// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";   
import "@openzeppelin/contracts/utils/Address.sol";   
import "./ERC721NFTCollectionManager.sol";
import "../interfaces/IWETH.sol";

contract ERC721NFTMarket is
    ERC721Holder,
    Ownable,
    ReentrancyGuard,
    ERC721NFTCollectionManager
{ 

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;



    struct Ask {
        address seller;
        address quoteToken;
        uint256 price;
    }

    struct BidEntry {
        address quoteToken;
        uint256 price;
    }

    address public immutable WETH;

    // nft => tokenId => ask
    mapping(address => mapping(uint256 => Ask)) public asks;
    mapping(address => EnumerableSet.UintSet) private _askTokenIds; // Set of tokenIds for a collection

    // nft => tokenId => bidder=> bid
    mapping(address => mapping(uint256 => mapping(address => BidEntry))) public bids;

    event AskNew(
        address indexed _seller,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    );

    event AskCancel(
        address indexed _seller,
        address indexed _nft,
        uint256 _tokenId
    );

    event Trade(
        address indexed _seller,
        address indexed buyer,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _netPrice
    );

    event AcceptBid(
        address indexed _seller,
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _netPrice
    );
    
    event Bid(
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    );

    event CancelBid(
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId
    );

    modifier notContract() {
        require(!(Address.isContract(msg.sender)), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    constructor(
        address _weth,
        address _feeRecipient,
        uint256 _feePercent
    ) ERC721NFTCollectionManager(_feeRecipient, _feePercent) {
        WETH = _weth;
    }

    /**
     * @notice Create ask order
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _quoteToken: quote token
     * @param _price: price for listing (in wei)
     */
    function createAsk(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external nonReentrant notContract tradeAllowed(_nft) {
        // Verify price is not too low/high
        require(_price > 0, "Ask: Price must be greater than zero");
        IERC721(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId);
        asks[_nft][_tokenId] = Ask({
            seller: _msgSender(),
            quoteToken: _quoteToken,
            price: _price
        });
        _askTokenIds[_nft].add(_tokenId);
        emit AskNew(_msgSender(), _nft, _tokenId, _quoteToken, _price);
    }

    /**
     * @notice Cancel Ask
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     */
    function cancelAsk(address _nft, uint256 _tokenId) external nonReentrant {
        // Verify the sender has listed it
        require(
            asks[_nft][_tokenId].seller == _msgSender(),
            "Ask: only seller"
        );
        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);
        delete asks[_nft][_tokenId];
        _askTokenIds[_nft].remove(_tokenId);
        emit AskCancel(_msgSender(), _nft, _tokenId);
    }

    /**
     * @notice Buy
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _quoteToken: quote token
     * @param _price: price for listing (in wei)
     */
    function buy(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        bytes32 _fingeprint
    ) external notContract nonReentrant tradeAllowed(_nft) {
        require(_askTokenIds[_nft].contains(_tokenId), "token was not sell");
        IERC20(_quoteToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _price
        );
        _buy(_nft, _tokenId, _quoteToken, _price);
    }

    function _buy(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) private {
        Ask memory ask = asks[_nft][_tokenId];
        require(ask.quoteToken == _quoteToken, "Buy: Incorrect qoute token");
        require(ask.price == _price, "Buy: Incorrect price");
        uint256 fees = _distributeFees(_nft, _quoteToken, _price);
        uint256 netPrice = _price.sub(fees);
        IERC20(_quoteToken).safeTransfer(ask.seller, netPrice);
        IERC721(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId);
        delete asks[_nft][_tokenId];
        _askTokenIds[_nft].remove(_tokenId);
        emit Trade(
            ask.seller,
            _msgSender(),
            _nft,
            _tokenId,
            _quoteToken,
            _price,
            netPrice
        );
    }


    /**
     * @notice Buy using native token
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     */
    function buyUsingNative(
        address _nft,
        uint256 _tokenId
    ) external payable nonReentrant notContract tradeAllowed(_nft) {
        require(asks[_nft][_tokenId].seller != address(0), "token is not sell");
        IWETH(WETH).deposit{value: msg.value}();
        _buy(_nft, _tokenId, WETH, msg.value);
    }

     /**
     * @notice Create a offer
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _bidder: address of bidder
     * @param _quoteToken: quote token
     * @param _price: price for listing (in wei)
     */
    function acceptBid(
        address _nft,
        uint256 _tokenId,
        address _bidder,
        address _quoteToken,
        uint256 _price
    ) external nonReentrant tradeAllowed(_nft) {
        BidEntry memory bid = bids[_nft][_tokenId][_bidder];
        require(bid.price == _price, "AcceptBid: invalid price");
        require(bid.quoteToken == _quoteToken, "AcceptBid: invalid quoteToken");

        address seller = asks[_nft][_tokenId].seller;
        if (seller == _msgSender()) {
            IERC721(_nft).safeTransferFrom(address(this), _bidder, _tokenId);
        } else {
            seller = _msgSender();
            IERC721(_nft).safeTransferFrom(seller, _bidder, _tokenId);
        }

        uint256 fees = _distributeFees(_nft, _quoteToken, _price);
        uint256 netPrice = _price.sub(fees);
        IERC20(_quoteToken).safeTransfer(seller, netPrice);

        delete asks[_nft][_tokenId];
        _askTokenIds[_nft].remove(_tokenId);
        delete bids[_nft][_tokenId][_bidder];
        emit AcceptBid(
            seller,
            _bidder,
            _nft,
            _tokenId,
            _quoteToken,
            _price,
            netPrice
        );
    }

    function createBid(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) external notContract nonReentrant tradeAllowed(_nft) {
        IERC20(_quoteToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _price
        );
        _createBid(_nft, _tokenId, _quoteToken, _price);
    }
    
    function _createBid(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price
    ) private {
        require(_price > 0, "Bid: Price must be granter than zero");
        if (bids[_nft][_tokenId][_msgSender()].price > 0) {
            // cancel old bid
            _cancelBid(_nft, _tokenId);
        }
        bids[_nft][_tokenId][_msgSender()] = BidEntry({
            price: _price,
            quoteToken: _quoteToken
        });
        emit Bid(_msgSender(), _nft, _tokenId, _quoteToken, _price);
    }

    function createBidUsingNative(
        address _nft,
        uint256 _tokenId
    ) external payable notContract nonReentrant tradeAllowed(_nft) {
        IWETH(WETH).deposit{value: msg.value}();
        _createBid(_nft, _tokenId, WETH, msg.value);
    }

    function cancelBid(address _nft, uint256 _tokenId) external nonReentrant {
        _cancelBid(_nft, _tokenId);
    }

    function _cancelBid(address _nft, uint256 _tokenId) private {
        BidEntry memory bid = bids[_nft][_tokenId][_msgSender()];
        require(bid.price > 0, "Bid: bid not found");
        IERC20(bid.quoteToken).safeTransfer(_msgSender(), bid.price);
        delete bids[_nft][_tokenId][_msgSender()];
        emit CancelBid(_msgSender(), _nft, _tokenId);
    }

    function viewAsksByCollectionAndTokenIds(address _collection, uint256[] calldata _tokenIds)
        external
        view
        returns (bool[] memory statuses, Ask[] memory askInfo)
    {
        uint256 length = _tokenIds.length;

        statuses = new bool[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            if (_askTokenIds[_collection].contains(_tokenIds[i])) {
                statuses[i] = true;
            } else {
                statuses[i] = false;
            }

            askInfo[i] = asks[_collection][_tokenIds[i]];
        }

        return (statuses, askInfo);
    }

    function viewAsksByCollection(
        address _collection,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory tokenIds,
            Ask[] memory askInfo,
            uint256
        )
    {
        uint256 length = _size;

        if (length > _askTokenIds[_collection].length() - _cursor) {
            length = _askTokenIds[_collection].length() - _cursor;
        }

        tokenIds = new uint256[](length);
        askInfo = new Ask[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _askTokenIds[_collection].at(_cursor + i);
            askInfo[i] = asks[_collection][tokenIds[i]];
        }

        return (tokenIds, askInfo, _cursor + length);
    }

}