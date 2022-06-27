//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../KaidexToken.sol";
import "../interfaces/IRewarder.sol";

contract KaidexMasterChef is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. KDXs to distribute per block.
        uint256 lastRewardBlock; // Last block number that KDXs distribution occurs.
        uint256 accKDXPerShare; // Accumulated KDXs per share, times 1e12. See below.
    }

    // The KDX TOKEN
    KaiDexToken public kdx;

    // KDX tokens created per block.
    uint256 public kdxPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when KDX mining starts.
    uint256 public startBlock;

    /// @notice Address of each `IRewarder` contract.
    IRewarder[] public rewarder;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event LogPoolAddition(
        uint256 indexed pid, 
        uint256 allocPoint, 
        IERC20 indexed lpToken, 
        IRewarder indexed rewarder
    );
    event LogSetPool(
        uint256 indexed pid, 
        uint256 allocPoint, 
        IRewarder indexed rewarder,
        bool overwrite
    );
    event LogUpdatePool(
        uint256 indexed pid, 
        uint256 lastRewardBlock, 
        uint256 lpSupply, 
        uint256 accKdxPerShare
    );
    event UpdateKdxPerBlock (
        uint256 _oldKdxPerblock,
        uint256 _newKdxPerblock
    );

    constructor(
        KaiDexToken _kdx,
        uint256 _kdxPerBlock,
        uint256 _startBlock
    ) public {
        kdx = _kdx;
        kdxPerBlock = _kdxPerBlock;
        startBlock = _startBlock;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // updateKdxPerBlock, can update the kdx per block only onwer can update this field
    function updateKdxPerBlock(uint256 _newKdxPerBlock) public onlyOwner {
        massUpdatePools();
        uint256 _oldKdxPerblock = kdxPerBlock;
        kdxPerBlock = _newKdxPerBlock;
        emit UpdateKdxPerBlock(_oldKdxPerblock, kdxPerBlock);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKDXPerShare: 0
            })
        );
        rewarder.push(_rewarder);
        emit LogPoolAddition(poolInfo.length.sub(1), _allocPoint, _lpToken, _rewarder);
    }

    // Update the given pool's KDX allocation point or rewarder. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        IRewarder _rewarder,
        bool overwrite
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        if (overwrite) { rewarder[_pid] = _rewarder; }
        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    // View function to see pending KDXs on frontend.
    function pendingKDX(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKdxPerShare = pool.accKDXPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 kdxReward =
                multiplier.mul(kdxPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accKdxPerShare = accKdxPerShare.add(
                kdxReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accKdxPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 kdxReward =
            multiplier.mul(kdxPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        kdx.mint(address(this), kdxReward);
        pool.accKDXPerShare = pool.accKDXPerShare.add(
            kdxReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
        emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accKDXPerShare);
    }

    // Internal deposit function to deposit LP tokens to MasterChef for KDX allocation.
    function _deposit(uint256 _pid, uint256 _amount, address userAddress) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][userAddress];
        updatePool(_pid);
        uint256 pending = 0;
        if (user.amount > 0) {
            pending =
                user.amount.mul(pool.accKDXPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeKDXTransfer(userAddress, pending);
        } 
        pool.lpToken.safeTransferFrom(
            address(userAddress),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accKDXPerShare).div(1e12);
        // Rewarder
        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onKdxReward(_pid, userAddress, userAddress, pending, user.amount);
        }
        emit Deposit(userAddress, _pid, _amount);
    }

    // Deposit LP tokens to MasterChef for KDX allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        _deposit(_pid, _amount, msg.sender);
    }

    // Harvest KDX rewards from MasterChef pools.
    function harvest(uint256 _pid) public {
        _deposit(_pid, 0, msg.sender);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accKDXPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeKDXTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accKDXPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        // Rewarder
        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onKdxReward(_pid, msg.sender, msg.sender, pending, user.amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onKdxReward(_pid, msg.sender, msg.sender, 0, 0);
        }
    }

    // Safe kdx transfer function, just in case if rounding error causes pool to not have enough KDXs.
    function safeKDXTransfer(address _to, uint256 _amount) internal {
        uint256 kdxBal = kdx.balanceOf(address(this));
        if (_amount > kdxBal) {
            kdx.transfer(_to, kdxBal);
        } else {
            kdx.transfer(_to, _amount);
        }
    }
}