//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/TransferHelper.sol";

contract FundRaising is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        bool claimed; // default false
    }
    // The buy token
    ERC20 public buyToken; // Ex.USDT, DAI ... If buyToken = address(0) => so this is using KAI native
    // The offering token
    ERC20 public offeringToken;
    // The timestamp when raising starts
    uint256 public startTime;
    // The timestamp when raising ends
    uint256 public endTime;
    // total amount of raising tokens need to be raised
    uint256 public raisingAmount;
    // total amount of offeringToken that will offer
    uint256 public offeringAmount;
    // total amount of raising tokens that have already raised
    uint256 public totalAmount;
    // address => amount
    mapping(address => UserInfo) public userInfo;
    // participators
    address[] public addressList;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(
        address indexed user,
        uint256 offeringAmount,
        uint256 excessAmount
    );

    struct TokenInfo {
        ERC20 token;
        uint256 decimals;
        string name;
        string symbol;
    }

    constructor(
        ERC20 _buyToken,
        ERC20 _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _offeringAmount,
        uint256 _raisingAmount
    ) public {
        buyToken = _buyToken;
        offeringToken = _offeringToken;
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        totalAmount = 0;
    }

    modifier depositAllowed(uint256 _amount) {
        require(
            block.timestamp > startTime && block.timestamp < endTime,
            "not raising time"
        );
        require(_amount > 0, "need _amount > 0");
        _;
    }

    modifier harvestAllowed() {
        require(block.timestamp > endTime, "not harvest time");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "nothing to harvest");
        _;
    }

    function getInfo () public view returns (
        TokenInfo memory,
        TokenInfo memory,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        TokenInfo memory _buyToken = getERC20Info(buyToken);
        TokenInfo memory _offeringToken = getERC20Info(offeringToken);
        return (
            _buyToken,
            _offeringToken,
            startTime,
            endTime,
            offeringAmount,
            raisingAmount
        );
    }

    function getERC20Info (ERC20 _token) private view returns (TokenInfo memory) {
        return TokenInfo({
            token: _token,
            decimals: _token.decimals(),
            name: _token.name(),
            symbol: _token.symbol()
        });
    }

    function setOfferingAmount(uint256 _offerAmount) public onlyOwner {
        require(block.timestamp < startTime, "no");
        offeringAmount = _offerAmount;
    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyOwner {
        require(block.timestamp < startTime, "no");
        raisingAmount = _raisingAmount;
    }

    function deposit(uint256 _amount)
        public
        payable
        nonReentrant
        depositAllowed(_amount)
    {
        if (buyToken == IERC20(address(0))) {
            require(msg.value >= _amount, "amount not enough");
            if (msg.value > _amount) {
                TransferHelper.safeTransferKAI(msg.sender, msg.value - _amount);
            }
        } else {
            buyToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }
        if (userInfo[msg.sender].amount == 0) {
            addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function harvest() public nonReentrant harvestAllowed {
        uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
        uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
        offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
        if (refundingTokenAmount > 0) {
            if (buyToken == IERC20(address(0))) {
                TransferHelper.safeTransferKAI(
                    msg.sender,
                    refundingTokenAmount
                );
            } else {
                buyToken.safeTransfer(
                    address(msg.sender),
                    refundingTokenAmount
                );
            }
        }
        userInfo[msg.sender].claimed = true;
        emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount);
    }

    function hasHarvest(address _user) external view returns (bool) {
        return userInfo[_user].claimed;
    }

    // allocation 100000 means 0.1(10%), 1 meanss 0.000001(0.0001%), 1000000 means 1(100%)
    function getUserAllocation(address _user) public view returns (uint256) {
        return userInfo[_user].amount.mul(1e12).div(totalAmount).div(1e6);
    }

    // get the amount of Offering token you will get
    function getOfferingAmount(address _user) public view returns (uint256) {
        if (totalAmount > raisingAmount) {
            uint256 allocation = getUserAllocation(_user);
            return offeringAmount.mul(allocation).div(1e6);
        } else {
            // userInfo[_user] / (raisingAmount / offeringAmount)
            return
                userInfo[_user].amount.mul(offeringAmount).div(raisingAmount);
        }
    }

    // get the amount of lp token you will be refunded
    function getRefundingAmount(address _user) public view returns (uint256) {
        if (totalAmount <= raisingAmount) {
            return 0;
        }
        uint256 allocation = getUserAllocation(_user);
        uint256 payAmount = raisingAmount.mul(allocation).div(1e6);
        return userInfo[_user].amount.sub(payAmount);
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdraw(uint256 _raisingAmount, uint256 _offerAmount)
        public
        onlyOwner
    {
        require(
            _offerAmount < offeringToken.balanceOf(address(this)),
            "not enough token 1"
        );
        if (buyToken == IERC20(address(0))) {
            TransferHelper.safeTransferKAI(msg.sender, _raisingAmount);
        } else {
            require(
                _raisingAmount < buyToken.balanceOf(address(this)),
                "not enough token 0"
            );
            buyToken.safeTransfer(address(msg.sender), _raisingAmount);
        }
        offeringToken.safeTransfer(address(msg.sender), _offerAmount);
    }

    function emergencyWithdraw(
        address token,
        uint256 amount,
        address payable to
    ) public onlyOwner {
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            ERC20(token).safeTransfer(to, amount);
        }
    }
}
