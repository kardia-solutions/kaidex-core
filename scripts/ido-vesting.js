// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000"; // KAI
const _offeringToken = "0x1110A87c7664e819fca35B9B0f6d31f64aC78963";  // WKAI
const _startTime = "1662955800";
const _endTime = "1662970200";
const _harvestTime = "1662970200"
const _offeringAmount = "10000000000000000000000";
const _raisingAmount = "5000000000000000000000";
const _tier = "0x685d4719c1224D09a6b09b83a48aA04f5053a402"
const _snapshotForm = 1;
const _snapshotTo = 3
const _multiplier = "100000";
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const IDOVesting = await hre.ethers.getContractFactory("IDOVesting");
  const idoVesting = await IDOVesting.deploy(
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
    _multiplier,
    { gasLimit: 30000000 });
  await idoVesting.deployed();
  console.log("IDOVesting deployed to:", idoVesting.address);

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