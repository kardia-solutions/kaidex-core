// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMinterAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMinter.sol";


contract ERC721MinterAdapter is IMinterAdapter, Ownable {

    address public inoContract;
    IMinter public erc721NFTContract;
    uint256 public constant MAX_NFT_SALES = 1000;

    constructor(address nft){
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


    function isMinter() external pure override returns (bool)  {
        return true;
    }

    function mint(address receiver) external override onlyINO returns(bool)  {
        uint256 tokenId = erc721NFTContract.mint(receiver);
        return tokenId > 0 ? true : false;
    }

    // maximum nft amount user can mint
    function maximunTicketByUser (address userAddr) external view override returns(uint256) {
        return 10;
    }

    // Maximun NFT sales
    function maximunNFTSales () external view override returns (uint256) {
        return MAX_NFT_SALES;
    }
}