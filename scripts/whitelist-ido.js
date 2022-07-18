// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _offeringToken = "0xA971434fc1a9730bB2448ebdAfA7EC25290857f5";  // KDX
const _startTime = "1658134800";
const _endTime = "1658135700";
const _harvestTime = "1658136000"
const _offeringAmount = "4000000000000000000000000";
const _raisingAmount = "16000000000000000000000000";
const _maxAllocation = "5333000000000000000000";
const _maxAddrWhitelist = 3000;
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const WhitelistRaising = await hre.ethers.getContractFactory("WhitelistRaising");
  const whitelistRaising = await WhitelistRaising.deploy(
    _offeringToken,
    _startTime,
    _endTime,
    _harvestTime,
    _offeringAmount,
    _raisingAmount,
    _maxAllocation,
    _maxAddrWhitelist,
    { gasLimit: 30000000 });
  await whitelistRaising.deployed();
  console.log("FundRaising deployed to:", whitelistRaising.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

