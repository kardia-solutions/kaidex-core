// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinter {  
    function mint(address receiver) external returns (uint256);
}