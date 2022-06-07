const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking KAIDEX Token", function () {
  before(async function () {
    this.KaiDexToken = await ethers.getContractFactory("KaiDexToken")
    this.StKDX = await ethers.getContractFactory("StKDX")
    this.signers = await ethers.getSigners()
    this.alice = this.signers[0]
    this.bob = this.signers[1]
    this.carol = this.signers[2]
  })

  beforeEach(async function () {
    this.kdx = await this.KaiDexToken.deploy("KAIDEX Token", "KDX", "100000000")
    this.stKDX = await this.StKDX.deploy(this.kdx.address)
    this.kdx.mint(this.alice.address, "10000")
    this.kdx.mint(this.bob.address, "10000")
    this.kdx.mint(this.carol.address, "10000")
  })

  it("should not allow enter if not enough approve", async function () {
    await expect(this.stKDX.enter("1000")).to.be.revertedWith("ERC20: insufficient allowance")
    await this.kdx.approve(this.stKDX.address, "50")
    await expect(this.stKDX.enter("1000")).to.be.revertedWith("ERC20: insufficient allowance")
    await this.kdx.approve(this.stKDX.address, "1000000")
    await this.stKDX.enter("1000")
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("1000")
  })

  it("should not allow withraw more than what you have", async function () {
    await this.kdx.approve(this.stKDX.address, "100")
    await this.stKDX.enter("100")
    await expect(this.stKDX.leave("200")).to.be.revertedWith("ERC20: burn amount exceeds balance")
  })

  it("should work with more than one participant", async function () {
    await this.kdx.approve(this.stKDX.address, "100")
    await this.kdx.connect(this.bob).approve(this.stKDX.address, "100", { from: this.bob.address })
    // Alice enters and gets 20 shares. Bob enters and gets 10 shares.
    await this.stKDX.enter("20")
    await this.stKDX.connect(this.bob).enter("10", { from: this.bob.address })
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("20")
    expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("10")
    expect(await this.kdx.balanceOf(this.stKDX.address)).to.equal("30")
    // stKDX get 20 more stKDX from an external source.
    await this.kdx.connect(this.carol).transfer(this.stKDX.address, "20", { from: this.carol.address })
    // Alice deposits 10 more stKDX. She should receive 10*30/50 = 6 shares.
    await this.stKDX.enter("10")
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("26")
    expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("10")
    // Bob withdraws 5 shares. He should receive 5*60/36 = 8 shares
    await this.stKDX.connect(this.bob).leave("5", { from: this.bob.address })
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("26")
    expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("5")
    expect(await this.kdx.balanceOf(this.stKDX.address)).to.equal("52")
    expect(await this.kdx.balanceOf(this.alice.address)).to.equal("9970")
    expect(await this.kdx.balanceOf(this.bob.address)).to.equal("9998")
  })

  it ("snapshot woring rigth!!", async function () {
    await this.kdx.approve(this.stKDX.address, "100")
    await this.kdx.connect(this.bob).approve(this.stKDX.address, "100", { from: this.bob.address })
    // Alice enters and gets 20 shares. Bob enters and gets 10 shares.
    await this.stKDX.enter("20")
    await this.stKDX.connect(this.bob).enter("10", { from: this.bob.address })
    await this.stKDX.snapshot();
    expect(await this.stKDX.getCurrentSnapshotId()).to.equal(1)
    expect(await this.stKDX.getRatioAt(1)).to.equal("1000000000000000000")
    expect(await this.stKDX.getKdxBalanceAt(this.alice.address, 1)).to.equal("20")
    expect(await this.stKDX.getKdxBalanceAt(this.bob.address, 1)).to.equal("10")
    expect(await this.stKDX.balanceOfAt(this.alice.address, 1)).to.equal("20")
    expect(await this.stKDX.balanceOfAt(this.bob.address, 1)).to.equal("10")
    // stKDX get 20 more stKDX from an external source.
    await this.kdx.connect(this.carol).transfer(this.stKDX.address, "20", { from: this.carol.address })
    // Alice deposits 10 more stKDX. She should receive 10*30/50 = 6 shares.
    await this.stKDX.enter("10")
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("26")
    // Balance Kdx of Alice: 36 * 60 / 26 = 15.6
    expect(await this.stKDX.getKdxBalance(this.alice.address)).to.equal("43")
    // Balance Kdx of Alice: 36 * 60 / 26 = 15.6
    expect(await this.stKDX.getKdxBalanceAt(this.alice.address, 1)).to.equal("20")
    await this.stKDX.snapshot();
    expect(await this.stKDX.getCurrentSnapshotId()).to.equal(2)
    // Alice deposits 10 more stKDX. She should receive 10 * 36 / 60 + 26 = 6 shares.
    await this.stKDX.enter("10")
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("32")
    expect(await this.stKDX.getKdxBalanceAt(this.alice.address, 2)).to.equal("43")
    expect(await this.stKDX.getKdxBalance(this.alice.address)).to.equal("53")
    expect(await this.stKDX.getRatioAt(2)).to.equal("1666666666666666666")
  })
})