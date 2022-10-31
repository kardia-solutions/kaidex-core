// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinterAdapterWhitelist {
    function isMinter() external view returns (bool);    
    function mint(address receiver) external returns(uint256);
    function maximumTicketByUser (address userAddr) external view returns(uint256);
    function maximumNFTSales () external view returns (uint256);
}