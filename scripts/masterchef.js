// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const kdx_token="0xf45b9D886421Dd06349d9De5069973d3a925C60A";
const dev_address="0x5D94B6dA25A95067e0647bc8F6597823ea09162e";
const kdx_per_block=10;
const start_block=7957800;


async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const KaidexMasterChef = await hre.ethers.getContractFactory("KaidexMasterChef");
  const kaidexMasterChef = await KaidexMasterChef.deploy(kdx_token, kdx_per_block, start_block);

  await kaidexMasterChef.deployed();

  console.log("KAIDEX Masterchef deployed to:", kaidexMasterChef.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
