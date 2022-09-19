// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinterAdapter {
    function isMinter() external view returns (bool);    
    function mint(address receiver) external returns(bool);
    function maximumTicketByUser (address userAddr) external view returns(uint256);
    function maximumNFTSales () external view returns (uint256);
}