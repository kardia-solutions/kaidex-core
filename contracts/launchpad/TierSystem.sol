//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IStKDX.sol";

contract TierSystem is Ownable {
    using SafeMath for uint256;
    IStKDX public stKdx;
    // Tier checking
    uint256[4] public kdxStakedTiers = [
        uint256(1000 * 1e18), // Silver
        uint256(3000 * 1e18),  // Platinum
        uint256(10000 * 1e18),  // Sapphire
        uint256(30000 * 1e18)  // Diamond
    ];

    constructor(IStKDX _stKdx) {
        stKdx = _stKdx;
    }

    function setKdxStakedTiers (uint256[4] memory _tiers) public onlyOwner {
        kdxStakedTiers = _tiers;
    }

    function getTier (address _account, uint256[] memory _snapshotIds) external view returns(uint256) {
        uint256 kdxStaked = _getAverage(_account,_snapshotIds);
        uint256 tier = 0;
        while(tier < kdxStakedTiers.length && kdxStaked >= kdxStakedTiers[tier]) {
            tier ++;
        }
        return tier;
    }

    function getAverage (address _account, uint256[] memory _snapshotIds) public view returns (uint256) {
        return _getAverage((_account), _snapshotIds);
    }

    function _getAverage(address _account, uint256[] memory _snapshotIds)
        private
        view
        returns (uint256)
    {
        if (_snapshotIds.length == 0) return 0;
        uint256 averageBalance;
        for (uint256 i = 0; i < _snapshotIds.length; i++) {
            averageBalance = averageBalance.add(stKdx.getKdxBalanceAt(_account, _snapshotIds[i]));
        }
        return averageBalance / _snapshotIds.length;
    }
}
