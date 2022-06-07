//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StKDX is ERC20Snapshot, Ownable {
    using SafeMath for uint256;
    IERC20 public kdx;

    // Define the KDX token contract
    constructor(IERC20 _kdx) ERC20("stKDX", "stKDX") public {
        kdx = _kdx;
    }

    // Enter the bar. Pay some KDXs. Earn some shares.
    // Locks Kdx and mints stKDX
    function enter(uint256 _amount) public {
        // Gets the amount of Kdx locked in the contract
        uint256 totalKdx = kdx.balanceOf(address(this));
        // Gets the amount of stKDX in existence
        uint256 totalShares = totalSupply();
        // If no stKDX exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalKdx == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of stKDX the Kdx is worth. The ratio will change overtime, as stKDX is burned/minted and Kdx deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalKdx);
            _mint(msg.sender, what);
        }
        // Lock the Kdx in the contract
        kdx.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your KDXs.
    // Unlocks the staked + gained Kdx and burns stKDX
    function leave(uint256 _share) public {
        // Gets the amount of stKDX in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Kdx the stKDX is worth
        uint256 what = _share.mul(kdx.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        kdx.transfer(msg.sender, what);
    }

    function getCurrentSnapshotId() public view virtual returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }
}