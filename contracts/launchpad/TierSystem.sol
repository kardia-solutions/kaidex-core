//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStKDX.sol";

contract TierSystem is Ownable {
    IStKDX public stKdx;
    // Snapshot list
    uint256[] private _snapshotIds;

    // Tier checking
    uint256[] public kdxStakedTiers = [
        uint256(1000 * 1e18), // Silver
        uint256(3000 * 1e18),  // Platinum
        uint256(10000 * 1e18),  // Sapphire
        uint256(30000 * 1e18)  // Diamond
    ];

    constructor(IStKDX _stKdx) {
        stKdx = _stKdx;
    }

    function addSnapshotIds (uint256 _id) public onlyOwner {
        require(_id > 0, "invalid!!!");
        _snapshotIds.push(_id);
    }

    function getTier (address _account) external view returns(uint256) {
        uint256 kdxStaked = _getSmallestSnapshot(_account);
        uint256 tier = 0;
        while(tier < kdxStakedTiers.length && kdxStaked >= kdxStakedTiers[tier]) {
            tier ++;
        }
        return tier;
    }

    function snapshotLength() public view returns (uint256) {
        return _snapshotIds.length;
    }

    function _getSmallestSnapshot(address _account)
        private
        view
        returns (uint256)
    {
        if (_snapshotIds.length == 0) return 0;
        uint256 store = stKdx.getKdxBalanceAt(_account, _snapshotIds[0]);
        for (uint256 i = 1; i < _snapshotIds.length; i++) {
            uint256 kdxStaked = stKdx.getKdxBalanceAt(_account, _snapshotIds[i]);
            if (store > kdxStaked) {
                store = kdxStaked;
            }
        }
        return store;
    }
}
