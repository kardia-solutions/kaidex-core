// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMinterAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMinter.sol";
import "../../interfaces/ITierSystem.sol";

contract ERC721MinterAdapter is IMinterAdapter, Ownable {

    address public inoContract;
    IMinter public erc721NFTContract;
    uint256 public constant MAX_NFT_SALES = 1000;

    // Tier system
    ITierSystem public tierSystem;

    // snapshot ids
    uint256 snapshotFrom;
    uint256 snapshotTo;

    // Total NFT minted
    uint256 public minted;

    // Tier allocation
    uint256[5] public tierAllocations = [1,2,4,8,15];
    uint256[5] public tierBuySchedules; // Tier 1,2,3,4,5

    constructor(
        address nft,
        ITierSystem _tierSystem,
        uint256 _snapshotFrom,
        uint256 _snapshotTo,
        uint256[5] memory _tierBuySchedules
    ){
        require(nft != address(0), "address is invalid");
        erc721NFTContract = IMinter(nft);
        snapshotFrom = _snapshotFrom;
        snapshotTo = _snapshotTo;
        tierSystem = _tierSystem;
        require(_verifySchedules(_tierBuySchedules), "schedules were invalid");
        tierBuySchedules = _tierBuySchedules;
    }

    function _verifySchedules (uint256[5] memory _tierBuySchedules) private view returns (bool) {
        if (_tierBuySchedules.length != 5) return false;
        for(uint256 index = 0; index < _tierBuySchedules.length; ++index) {
            if (index == 0 && _tierBuySchedules[index] <= 0) return false;
            if (index > 0 && _tierBuySchedules[index] > _tierBuySchedules[index - 1]) return false;
            if (_tierBuySchedules[index] < block.timestamp) return false;
        }
        return true;
    }

    modifier onlyINO {
        require(msg.sender == inoContract, "Only call by ino contract");
        _;
    }

    function setSnapshotFrom (uint256 id) public onlyOwner {
        require(id > 0, 'Id invalid');
        snapshotFrom = id;
    }

    function setSnapshotTo (uint256 id) public onlyOwner {
        require(id > 0, 'Id invalid');
        snapshotTo = id;
    }

    function setINOContract (address _ino) public onlyOwner {
        require(_ino != address(0), "address is invalid");
        inoContract = _ino;
    }

    function isValidTierTime (address _user) external view override returns (bool) {
        uint256 tier = tierSystem.getTierFromTo(_user, snapshotFrom, snapshotTo);
        if (tier == 0) return false;
        if (tierBuySchedules[tier - 1] < block.timestamp) return true;
        return false;
    }


    function isMinter() external pure override returns (bool) {
        return true;
    }

    function mint(address receiver) external override onlyINO returns(uint256)  {
        require(minted < MAX_NFT_SALES, "maximum!!");
        uint256 tokenId = erc721NFTContract.mint(receiver);
        minted ++;
        return tokenId;
    }

    // maximum nft amount user can mint
    function maximumTicketByUser (address userAddr) external view override returns(uint256) {
        uint256 tier = tierSystem.getTierFromTo(userAddr, snapshotFrom, snapshotTo);
        if (tier == 0) return 0;
        return tierAllocations[tier-1];
    }

    // Maximum NFT sales
    function maximumNFTSales () external view override returns (uint256) {
        return MAX_NFT_SALES;
    }


    function getSnapshotFrom() external view override returns(uint256) {
        return snapshotFrom;
    }

    function getSnapshotTo() external view override returns(uint256) {
        return snapshotTo;
    }

    function getAllocationByTier(uint256 _tier) external view override returns(uint256) {
        require(_tier > 0 && _tier <= 5, "Tier was invalid");
        return tierAllocations[_tier - 1];
    }

    function getBuySchedulesBuyTier(uint256 _tier) external view override returns(uint256) {
        require(_tier > 0 && _tier <= 5, "Tier was invalid");
        return tierBuySchedules[_tier - 1];
    }
}