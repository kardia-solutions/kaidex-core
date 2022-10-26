// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinterAdapter.sol";
import "../../libraries/TransferHelper.sol";

contract ERC721INO is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    struct UserInfo {
        uint8 ticket;
        uint8 usedTicket;
    }
    uint256 public constant NFT_PRICE = 5*10**18;
    address public minterAdapter;
    address public buyToken; // The currency used to buy NFT
    // address => user info
    mapping(address => UserInfo) public users;
    uint256 public totalUsers; // Total user bought
    uint256 public totalTicket;  // Total nft bought
    uint256 public totalUsedTicket;  // Total nft claimed
    uint256 public startTime;
    uint256 public endTime;

    event Buy(address indexed user, uint8 _ticket);
    event Claim(address indexed user, uint256 tokenId);

    constructor(
        address _buyToken,
        address _minter,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(
            _endTime > _startTime && _startTime > block.timestamp,
            "Time is invalid"
        );
        require(IMinterAdapter(_minter).isMinter(), "minter is invalid");
        buyToken = _buyToken;
        minterAdapter = _minter;
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier satisfyBuyCondition(uint8 _ticket) {
        require(_ticket > 0, "the amount have to bigger than zero");
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Buy time is invalid"
        );

        require(IMinterAdapter(minterAdapter).isValidTierTime(_msgSender()), "Tim has not come");
        require(
            users[_msgSender()].ticket + _ticket <= getMaximumTicketByUser(_msgSender()) &&
                totalTicket + _ticket <= getMaximumTicketSales(),
            "Ticket number is invalid"
        );
        _;
    }

    modifier satisfyClaimCondition() {
        require(
            users[_msgSender()].ticket > 0 &&
                users[_msgSender()].ticket > users[_msgSender()].usedTicket,
            "Not has ticket"
        );
        require(block.timestamp >= endTime, "Time has not ended yet");
        _;
    }

    function buy(uint8 _ticket)
        public
        payable
        whenNotPaused
        nonReentrant
        satisfyBuyCondition(_ticket)
    {
        uint256 mustPay = NFT_PRICE.mul(_ticket);
        if (buyToken == address(0)) {
            require(msg.value >= mustPay, "value not enough");
            if (msg.value > mustPay) {
                TransferHelper.safeTransferKAI(msg.sender, msg.value - mustPay);
            }
        } else {
            IERC20(buyToken).transferFrom(
                address(msg.sender),
                address(this),
                mustPay
            );
        }
        if (users[_msgSender()].ticket == 0) {
            totalUsers++;
        }
        users[_msgSender()].ticket += _ticket;
        totalTicket += _ticket;
        emit Buy(_msgSender(), _ticket);
    }

    function claim() public whenNotPaused nonReentrant satisfyClaimCondition {
        // mint nft
        uint256 tokenId = IMinterAdapter(minterAdapter).mint(_msgSender());
        require(tokenId > 0, "mint falied");
        users[_msgSender()].usedTicket++;
        totalUsedTicket++;
        emit Claim(_msgSender(), tokenId);
    }

    function setMinter(address _newMinter) public onlyOwner {
        require(IMinterAdapter(_newMinter).isMinter(), "minter is invalid");
        minterAdapter = _newMinter;
    }

    function setStartTime (uint256 newStartTime) public onlyOwner {
        require(newStartTime > block.timestamp && newStartTime < endTime, "Time is invalid!!");
        startTime = newStartTime;
    }

    function setEndTime (uint256 newEndTime) public onlyOwner {
        require(newEndTime > block.timestamp && newEndTime > startTime && endTime > block.timestamp, "Time is invalid!!");
        endTime = newEndTime;
    }

    function emergencyWithdraw(address token, address payable to)
        public
        onlyOwner
    {
        if (token == address(0)) {
            to.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
        }
    }

    function finalWithdraw(address _destination) public onlyOwner {
        uint256 _withdraw = NFT_PRICE.mul(totalTicket);
        if (buyToken == address(0)) {
            TransferHelper.safeTransferKAI(_destination, _withdraw);
        } else {
            IERC20(buyToken).transfer(
                address(_destination),
                _withdraw
            );
        }
    }

    function getMaximumTicketByUser (address userAddr) public view returns (uint256) {
        return IMinterAdapter(minterAdapter).maximumTicketByUser(userAddr);
    }

    function getMaximumTicketSales () public view returns (uint256) {
        return IMinterAdapter(minterAdapter).maximumNFTSales();
    }

    function getSnapshotFrom () public view returns (uint256) {
        return IMinterAdapter(minterAdapter).getSnapshotFrom();
    }

    function getSnapshotTo () public view returns (uint256) {
        return IMinterAdapter(minterAdapter).getSnapshotTo();
    }

    function getAllocationByTier (uint256 _tier) public view returns (uint256) {
        return IMinterAdapter(minterAdapter).getAllocationByTier(_tier);
    }

    function getBuySchedulesBuyTier (uint256 _tier) public view returns (uint256) {
        return IMinterAdapter(minterAdapter).getBuySchedulesBuyTier(_tier);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
