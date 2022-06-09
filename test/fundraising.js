const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking KAIDEX Token", function () {
    before(async function () {
        this.KaiDexToken = await ethers.getContractFactory("KaiDexToken")
        this.StKDX = await ethers.getContractFactory("StKDX")
        this.TierSystem = await ethers.getContractFactory("TierSystem")
        this.ERC20 = await ethers.getContractFactory("ERC20Mock")
        this.FundRaising = await ethers.getContractFactory("FundRaising")
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
        this.kdx = await this.KaiDexToken.deploy("KAIDEX Token", "KDX", "1000000000000000000000000000000000000")
        this.stKDX = await this.StKDX.deploy(this.kdx.address)
        this.tierSystem = await this.TierSystem.deploy(this.stKDX.address)
        this.bean = await this.ERC20.deploy("BEAN", "BEAN", "50000000000000000000000")
        this.usdt = await this.ERC20.deploy("USDT", "USDT", "1000000000000000000000000")
        this.kdx.mint(this.alice.address, "1000000000000000000000000000")
        this.kdx.mint(this.bob.address, "1000000000000000000000000000")
        this.kdx.mint(this.carol.address, "1000000000000000000000000000")
        this.kdx.mint(this.john.address, "1000000000000000000000000000")
        this.kdx.mint(this.lew.address, "1000000000000000000000000000")

        await this.usdt.transfer(this.usdtOwner.address, "1000000000000000000000000")
        await this.usdt.connect(this.usdtOwner).transfer(this.alice.address, "50000000000000000000000")
        await this.usdt.connect(this.usdtOwner).transfer(this.bob.address, "50000000000000000000000")
        await this.usdt.connect(this.usdtOwner).transfer(this.carol.address, "50000000000000000000000")
        await this.usdt.connect(this.usdtOwner).transfer(this.john.address, "50000000000000000000000")
        await this.usdt.connect(this.usdtOwner).transfer(this.lew.address, "50000000000000000000000")
    })

    it("IDO work right!", async function () {
        // Rasie: 50K USDT
        // Offer Token: 50K BEAN
        this.fundRaising = await this.FundRaising.deploy(this.usdt.address, this.bean.address, 0, 0, 0, "50000000000000000000000", "50000000000000000000000", this.tierSystem.address);
        // Transfer bean to ido contract
        await this.bean.transfer(this.fundRaising.address, "50000000000000000000000")
        await this.kdx.approve(this.stKDX.address, "1000000000000000000000000000000000000");
        await this.kdx.connect(this.bob).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.kdx.connect(this.carol).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.carol.address });
        await this.kdx.connect(this.john).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.john.address });
        await this.kdx.connect(this.lew).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.lew.address });
        await this.stKDX.enter("30000000000000000000000"); // 30K
        await this.stKDX.connect(this.bob).enter("5000000000000000000000"); // 5k
        await this.stKDX.connect(this.carol).enter("10000000000000000000000"); // 10k
        await this.stKDX.connect(this.john).enter("20000000000000000000000"); // 20k
        await this.stKDX.connect(this.lew).enter("1000000000000000000000"); // 1k
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.connect(this.bob).transfer(this.lew.address, "4500000000000000000000")
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        expect(await this.tierSystem.getTier(this.alice.address, [1,2,3,4,5,6,7])).to.equal("4")
        expect(await this.tierSystem.getTier(this.bob.address, [1,2,3,4,5,6,7])).to.equal("2")
        expect(await this.tierSystem.getTier(this.carol.address, [1,2,3,4,5,6,7])).to.equal("3")
        expect(await this.tierSystem.getTier(this.john.address, [1,2,3,4,5,6,7])).to.equal("3")
        expect(await this.tierSystem.getTier(this.lew.address, [1,2,3,4,5,6,7])).to.equal("1")
        
        // Approve raising token (kdx) to fundraising contract
        await this.usdt.approve(this.fundRaising.address, "1000000000000000000000000000000000000");
        await this.usdt.connect(this.bob).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.usdt.connect(this.carol).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.carol.address });
        await this.usdt.connect(this.john).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.john.address });
        await this.usdt.connect(this.lew).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.lew.address });

        // Set snapshot ids
        await this.fundRaising.setSnapshotIds([1,2,3,4,5,6,7]);

        // Deposit
        await this.fundRaising.deposit("20000000000000000000000");
        await this.fundRaising.deposit("20000000000000000000000"); 
        const aliceInfo = await this.fundRaising.userInfo(this.alice.address);
        // // Allice's total deposite: 30K usdt
        expect(aliceInfo[0].toString()).to.equal("30000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("30000000000000000000000");
        expect(await this.usdt.balanceOf(this.alice.address)).to.equal("20000000000000000000000");

        // // Bob deposit fail
        // await expect(this.fundRaising.connect(this.bob).deposit("20000000000000000000000")).to.be.revertedWith("not eligible amount!!")

        // Carol's total deposite: 10K usdt
        await this.fundRaising.connect(this.carol).deposit("20000000000000000000000");
        const carolInfo = await this.fundRaising.userInfo(this.carol.address);
        expect(carolInfo[0].toString()).to.equal("10000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("40000000000000000000000");
        expect(await this.usdt.balanceOf(this.carol.address)).to.equal("40000000000000000000000");

        // john's total deposite: 5K usdt
        await this.fundRaising.connect(this.john).deposit("5000000000000000000000");
        const johnInfo = await this.fundRaising.userInfo(this.john.address);
        expect(johnInfo[0].toString()).to.equal("5000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("45000000000000000000000");
        expect(await this.usdt.balanceOf(this.john.address)).to.equal("45000000000000000000000");

        // lew's total deposite: 1K usdt
        await this.fundRaising.connect(this.lew).deposit("1000000000000000000000");
        const lewInfo = await this.fundRaising.userInfo(this.lew.address);
        expect(lewInfo[0].toString()).to.equal("1000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("46000000000000000000000");
        expect(await this.usdt.balanceOf(this.lew.address)).to.equal("49000000000000000000000");

        // Total raised: 46K
        // Rate: 1:1
        // Alice deposit 30K usdt => 30K bean
        // Carol deposit 10K usdt => 10K bean
        // John deposit 5K usdt => 5K bean
        // Lew deposit 1K usdt => 1K bean

        // Harvest process

        // Alice harvest
        await this.fundRaising.harvest();
        expect(await this.bean.balanceOf(this.alice.address)).to.equal("30000000000000000000000");
        await expect(this.fundRaising.harvest()).to.be.revertedWith("nothing to harvest")

        // Bob harvest
        await this.fundRaising.connect(this.bob).harvest();
        expect(await this.bean.balanceOf(this.bob.address)).to.equal("0");
        await expect(this.fundRaising.connect(this.bob).harvest()).to.be.revertedWith("nothing to harvest")

        // john harvest
        await this.fundRaising.connect(this.john).harvest();
        expect(await this.bean.balanceOf(this.john.address)).to.equal("5000000000000000000000");
        await expect(this.fundRaising.connect(this.john).harvest()).to.be.revertedWith("nothing to harvest")

        // Carol harvest
        await this.fundRaising.connect(this.carol).harvest();
        expect(await this.bean.balanceOf(this.carol.address)).to.equal("10000000000000000000000");
        await expect(this.fundRaising.connect(this.carol).harvest()).to.be.revertedWith("nothing to harvest")

        // Lew harvest
        await this.fundRaising.connect(this.lew).harvest();
        expect(await this.bean.balanceOf(this.lew.address)).to.equal("1000000000000000000000");
        await expect(this.fundRaising.connect(this.lew).harvest()).to.be.revertedWith("nothing to harvest")

        expect(await this.bean.balanceOf(this.fundRaising.address)).to.equal("4000000000000000000000");

        // Finalize withdraw
        await this.fundRaising.finalWithdraw(this.dang.address);
        expect(await this.usdt.balanceOf(this.dang.address)).to.equal("46000000000000000000000");
        expect(await this.usdt.balanceOf(this.fundRaising.address)).to.equal("0");

        // emergency withdraw
        await this.fundRaising.emergencyWithdraw(this.bean.address, this.dang.address);
        expect(await this.bean.balanceOf(this.dang.address)).to.equal("4000000000000000000000");
    })

    it("IDO work right!!!!!", async function () {
        // Rasie: 20K USDT
        // Offer Token: 20K BEAN
        this.fundRaising = await this.FundRaising.deploy(this.usdt.address, this.bean.address, 0, 0, 0, "20000000000000000000000", "20000000000000000000000", this.tierSystem.address);
        // Transfer bean to ido contract
        await this.bean.transfer(this.fundRaising.address, "20000000000000000000000")
        await this.kdx.approve(this.stKDX.address, "1000000000000000000000000000000000000");
        await this.kdx.connect(this.bob).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.kdx.connect(this.carol).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.carol.address });
        await this.kdx.connect(this.john).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.john.address });
        await this.kdx.connect(this.lew).approve(this.stKDX.address, "1000000000000000000000000000000000000", { from: this.lew.address });
        await this.stKDX.enter("30000000000000000000000"); // 30K
        await this.stKDX.connect(this.bob).enter("5000000000000000000000"); // 5k
        await this.stKDX.connect(this.carol).enter("10000000000000000000000"); // 10k
        await this.stKDX.connect(this.john).enter("20000000000000000000000"); // 20k
        await this.stKDX.connect(this.lew).enter("1000000000000000000000"); // 1k
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.connect(this.bob).transfer(this.lew.address, "4500000000000000000000")
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();
        await this.stKDX.snapshot();

        expect(await this.tierSystem.getTier(this.alice.address, [1,2,3,4,5,6,7])).to.equal("4")
        expect(await this.tierSystem.getTier(this.bob.address, [1,2,3,4,5,6,7])).to.equal("2")
        expect(await this.tierSystem.getTier(this.carol.address, [1,2,3,4,5,6,7])).to.equal("3")
        expect(await this.tierSystem.getTier(this.john.address, [1,2,3,4,5,6,7])).to.equal("3")
        expect(await this.tierSystem.getTier(this.lew.address, [1,2,3,4,5,6,7])).to.equal("1")
        
        // Approve raising token (kdx) to fundraising contract
        await this.usdt.approve(this.fundRaising.address, "1000000000000000000000000000000000000");
        await this.usdt.connect(this.bob).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.bob.address });
        await this.usdt.connect(this.carol).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.carol.address });
        await this.usdt.connect(this.john).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.john.address });
        await this.usdt.connect(this.lew).approve(this.fundRaising.address, "1000000000000000000000000000000000000", { from: this.lew.address });

        // Set snapshot ids
        await this.fundRaising.setSnapshotIds([1,2,3,4,5,6,7]);

        // Deposit
        await this.fundRaising.deposit("20000000000000000000000");
        await this.fundRaising.deposit("20000000000000000000000"); 
        const aliceInfo = await this.fundRaising.userInfo(this.alice.address);
        // Allice's total deposite: 30K usdt
        expect(aliceInfo[0].toString()).to.equal("30000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("30000000000000000000000");
        expect(await this.usdt.balanceOf(this.alice.address)).to.equal("20000000000000000000000");

        // // Bob deposit fail
        // await expect(this.fundRaising.connect(this.bob).deposit("20000000000000000000000")).to.be.revertedWith("not eligible amount!!")

        // Carol's total deposite: 10K usdt
        await this.fundRaising.connect(this.carol).deposit("20000000000000000000000");
        const carolInfo = await this.fundRaising.userInfo(this.carol.address);
        expect(carolInfo[0].toString()).to.equal("10000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("40000000000000000000000");
        expect(await this.usdt.balanceOf(this.carol.address)).to.equal("40000000000000000000000");

        // john's total deposite: 5K usdt
        await this.fundRaising.connect(this.john).deposit("5000000000000000000000");
        const johnInfo = await this.fundRaising.userInfo(this.john.address);
        expect(johnInfo[0].toString()).to.equal("5000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("45000000000000000000000");
        expect(await this.usdt.balanceOf(this.john.address)).to.equal("45000000000000000000000");

        // lew's total deposite: 1K usdt
        await this.fundRaising.connect(this.lew).deposit("1000000000000000000000");
        const lewInfo = await this.fundRaising.userInfo(this.lew.address);
        expect(lewInfo[0].toString()).to.equal("1000000000000000000000");
        expect(await this.fundRaising.totalAmount()).to.equal("46000000000000000000000");
        expect(await this.usdt.balanceOf(this.lew.address)).to.equal("49000000000000000000000");

        // Total raised: 46K
        // Rate: 1:1
        // Alice deposit 30K usdt => 30 * 20 / 46 = 13043460000000000000000 bean + 30K 
        // Carol deposit 10K usdt => 10 * 20 / 46 = ~4.3 bean
        // John deposit 5K usdt => 5 * 20 / 46 bean
        // Lew deposit 1K usdt => 1 * 20 / 46 bean

        // Harvest process

        // Alice harvest
        await this.fundRaising.harvest();
        expect(await this.bean.balanceOf(this.alice.address)).to.equal("43043478260869565200000");
        await expect(this.fundRaising.harvest()).to.be.revertedWith("nothing to harvest")

        // Bob harvest
        await this.fundRaising.connect(this.bob).harvest();
        expect(await this.bean.balanceOf(this.bob.address)).to.equal("0");
        await expect(this.fundRaising.connect(this.bob).harvest()).to.be.revertedWith("nothing to harvest")

        // john harvest
        await this.fundRaising.connect(this.john).harvest();
        expect(await this.bean.balanceOf(this.john.address)).to.equal("2173913043478260860000");
        await expect(this.fundRaising.connect(this.john).harvest()).to.be.revertedWith("nothing to harvest")

        // Carol harvest
        await this.fundRaising.connect(this.carol).harvest();
        expect(await this.bean.balanceOf(this.carol.address)).to.equal("4347826086956521720000");
        await expect(this.fundRaising.connect(this.carol).harvest()).to.be.revertedWith("nothing to harvest")

        // Lew harvest
        await this.fundRaising.connect(this.lew).harvest();
        expect(await this.bean.balanceOf(this.lew.address)).to.equal("434782608695652160000");
        await expect(this.fundRaising.connect(this.lew).harvest()).to.be.revertedWith("nothing to harvest")

        expect(await this.bean.balanceOf(this.fundRaising.address)).to.equal("60000");

        // // Finalize withdraw
        await this.fundRaising.finalWithdraw(this.dang.address);
        expect(await this.usdt.balanceOf(this.dang.address)).to.equal("19999999999999999940000");
        expect(await this.usdt.balanceOf(this.fundRaising.address)).to.equal("0");

        // // emergency withdraw
        await this.fundRaising.emergencyWithdraw(this.bean.address, this.dang.address);
        expect(await this.bean.balanceOf(this.dang.address)).to.equal("60000");
    })
})