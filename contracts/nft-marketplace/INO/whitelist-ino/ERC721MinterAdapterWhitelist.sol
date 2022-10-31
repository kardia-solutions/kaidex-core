// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../interfaces/IMinterAdapterWhitelist.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./../interfaces/IMinter.sol";
import "./Whitelist.sol";

contract ERC721MinterAdapterWhitelist is IMinterAdapterWhitelist, Ownable, Whitelist {

    address public inoContract;
    IMinter public erc721NFTContract;
    uint256 public constant MAX_NFT_SALES = 1000;
    uint256 public maxTicketForWhitelistedUser = 2;

    // Total NFT minted
    uint256 public minted;

    constructor(
        address nft
    ){
        require(nft != address(0), "address is invalid");
        erc721NFTContract = IMinter(nft);
    }

    modifier onlyINO {
        require(msg.sender == inoContract, "Only call by ino contract");
        _;
    }

    function setINOContract (address _ino) public onlyOwner {
        require(_ino != address(0), "address is invalid");
        inoContract = _ino;
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
        if (!whitelist[userAddr]) return 0;
        return maxTicketForWhitelistedUser;
    }

    // Maximum NFT sales
    function maximumNFTSales () external view override returns (uint256) {
        return MAX_NFT_SALES;
    }
}