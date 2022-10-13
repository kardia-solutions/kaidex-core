//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../libraries/TransferHelper.sol";
import "./Whitelist.sol";

contract WhitelistRaisingV2 is ReentrancyGuard, Ownable, Pausable, Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        bool claimed; // default false
    }

    struct TokenInfo {
        ERC20 token;
        uint256 decimals;
        string name;
        string symbol;
    }
    // The buy token
    ERC20 public buyToken; // Ex.USDT, DAI ... If buyToken = address(0) => so this is using KAI native
    // The offering token
    ERC20 public offeringToken;
    // The timestamp when raising starts
    uint256 public startTime;
    // The timestamp when raising ends
    uint256 public endTime;
    // The timestamp user staring harvest
    uint256 public harvestTime;
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

    // Maximum allocation
    uint256 public maxAllocation;

    // IDO Fees: 10000 ~ 1, 1000 ~ 0.1 (10%), 100 ~ 0.01 (1%)
    uint256 public IDO_FEE = 200; // ~ 2%
    uint256 public totalFees;

    // Event
    event Deposit(address indexed user, uint256 amount);
    event Harvest(
        address indexed user,
        uint256 offeringAmount,
        uint256 excessAmount
    );

    constructor(
        ERC20 _buyToken,
        ERC20 _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _harvestTime,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _maxAllocation
    ) public {
        require(
            _harvestTime >= _endTime &&
                _endTime > _startTime &&
                _startTime > block.timestamp
        );
        buyToken = _buyToken;
        offeringToken = _offeringToken;
        startTime = _startTime;
        endTime = _endTime;
        harvestTime = _harvestTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        maxAllocation = _maxAllocation;
    }

    function getInfo()
        public
        view
        returns (
            TokenInfo memory,
            TokenInfo memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        TokenInfo memory _buyToken;
        if (buyToken == ERC20(address(0))) {
            _buyToken = TokenInfo({
                token: ERC20(address(0)),
                decimals: 18,
                name: "KardiaChain",
                symbol: "KAI"
            });
        } else {
            _buyToken = getERC20Info(buyToken);
        }
        TokenInfo memory _offeringToken = getERC20Info(offeringToken);
        return (
            _buyToken,
            _offeringToken,
            startTime,
            endTime,
            harvestTime,
            offeringAmount,
            raisingAmount
        );
    }

    function getERC20Info(ERC20 _token)
        private
        view
        returns (TokenInfo memory)
    {
        return
            TokenInfo({
                token: _token,
                decimals: _token.decimals(),
                name: _token.name(),
                symbol: _token.symbol()
            });
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
        require(block.timestamp > harvestTime, "not harvest time");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "nothing to harvest");
        _;
    }

    function updateStartTime(uint256 _newTime) public onlyOwner {
        require(
            _newTime > block.timestamp && _newTime < endTime,
            "time invalid!!"
        );
        startTime = _newTime;
    }

    function updateHarvestTime(uint256 _newTime) public onlyOwner {
        require(
            _newTime > block.timestamp && _newTime > endTime,
            "time invalid!!"
        );
        harvestTime = _newTime;
    }

    function updateEndTime(uint256 _newTime) public onlyOwner {
        require(
            _newTime > block.timestamp && _newTime < harvestTime,
            "time invalid!!"
        );
        endTime = _newTime;
    }

    function setRaisingAndOfferingAmount(
        uint256 _offerAmount,
        uint256 _raisingAmount
    ) public onlyOwner {
        raisingAmount = _raisingAmount;
        offeringAmount = _offerAmount;
    }

    function deposit(uint256 _amount)
        public
        payable
        nonReentrant
        depositAllowed(_amount)
        whenNotPaused
        onlyWhitelisted
    {
        require(
            maxAllocation > userInfo[msg.sender].amount,
            "not eligible amount!!"
        );
        uint256 eligibleAmount = maxAllocation - userInfo[msg.sender].amount;
        uint256 amount = _amount;
        if (eligibleAmount < _amount) {
            amount = eligibleAmount;
        }
        // submit fees
        uint256 fees = _feeCompute(amount);
        uint256 amountInclucedFee = amount + fees;
        if (buyToken == IERC20(address(0))) {
            require(msg.value >= amountInclucedFee, "amount not enough");
            if (msg.value > amountInclucedFee) {
                TransferHelper.safeTransferKAI(
                    msg.sender,
                    msg.value - amountInclucedFee
                );
            }
        } else {
            buyToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                amountInclucedFee
            );
        }
        if (userInfo[msg.sender].amount == 0) {
            addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(amount);
        totalAmount = totalAmount.add(amount);
        totalFees = totalFees.add(fees);
        emit Deposit(msg.sender, amount);
    }

    function _feeCompute(uint256 amount) private view returns (uint256) {
        return amount.mul(IDO_FEE).div(10000);
    }

    function harvest() public nonReentrant harvestAllowed whenNotPaused {
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

    function getUserAllocation(address _user) public view returns (uint256) {
        return userInfo[_user].amount.mul(1e18).div(totalAmount);
    }

    // get the amount of Offering token you will get
    function getOfferingAmount(address _user) public view returns (uint256) {
        if (totalAmount > raisingAmount) {
            uint256 allocation = getUserAllocation(_user);
            return offeringAmount.mul(allocation).div(1e18);
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
        uint256 payAmount = raisingAmount.mul(allocation).div(1e18);
        uint256 unpayAmount = userInfo[_user].amount.sub(payAmount).sub(10000);
        uint256 returnFees = _feeCompute(unpayAmount);
        return unpayAmount.add(returnFees);
    }

    function getAllocation(address _account) external view returns (uint256) {
        if (!whitelist[_account]) return 0;
        return maxAllocation;
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdrawRaised(address _destination) public onlyOwner {
        require(endTime < block.timestamp, "time has not ended");
        uint256 _withdraw = totalAmount < raisingAmount
            ? totalAmount
            : raisingAmount;
        if (buyToken == IERC20(address(0))) {
            TransferHelper.safeTransferKAI(_destination, _withdraw);
        } else {
            buyToken.safeTransfer(address(_destination), _withdraw);
        }
    }

    function finalWithdrawFees(address _destination) public onlyOwner {
        require(endTime < block.timestamp, "time has not ended");
        uint256 _raised = totalAmount < raisingAmount
            ? totalAmount
            : raisingAmount;
        uint256 _withdrawFees = _feeCompute(_raised);
        if (buyToken == IERC20(address(0))) {
            TransferHelper.safeTransferKAI(_destination, _withdrawFees);
        } else {
            buyToken.safeTransfer(address(_destination), _withdrawFees);
        }
    }

    // Return offering amount hasn't sold
    function remainingToken() public view returns (uint256) {
        uint256 sold = soldTokenAmount();
        return offeringAmount.sub(sold);
    }

    // Return offering amount has sold already
    function soldTokenAmount() public view returns (uint256) {
        if (totalAmount == 0) {
            return 0;
        }
        if (totalAmount >= raisingAmount) {
            return offeringAmount;
        }
        return offeringAmount.mul(totalAmount).div(raisingAmount);
    }

    function withdrawRemainingOfferingToken(address _destination)
        public
        onlyOwner
    {
        require(endTime < block.timestamp, "time has not ended");
        uint256 _withdraw = remainingToken();
        offeringToken.safeTransfer(address(_destination), _withdraw);
    }

    function emergencyWithdraw(address token, address payable to)
        public
        onlyOwner
    {
        if (token == address(0)) {
            to.transfer(address(this).balance);
        } else {
            ERC20(token).safeTransfer(
                to,
                ERC20(token).balanceOf(address(this))
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
