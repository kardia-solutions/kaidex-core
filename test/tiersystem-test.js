const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking KAIDEX Token", function () {
    before(async function () {
        this.KaiDexToken = await ethers.getContractFactory("KaiDexToken")
        this.StKDX = await ethers.getContractFactory("StKDX")
        this.TierSystem = await ethers.getContractFactory("TierSystem")
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
    })

    beforeEach(async function () {
        this.kdx = await this.KaiDexToken.deploy("KAIDEX Token", "KDX", "1000000000000000000000000000000000000")
        this.stKDX = await this.StKDX.deploy(this.kdx.address)
        this.tierSystem = await this.TierSystem.deploy(this.stKDX.address)
        this.kdx.mint(this.alice.address, "1000000000000000000000000000")
        this.kdx.mint(this.bob.address, "1000000000000000000000000000")
        this.kdx.mint(this.carol.address, "1000000000000000000000000000")
    })

    it("Did tier system work rigt??????????", async function () {
        await this.kdx.approve(this.stKDX.address, "1000000000000000000000000000000000000");
        await this.kdx.connect(this.bob).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.stKDX.enter("30000000000000000000000"); // 30K
        await this.stKDX.connect(this.bob).enter("10000000000000000000000"); // 10k
        await this.stKDX.snapshot();
        await this.tierSystem.addSnapshotIds(1);
        expect(await this.tierSystem.getTier(this.alice.address)).to.equal("4")
        expect(await this.tierSystem.getTier(this.bob.address)).to.equal("3")
        await this.stKDX.leave("19000000000000000000000"); // 19K
        await this.stKDX.connect(this.bob).leave("7000000000000000000000"); // 900k
        await this.stKDX.snapshot();
        await this.tierSystem.addSnapshotIds(2);
        expect(await this.tierSystem.getTier(this.alice.address)).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address)).to.equal("2")
        await this.stKDX.leave("1000000000000000000000"); // 19K
        await this.stKDX.connect(this.bob).leave("1000000000000000000000"); // 900k
        await this.stKDX.snapshot();
        await this.tierSystem.addSnapshotIds(3);
        expect(await this.tierSystem.getTier(this.alice.address)).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address)).to.equal("1")
        await this.kdx.connect(this.carol).transfer(this.stKDX.address, "10000000000000000000000", { from: this.carol.address })
        await this.stKDX.snapshot();
        await this.tierSystem.addSnapshotIds(4);
        expect(await this.tierSystem.getTier(this.alice.address)).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address)).to.equal("1")
    })
})