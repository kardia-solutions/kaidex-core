// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinter {
    function isMinter() external view returns (bool);    
    function mint() external;
}