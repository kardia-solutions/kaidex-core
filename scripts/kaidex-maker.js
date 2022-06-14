// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _kdx = "0xb7aABF462677024Aa4b603A0e8A046eBa34b6e8e";
const _factory = "0x6208a282a0Bb02db05211B6D15fE793419B70E5c";
const _stkdx = "0xFc4aCfbb0e41DDFC50fF253C0dD5556f0E18FA9D";
const _wkai = "0xAF984E23EAA3E7967F3C5E007fbe397D8566D23d";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const KaidexMaker = await hre.ethers.getContractFactory("KaidexMaker");
  const kaidexMaker = await KaidexMaker.deploy(_factory, _stkdx, _kdx, _wkai);
  await kaidexMaker.deployed();

  console.log("KAIDEX Maker Token deployed to:", kaidexMaker.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
