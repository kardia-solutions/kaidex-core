// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./ERC1155NFTCollectionManager.sol";
import "../interfaces/IWETH.sol";
import "../../libraries/TransferHelper.sol";


contract ERC1155NFTMarket is ERC1155NFTCollectionManager, ReentrancyGuard {
    
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Ask {
        address seller;
        address quoteToken;
        uint256 price;
        uint256 amounts;
    }

    struct BidEntry {
        address quoteToken;
        uint256 price;
        uint256 amounts;
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
        uint256 _price,
        uint256 _amounts
    );

    event AskCancel(
        address indexed _seller,
        address indexed _nft,
        uint256 _tokenId,
        uint256 _amounts
    );

    event Trade(
        address indexed _seller,
        address indexed buyer,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _netPay,
        uint256 _amounts
    );

    event AcceptBid(
        address indexed _seller,
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _netPay,
        uint256 _amounts
    );
    
    event Bid(
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    );

    event CancelBid(
        address indexed bidder,
        address indexed _nft,
        uint256 _tokenId,
        uint256 _amounts
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
    ) ERC1155NFTCollectionManager(_feeRecipient, _feePercent) {
        WETH = _weth;
    }

    /**
     * @notice Create ask order
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _quoteToken: quote token
     * @param _price: price for each erc1155 amount listing (in wei)
     * @param _amounts: amounts
     */
    function createAsk(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    ) external nonReentrant notContract {
        // Verify price is not too low/high
        require(_price > 0, "Ask: Price must be greater than zero");
        require(IERC1155(_nft).balanceOf(_msgSender(), _tokenId) >= _amounts, "Ask: The amounts are not enough");
        IERC1155(_nft).safeTransferFrom(_msgSender(), address(this), _tokenId, _amounts, "");
        asks[_nft][_tokenId] = Ask({
            seller: _msgSender(),
            quoteToken: _quoteToken,
            price: _price,
            amounts: _amounts
        });
        _askTokenIds[_nft].add(_tokenId);
        emit AskNew(_msgSender(), _nft, _tokenId, _quoteToken, _price, _amounts);
    }

    /**
     * @notice Cancel Ask
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _amounts: amounts
     */
    function cancelAsk(address _nft, uint256 _tokenId, uint256 _amounts) external nonReentrant {
        // Verify the sender has listed it
        require(
            asks[_nft][_tokenId].seller == _msgSender(),
            "Ask: only seller"
        );
        require(asks[_nft][_tokenId].amounts >= _amounts, "Ask: over amounts");
        IERC1155(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId, _amounts, "");

        if (_amounts == asks[_nft][_tokenId].amounts) {
            delete asks[_nft][_tokenId];
            _askTokenIds[_nft].remove(_tokenId);
        } else {
            asks[_nft][_tokenId].amounts -= _amounts;
        }
        emit AskCancel(_msgSender(), _nft, _tokenId, _amounts);
    }

    /**
     * @notice Buy
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _quoteToken: quote token
     * @param _price: price for listing (in wei)
     * @param _amounts: amounts
     */
    function buy(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    ) external notContract nonReentrant {
        require(asks[_nft][_tokenId].seller != address(0), "token is not sell");
        uint256 mustPay = _price.mul(_amounts);
        IERC20(_quoteToken).safeTransferFrom(
            _msgSender(),
            address(this),
            mustPay
        );
        _buy(_nft, _tokenId, _quoteToken, _price, _amounts, mustPay);
    }

    function _buy(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts,
        uint256 _totalPay
    ) private {
        Ask memory ask = asks[_nft][_tokenId];
        require(ask.quoteToken == _quoteToken, "Buy: Incorrect qoute token");
        require(ask.price == _price, "Buy: Incorrect price");
        require(ask.amounts >= _amounts, "Buy: Incorrect amounts");
        uint256 fees = _distributeFees(_nft, _quoteToken, _totalPay);
        uint256 netPay= _totalPay.sub(fees);
        IERC20(_quoteToken).safeTransfer(ask.seller, netPay);
        IERC1155(_nft).safeTransferFrom(address(this), _msgSender(), _tokenId, _amounts, "");
        if (_amounts == ask.amounts) {
            delete asks[_nft][_tokenId];
            _askTokenIds[_nft].remove(_tokenId);
        } else {
            asks[_nft][_tokenId].amounts -= _amounts;
        }
        emit Trade(
            ask.seller,
            _msgSender(),
            _nft,
            _tokenId,
            _quoteToken,
            _price,
            netPay,
            _amounts
        );
    }


    /**
     * @notice Buy using native token
     * @param _nft: contract address of the NFT
     * @param _amounts: amounts
     * @param _tokenId: tokenId of the NFT
     */
    function buyUsingNative(
        address _nft,
        uint256 _tokenId,
        uint256 _amounts,
        uint256 _price
    ) external payable nonReentrant notContract {
        require(asks[_nft][_tokenId].seller != address(0), "token is not sell");
        uint256 mustPay = _price.mul(_amounts);
        require(msg.value >= mustPay, "amount not enough");
        if (msg.value > mustPay) {
            TransferHelper.safeTransferKAI(msg.sender, msg.value - mustPay);
        }
        IWETH(WETH).deposit{value: mustPay}();
        _buy(_nft, _tokenId, WETH, _price, _amounts, mustPay);
    }

     /**
     * @notice Create a offer
     * @param _nft: contract address of the NFT
     * @param _tokenId: tokenId of the NFT
     * @param _bidder: address of bidder
     * @param _price: price for listing (in wei)
     * @param _amounts: amounts
     */
    function acceptBid(
        address _nft,
        uint256 _tokenId,
        address _bidder,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    ) external nonReentrant {
        BidEntry memory bid = bids[_nft][_tokenId][_bidder];
        require(bid.price == _price, "AcceptBid: invalid price");
        require(bid.quoteToken == _quoteToken, "AcceptBid: invalid quoteToken");

        address seller = asks[_nft][_tokenId].seller;
        if (seller == _msgSender()) {
            IERC1155(_nft).safeTransferFrom(address(this), _bidder, _tokenId, _amounts, "");
        } else {
            seller = _msgSender();
            IERC1155(_nft).safeTransferFrom(seller, _bidder, _tokenId, _amounts, "");
        }
        uint256 totalPay = _amounts.mul(_price);
        uint256 fees = _distributeFees(_nft, _quoteToken, totalPay);
        uint256 netPrice = totalPay.sub(fees);
        IERC20(_quoteToken).safeTransfer(seller, netPrice);

        if (asks[_nft][_tokenId].amounts == _amounts) {
            delete asks[_nft][_tokenId];
            _askTokenIds[_nft].remove(_tokenId);
        } else {
            asks[_nft][_tokenId].amounts -= _amounts;
        }

        if(bids[_nft][_tokenId][_bidder].amounts == _amounts) {
            delete bids[_nft][_tokenId][_bidder];
        } else {
            bids[_nft][_tokenId][_bidder].amounts -= _amounts;
        }

        emit AcceptBid(
            seller,
            _bidder,
            _nft,
            _tokenId,
            _quoteToken,
            _price,
            totalPay,
            _amounts
        );
    }

    function createBid(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    ) external notContract nonReentrant {
        uint256 totalPay = _amounts.mul(_price);
        IERC20(_quoteToken).safeTransferFrom(
            _msgSender(),
            address(this),
            totalPay
        );
        _createBid(_nft, _tokenId, _quoteToken, _price, _amounts);
    }
    
    function _createBid(
        address _nft,
        uint256 _tokenId,
        address _quoteToken,
        uint256 _price,
        uint256 _amounts
    ) private {
        require(_price > 0, "Bid: Price must be granter than zero");
        if (bids[_nft][_tokenId][_msgSender()].price > 0) {
            // cancel old bid
            _cancelBid(_nft, _tokenId, _amounts);
        }
        bids[_nft][_tokenId][_msgSender()] = BidEntry({
            price: _price,
            quoteToken: _quoteToken,
            amounts: _amounts
        });
        emit Bid(_msgSender(), _nft, _tokenId, _quoteToken, _price, _amounts);
    }

    function createBidUsingNative(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        uint256 _amounts
    ) external payable notContract nonReentrant {
        uint256 mustPay = _price.mul(_amounts);
        require(msg.value >= mustPay, "amount not enough");
        if (msg.value > mustPay) {
            TransferHelper.safeTransferKAI(msg.sender, msg.value - mustPay);
        }
        IWETH(WETH).deposit{value: mustPay}();
        _createBid(_nft, _tokenId, WETH, _price, _amounts);
    }

    function cancelBid(address _nft, uint256 _tokenId, uint256 _amounts) external nonReentrant {
        _cancelBid(_nft, _tokenId, _amounts);
    }

    function _cancelBid(address _nft, uint256 _tokenId, uint256 _amounts) private {
        BidEntry memory bid = bids[_nft][_tokenId][_msgSender()];
        require(bid.price > 0, "Bid: bid not found");
        require(bid.amounts >= _amounts, "Bid: Incorrect amounts");
        uint256 returnAmount = bid.price.mul(_amounts);
        IERC20(bid.quoteToken).safeTransfer(_msgSender(), returnAmount);
        if (bid.amounts == _amounts) {
            delete bids[_nft][_tokenId][_msgSender()];
        } else {
            bids[_nft][_tokenId][_msgSender()].amounts -= _amounts;
        }
        emit CancelBid(_msgSender(), _nft, _tokenId, _amounts);
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