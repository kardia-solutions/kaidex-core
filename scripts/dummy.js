// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const owner = "0x5D94B6dA25A95067e0647bc8F6597823ea09162e"

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DummyToken = await hre.ethers.getContractFactory("DummyToken");
  const dummyToken = await DummyToken.deploy();

  await dummyToken.deployed();
  console.log("Dummy Token deployed to:", dummyToken.address);
  const mint = await dummyToken.mint(owner, "1000000000000000000000")
  console.log("Mint dummy token send to owner: ", mint.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
