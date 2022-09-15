// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinter.sol";
import "../../libraries/TransferHelper.sol";


contract INO is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;    

    struct UserInfo {
        uint8 ticket;
        uint8 usedTicket;
    }

    uint256 public constant NFT_PRICE = 5 * 10**18;

    IMinter public minter;
    address public buyToken; // The currency used to buy NFT

    // address => user info
    mapping(address => UserInfo) public users;
    uint256 public totalUsers;
    uint256 public totalTicket;
    uint256 public totalUsedTicked;

    uint256 public startTime;
    uint256 public endTime;

    event Buy(address indexed user, uint8 _ticket);
    event Claim();

    constructor(
        address _buyToken,
        address _minter,
        uint256 _startTime,
        uint256 _endTime
    ) {
        require(_buyToken != address(0) && _minter != address(0), "Address invalid");
        require(_endTime > _startTime && startTime > block.timestamp, "Time is invalid");
        require(IMinter(minter).isMinter(), "minter is invalid");
        buyToken = _buyToken;
        minter = IMinter(_minter);
        startTime = _startTime;
        endTime = _endTime;
    }

    modifier satisfyBuyCondition(uint8 _ticket) {
        require(_ticket > 0, "the amount have to bigger than zero");
        _;
    }

    modifier satisfyClaimCondition() {
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

    }

    function setMinter (address _newMinter) public onlyOwner {
        require(IMinter(_newMinter).isMinter(), "minter is invalid");
        minter = IMinter(_newMinter);
    }

    function emergencyWithdraw(address token, address payable to)
        public
        onlyOwner
    {
        if (token == address(0)) {
            to.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(
                to,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
