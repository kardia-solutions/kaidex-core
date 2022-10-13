// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000"; // KAI
const _offeringToken = "0x1110A87c7664e819fca35B9B0f6d31f64aC78963";  // WKAI
const _startTime = "1665634200";
const _endTime = "1665634800";
const _harvestTime = "1665634800"
const _refundStartTime = "1665634800";
const _refundEndTime = "1665635400";
const _offeringAmount = "1000000000000000000000";
const _raisingAmount = "100000000000000000000";
const _tier = "0x104D8e975600a4c7C93faD7850F6927964B0aa94"
const _snapshotForm = 1;
const _snapshotTo = 4;
const _multiplier = "37500000";
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const FundRaising = await hre.ethers.getContractFactory("FundRaisingRefundable");
  const fundRaising = await FundRaising.deploy(
    _buyToken,
    _offeringToken,
    _offeringAmount,
    _raisingAmount,
    _tier,
    _snapshotForm,
    _snapshotTo,
    _multiplier,
    { gasLimit: 30000000 });
  await fundRaising.deployed();
  console.log("FundRaising deployed to:", fundRaising.address);
  // initTime 
  const { hash } = await fundRaising.initTime(
    _startTime,
    _endTime,
    _harvestTime,
    _refundStartTime,
    _refundEndTime)
  console.log("InitTime", hash)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  // FundRaising deployed to: 0xB8b177170deC5ecC647E87F37206f03321C5303d