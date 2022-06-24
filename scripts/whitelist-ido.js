// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _offeringToken = "0xc4a4ffa90379694b477b04ba66a5fecce5cddd25";  // KDX
const _startTime = "1656062100";
const _endTime = "1656063000";
const _harvestTime = "1656063000"
const _offeringAmount = "10000000000000000000";
const _raisingAmount = "5000000000000000000";
const _maxAllocation = "1000000000000000000";
const _maxAddrWhitelist = 5;
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

  // FundRaising deployed to: 0xB8b177170deC5ecC647E87F37206f03321C5303d