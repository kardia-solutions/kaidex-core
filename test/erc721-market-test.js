const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

const feeAddress = "0xf2f5c73fa04406b1995e397b55c24ab1f3ea726c";

describe("KAIDEX ERC721 Marketplace", function () {
    before(async function () {
        this.provider = waffle.provider;
        this.ERC721NFTMarket = await ethers.getContractFactory("ERC721NFTMarket")
        this.ERC20 = await ethers.getContractFactory("ERC20Mock")
        this.NFT721 = await ethers.getContractFactory("NFTMockup")
        this.WETH = await ethers.getContractFactory("WETH");
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.john = this.signers[3]
        this.lew = this.signers[4]
        this.usdtOwner = this.signers[5]
        this.dang = this.signers[6]
    })

    beforeEach(async function () {
        this.weth = await this.WETH.deploy();
        this.nft721 = await this.NFT721.deploy();
        this.erc20 = await this.ERC20.deploy();
        this.marketplace = await this.ERC721NFTMarket.deploy(this.weth.address, feeAddress, 500)
    })
})