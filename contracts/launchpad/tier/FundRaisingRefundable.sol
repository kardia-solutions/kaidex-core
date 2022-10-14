//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../libraries/TransferHelper.sol";
import "../../interfaces/ITierSystem.sol";

contract FundRaisingRefundable is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        bool claimed; // default false
        bool refunded; // default false
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
    // The timestamp allow user refund
    uint256 public refundStartTime;
    // The timestamp end refund
    uint256 public refundEndTime;
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

    // Tier system
    ITierSystem public tierSystem;

    // snapshot ids
    uint256 public snapshotFrom;
    uint256 public snapshotTo;

    // Project multiplier: 10000 ~ 1, 1000 ~ 0.1
    uint256 public multiplier;

    // Refund Fees: 10000 ~ 1, 1000 ~ 0.1 (10%), 100 ~ 0.01 (1%)
    uint256 public REFUND_FEE = 500; // ~ 5%
    uint256 public refundFees;
    uint256 public totalRefund; // incluced fees
    uint256 public offeringTokenRefund;
    bool initialized;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(
        address indexed user,
        uint256 offeringAmount,
        uint256 excessAmount
    );
    event Refund(address indexed user, uint256 amount, uint256 fees);

    struct TokenInfo {
        ERC20 token;
        uint256 decimals;
        string name;
        string symbol;
    }

    constructor(
        ERC20 _buyToken,
        ERC20 _offeringToken,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        ITierSystem _tierSystem,
        uint256 _snapshotFrom,
        uint256 _snapshotTo,
        uint256 _multiplier
    ) public {
        buyToken = _buyToken;
        offeringToken = _offeringToken;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        tierSystem = _tierSystem;
        snapshotFrom = _snapshotFrom;
        snapshotTo = _snapshotTo;
        multiplier = _multiplier;
    }

    function initTime(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _harvestTime,
        uint256 _refundStartTime,
        uint256 _refundEndTime
    ) public onlyOwner {
        require(!initialized, "has initialized");
        require(
            _harvestTime >= _endTime &&
                _endTime > _startTime &&
                _startTime > block.timestamp &&
                _refundStartTime >= _endTime &&
                _refundStartTime < _refundEndTime
        );
        startTime = _startTime;
        endTime = _endTime;
        harvestTime = _harvestTime;
        refundStartTime = _refundStartTime;
        refundEndTime = _refundEndTime;
        initialized = true;
    }

    modifier depositAllowed(uint256 _amount) {
        require(initialized, "hasn't already");
        require(
            block.timestamp > startTime && block.timestamp < endTime,
            "not raising time"
        );
        require(_amount > 0, "need _amount > 0");
        _;
    }

    modifier harvestAllowed() {
        require(initialized, "hasn't already");
        require(block.timestamp > harvestTime, "not harvest time");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "nothing to harvest");
        require(!userInfo[msg.sender].refunded, "has refuned");
        _;
    }

    modifier refundAllowed() {
        require(initialized, "hasn't already");
        require(
            block.timestamp > refundStartTime &&
                block.timestamp <= refundEndTime,
            "not refund time"
        );
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "has harvested");
        require(!userInfo[msg.sender].refunded, "has refuned");
        _;
    }

    function setSnapshotFrom(uint256 id) public onlyOwner {
        require(id > 0, "Id invalid");
        snapshotFrom = id;
    }

    function setSnapshotTo(uint256 id) public onlyOwner {
        require(id > 0, "Id invalid");
        snapshotTo = id;
    }

    function setMultiplier(uint256 mul) public onlyOwner {
        multiplier = mul;
    }

    function updateHarvestTime(uint256 _newTime) public onlyOwner {
        require(
            _newTime > block.timestamp && _newTime > endTime,
            "time invalid!!"
        );
        harvestTime = _newTime;
    }

    function updateRefundStartTime(uint256 _refundStartTime) public onlyOwner {
        require(
            _refundStartTime > block.timestamp && _refundStartTime > endTime,
            "time invalid!!"
        );
        refundStartTime = _refundStartTime;
    }

    function updateRefundEndTime(uint256 _refundEndTime) public onlyOwner {
        require(
            _refundEndTime > block.timestamp &&
                _refundEndTime > refundStartTime,
            "time invalid!!"
        );
        refundEndTime = _refundEndTime;
    }

    function updateEndTime(uint256 _newTime) public onlyOwner {
        require(
            _newTime > block.timestamp && _newTime < harvestTime,
            "time invalid!!"
        );
        endTime = _newTime;
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

    function setOfferingAmount(uint256 _offerAmount) public onlyOwner {
        require(block.timestamp < startTime, "no");
        offeringAmount = _offerAmount;
    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyOwner {
        require(block.timestamp < startTime, "no");
        raisingAmount = _raisingAmount;
    }

    function updateOfferingToken(address _newToken) public onlyOwner {
        require(_newToken != address(0), "no");
        offeringToken = ERC20(_newToken);
    }

    function deposit(uint256 _amount)
        public
        payable
        nonReentrant
        depositAllowed(_amount)
        whenNotPaused
    {
        uint256 maxAllocation = _computeMaxAllocation(msg.sender);
        require(
            maxAllocation > userInfo[msg.sender].amount,
            "not eligible amount!!"
        );
        uint256 eligibleAmount = maxAllocation - userInfo[msg.sender].amount;
        uint256 amount = _amount;
        if (eligibleAmount < _amount) {
            amount = eligibleAmount;
        }
        if (buyToken == IERC20(address(0))) {
            require(msg.value >= amount, "amount not enough");
            if (msg.value > amount) {
                TransferHelper.safeTransferKAI(msg.sender, msg.value - amount);
            }
        } else {
            buyToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                amount
            );
        }
        if (userInfo[msg.sender].amount == 0) {
            addressList.push(address(msg.sender));
        }
        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(amount);
        totalAmount = totalAmount.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function _computeMaxAllocation(address _account)
        private
        view
        returns (uint256)
    {
        require(
            snapshotFrom > 0 && snapshotTo > snapshotFrom,
            "Snapshot id not set"
        );
        uint256 tier = tierSystem.getTierFromTo(
            _account,
            snapshotFrom,
            snapshotTo
        );
        if (tier == 0) return 0;
        return allocations(tier);
    }

    function getTier(address _account) external view returns (uint256) {
        return tierSystem.getTierFromTo(_account, snapshotFrom, snapshotTo);
    }

    function getAllocation(address _account) external view returns (uint256) {
        uint256 tier = tierSystem.getTierFromTo(
            _account,
            snapshotFrom,
            snapshotTo
        );
        if (tier == 0) return 0;
        return allocations(tier);
    }

    function getAllocationPoint(address _account)
        external
        view
        returns (uint256)
    {
        uint256 tier = tierSystem.getTierFromTo(
            _account,
            snapshotFrom,
            snapshotTo
        );
        if (tier == 0) return 0;
        return tierSystem.getAllocationPoint(tier);
    }

    function allocations(uint256 _tier) public view returns (uint256) {
        uint256 _alloPoint = tierSystem.getAllocationPoint(_tier);
        if (buyToken == IERC20(address(0))) {
            return _alloPoint.mul(multiplier).mul(1e18).div(10000);
        }
        return
            _alloPoint.mul(multiplier).mul(10**buyToken.decimals()).div(10000);
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

    function refund() public nonReentrant whenNotPaused refundAllowed {
        uint256 amountDep = userInfo[msg.sender].amount;
        uint256 refundingTokenAmount = getRefundingAmount(msg.sender);
        uint256 offeringTokenAmount = getOfferingAmount(msg.sender);
        uint256 boughtAmount = amountDep.sub(refundingTokenAmount);
        uint256 fees = boughtAmount.mul(REFUND_FEE).div(10000);
        uint256 refundable = amountDep - fees;
        if (buyToken == IERC20(address(0))) {
            TransferHelper.safeTransferKAI(msg.sender, refundable);
        } else {
            buyToken.safeTransfer(address(msg.sender), refundable);
        }
        userInfo[msg.sender].refunded = true;
        refundFees = refundFees.add(fees);
        totalRefund = totalRefund.add(refundable);
        offeringTokenRefund = offeringTokenRefund.add(offeringTokenAmount);
        emit Refund(msg.sender, refundable, fees);
    }

    function hasHarvest(address _user) external view returns (bool) {
        return userInfo[_user].claimed;
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
        return userInfo[_user].amount.sub(payAmount).sub(10000);
    }

    function getAddressListLength() external view returns (uint256) {
        return addressList.length;
    }

    function finalWithdraw(address _destination) public onlyOwner {
        require(
            endTime < block.timestamp && refundEndTime < block.timestamp,
            "time has not ended"
        );
        uint256 _withdraw = finalWithdrawAmount();
        if (buyToken == IERC20(address(0))) {
            TransferHelper.safeTransferKAI(_destination, _withdraw);
        } else {
            buyToken.safeTransfer(address(_destination), _withdraw);
        }
    }

    function finalWithdrawAmount() public view returns(uint256) {
        if (totalAmount > raisingAmount) {
            uint256 soldAmountAfterRefund = soldTokenAmountAferRefund();
            return soldAmountAfterRefund.mul(raisingAmount).div(offeringAmount) + refundFees;
        } else {
           return totalAmount - totalRefund;
        }
    }

    // Return offering amount hasn't sold after refund
    function remainingTokenAfterRefund() public view returns (uint256) {
        uint256 sold = soldTokenAmountAferRefund();
        return offeringAmount.sub(sold);
    }

    // Return offering amount has sold already after refund
    function soldTokenAmountAferRefund() public view returns (uint256) {
        if (totalAmount == 0) {
            return 0;
        }
        if (totalAmount >= raisingAmount) {
            return offeringAmount - offeringTokenRefund;
        }
        return offeringAmount.mul(totalAmount).div(raisingAmount) - offeringTokenRefund;
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

    function emergencyWithdraw(
        address token,
        address payable to,
        uint256 amount
    ) public onlyOwner {
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            ERC20(token).safeTransfer(to, amount);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    fallback() external payable {}
}