// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITierSystem {
    function getTier (address _account, uint256[] memory _snapshotIds) external view returns(uint256);
}