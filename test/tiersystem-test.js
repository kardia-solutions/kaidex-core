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

    it("Did tier system work right??????????", async function () {
        await this.kdx.approve(this.stKDX.address, "1000000000000000000000000000000000000");
        await this.kdx.connect(this.bob).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.stKDX.enter("30000000000000000000000"); // 30K
        await this.stKDX.connect(this.bob).enter("10000000000000000000000"); // 10k
        await this.stKDX.snapshot();
        expect(await this.tierSystem.getTier(this.alice.address, [1])).to.equal("4")
        expect(await this.tierSystem.getTier(this.bob.address, [1])).to.equal("3")
        expect(await this.tierSystem.getAverage(this.alice.address, [1])).to.equal("30000000000000000000000")
        expect(await this.tierSystem.getAverage(this.bob.address, [1])).to.equal("10000000000000000000000")
        await this.stKDX.leave("19000000000000000000000"); // 19K
        await this.stKDX.connect(this.bob).leave("7000000000000000000000"); // 7k
        await this.stKDX.snapshot();
        expect(await this.tierSystem.getAverage(this.alice.address, [2])).to.equal("11000000000000000000000")
        expect(await this.tierSystem.getAverage(this.bob.address, [2])).to.equal("3000000000000000000000")
        // Allice average = (30 + 11) / 2 = 20.5k
        expect(await this.tierSystem.getAverage(this.alice.address, [1, 2])).to.equal("20500000000000000000000")
        // Bob average = (10 + 3) / 2 = 6.5K
        expect(await this.tierSystem.getAverage(this.bob.address, [1, 2])).to.equal("6500000000000000000000")
        expect(await this.tierSystem.getTier(this.alice.address, [1, 2])).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address,  [1, 2])).to.equal("2")
        await this.stKDX.leave("1000000000000000000000"); // 1k
        await this.stKDX.connect(this.bob).leave("1000000000000000000000"); // 1k
        await this.stKDX.snapshot();
        expect(await this.tierSystem.getAverage(this.alice.address, [3])).to.equal("10000000000000000000000")  // 10K
        expect(await this.tierSystem.getAverage(this.bob.address, [3])).to.equal("2000000000000000000000")
        // Allice average = (30 + 11 + 10) / 3 = 17k
        expect(await this.tierSystem.getAverage(this.alice.address, [1, 2, 3])).to.equal("17000000000000000000000")
        // // Bob average = (10 + 3 + 2) / 3 = 6.5K
        expect(await this.tierSystem.getAverage(this.bob.address, [1, 2, 3])).to.equal("5000000000000000000000")
        expect(await this.tierSystem.getTier(this.alice.address, [1, 2, 3])).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address,  [1, 2, 3])).to.equal("2")
    })

    it("Did tier system work right while transfer stKDX??????????", async function () {
        await this.kdx.approve(this.stKDX.address, "1000000000000000000000000000000000000");
        await this.kdx.connect(this.bob).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.kdx.connect(this.carol).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.carol.address });
        await this.stKDX.enter("30000000000000000000000"); // 30K
        await this.stKDX.connect(this.bob).enter("10000000000000000000000"); // 1k
        await this.stKDX.connect(this.carol).enter("1000000000000000000000"); // 1k
        await this.stKDX.snapshot();
        expect(await this.tierSystem.getTier(this.alice.address, [1])).to.equal("4")
        expect(await this.tierSystem.getTier(this.bob.address, [1])).to.equal("3")
        await this.stKDX.transfer(this.carol.address, "1000000000000000000000"); //1k
        await this.stKDX.snapshot();
        // Alice = (30 + 29) / 2 = 29.5K
        expect(await this.tierSystem.getTier(this.alice.address, [1, 2])).to.equal("3")
        expect(await this.tierSystem.getTier(this.bob.address, [1, 2])).to.equal("3")
        // Carol = (2 + 1) / 2 = 1.5k
        expect(await this.tierSystem.getAverage(this.carol.address, [1, 2])).to.equal("1500000000000000000000")
        expect(await this.tierSystem.getTier(this.carol.address, [1, 2])).to.equal("1")
    })
})