// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract INOManager is Ownable {
  event NewINO(address _inoAddress, address _nftContract);
  address [] public inoList;
  mapping(address => address) nftContractMap;

  function addINO(address _inoAddress, address _nftContract) public onlyOwner {
    inoList.push(_inoAddress);
    nftContractMap[_inoAddress] = _nftContract;
    emit NewINO(_inoAddress, _nftContract);
  }

  function getINO(uint256 index) public view returns (address) {
    return inoList[index];
  }

  function totalINO() public view returns (uint256) {
    return inoList.length;
  }

  function getNFTContract(address inoAddress) public view returns (address) {
    return nftContractMap[inoAddress];
  }
}