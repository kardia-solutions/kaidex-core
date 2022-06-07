// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0xeabd4203d3b3794d336441e4ca6a5d97005e9a70"; // USDT
const _offeringToken = "0xc4A4fFA90379694B477B04BA66A5feCce5CDdd25";  // KDX
const _startTime = "1654575600";
const _endTime = "1654582800";
const _offeringAmount = "100000000000000000000000";
const _raisingAmount = "100000000000";
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const RaiseFunding = await hre.ethers.getContractFactory("RaiseFunding");
  const raiseFunding = await RaiseFunding.deploy(_buyToken, _offeringToken, _startTime, _endTime, _offeringAmount, _raisingAmount);
  await raiseFunding.deployed();
  console.log("Raise Funding deployed to:", raiseFunding.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
//   Raise Funding deployed to: 0xDB9bCd9A1b9405B325b4432Ec06Da6b0ECe45c2D