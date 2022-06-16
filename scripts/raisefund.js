// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0xeabd4203d3b3794d336441e4ca6a5d97005e9a70"; // USDT
const _offeringToken = "0xc4A4fFA90379694B477B04BA66A5feCce5CDdd25";  // KDX
const _startTime = "1655102741";
const _endTime = "1655697562";
const _harvestTime = "1655697562"
const _offeringAmount = "100000000000000000000000";
const _raisingAmount = "100000000000";
const _tier = "0xBC6b92D6212D3775aF97A2E56A03e087fd31dc79"
const _snapshotForm = 0;
const _snapshotTo = 1
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const FundRaising = await hre.ethers.getContractFactory("FundRaising");
  const fundRaising = await FundRaising.deploy(
    _buyToken,
    _offeringToken,
    _startTime,
    _endTime,
    _harvestTime,
    _offeringAmount,
    _raisingAmount,
    _tier,
    _snapshotForm,
    _snapshotTo,
    { gasLimit: 30000000 });
  await fundRaising.deployed();
  console.log("FundRaising deployed to:", fundRaising.address);

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