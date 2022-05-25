// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _kdx = "0xc4A4fFA90379694B477B04BA66A5feCce5CDdd25";
const _factory = "0x3c4aff03317d8a7704a1ff9ba1a1476df1ce3e44";
const _stkdx = "0x97094C22aeD7cb346Ba48266de27eDfB1E6B1311";
const _wkai = "0xaf984e23eaa3e7967f3c5e007fbe397d8566d23d";

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
