const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

describe("Staking KAIDEX Token", function () {
    before(async function () {
        this.provider = waffle.provider;
        this.ERC20 = await ethers.getContractFactory("ERC20Mock")
        this.WhitelistRaising = await ethers.getContractFactory("WhitelistRaising")
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.one = this.signers[1]
        this.two = this.signers[2]
        this.three = this.signers[3]
        this.four = this.signers[4]
        this.usdtOwner = this.signers[5]
        this.five = this.signers[6]
        this.six = this.signers[7]
        this.seven = this.signers[8]
        this.eight = this.signers[9]
        this.nine = this.signers[10]
        this.ten = this.signers[11]
    })

    beforeEach(async function () {
        this.bean = await this.ERC20.deploy("BEAN", "BEAN", "50000")
    })

    it("IDO work right!", async function () {
        // Rasie: 100K KAI
        // Offer Token: 50K BEAN
        this.ido = await this.WhitelistRaising.deploy(this.bean.address, 0, 0, 0, "50000", "100000", 20000, 5);
        // Transfer bean to ido contract
        await this.bean.transfer(this.ido.address, "50000")
        // Deposit failed not whitelist address --------------------------------
        await expect(this.ido.connect(this.one).deposit("10000", {value: "10000"})).to.be.revertedWith("not whitelisted")
        // Whitelist failed cause not owner
        await expect(this.ido.connect(this.one).addAddressToWhitelist(this.one.address)).to.be.revertedWith("Ownable: caller is not the owner")
        // Owner whitelist
        await this.ido.addAddressToWhitelist(this.one.address);
        await this.ido.addAddressesToWhitelist([this.two.address, this.three.address, this.four.address]);
        await expect(this.ido.addAddressesToWhitelist([this.five.address, this.six.address])).to.be.revertedWith("full")
        await this.ido.addAddressesToWhitelist([this.five.address]);
        await expect(this.ido.addAddressToWhitelist(this.six.address)).to.be.revertedWith("full")
        await this.ido.removeAddressFromWhitelist(this.five.address);
        await this.ido.addAddressesToWhitelist([this.five.address]);
        // Deposit
        await this.ido.connect(this.one).deposit("20000", {value: "20000"});
        await this.ido.connect(this.two).deposit("20000", {value: "20000"});
        await this.ido.connect(this.three).deposit("30000", {value: "30000"});
        await this.ido.connect(this.four).deposit("20000", {value: "20000"});
        await this.ido.connect(this.five).deposit("20000", {value: "20000"});
        expect(await this.provider.getBalance(this.ido.address)).to.equal("100000");
        await expect(this.ido.connect(this.one).deposit("20000", {value: "20000"})).to.be.revertedWith("not eligible amount!!")

        // Havest
        await this.ido.connect(this.one).harvest();
        await expect(this.ido.connect(this.one).harvest()).to.be.revertedWith("nothing to harvest")
        await this.ido.connect(this.two).harvest();
        await this.ido.connect(this.three).harvest();
        await this.ido.connect(this.four).harvest();
        await this.ido.connect(this.five).harvest();
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.one.address)).to.equal("10000");
        expect(await this.bean.balanceOf(this.ido.address)).to.equal("0");
    })
})