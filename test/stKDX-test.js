const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking KAIDEX Token", function () {
  before(async function () {
    this.KaiDexToken = await ethers.getContractFactory("KaiDexToken")
    this.stKDX = await ethers.getContractFactory("stKDX")
    this.signers = await ethers.getSigners()
    this.alice = this.signers[0]
    this.bob = this.signers[1]
    this.carol = this.signers[2]
  })

  beforeEach(async function () {
    this.kdx = await this.KaiDexToken.deploy()
    this.stKDX = await this.stKDX.deploy(this.kdx.address)
    this.kdx.mint(this.alice.address, "100")
    this.kdx.mint(this.bob.address, "100")
    this.kdx.mint(this.carol.address, "100")
  })

  it("should not allow enter if not enough approve", async function () {
    await expect(this.stKDX.enter("100")).to.be.revertedWith("ERC20: insufficient allowance")
    await this.kdx.approve(this.stKDX.address, "50")
    await expect(this.stKDX.enter("100")).to.be.revertedWith("ERC20: insufficient allowance")
    await this.kdx.approve(this.stKDX.address, "100")
    await this.stKDX.enter("100")
    expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("100")
    await this.kdx.approve(this.stKDX.address, "100")
  })

  // it("should not allow withraw more than what you have", async function () {
  //   // await this.kdx.approve(this.stKDX.address, "100")
  //   // await this.stKDX.enter("100")
  //   // await expect(this.stKDX.leave("200")).to.be.revertedWith("ERC20: burn amount exceeds balance")
  // })

  // it("should work with more than one participant", async function () {
  //   await this.kdx.approve(this.stKDX.address, "100")
  //   await this.kdx.connect(this.bob).approve(this.stKDX.address, "100", { from: this.bob.address })
  //   // Alice enters and gets 20 shares. Bob enters and gets 10 shares.
  //   await this.stKDX.enter("20")
  //   await this.stKDX.connect(this.bob).enter("10", { from: this.bob.address })
  //   expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("20")
  //   expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("10")
  //   expect(await this.kdx.balanceOf(this.stKDX.address)).to.equal("30")
  //   // stKDX get 20 more stKDX from an external source.
  //   await this.kdx.connect(this.carol).transfer(this.stKDX.address, "20", { from: this.carol.address })
  //   // Alice deposits 10 more stKDX. She should receive 10*30/50 = 6 shares.
  //   await this.stKDX.enter("10")
  //   expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("26")
  //   expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("10")
  //   // Bob withdraws 5 shares. He should receive 5*60/36 = 8 shares
  //   await this.stKDX.connect(this.bob).leave("5", { from: this.bob.address })
  //   expect(await this.stKDX.balanceOf(this.alice.address)).to.equal("26")
  //   expect(await this.stKDX.balanceOf(this.bob.address)).to.equal("5")
  //   expect(await this.kdx.balanceOf(this.stKDX.address)).to.equal("52")
  //   expect(await this.kdx.balanceOf(this.alice.address)).to.equal("70")
  //   expect(await this.kdx.balanceOf(this.bob.address)).to.equal("98")
  // })
})