    // We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const _stKdx = "0x97094c22aed7cb346ba48266de27edfb1e6b1311"
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const TierSystem = await hre.ethers.getContractFactory("TierSystem");
  const tierSystem = await TierSystem.deploy(_stKdx);
  await tierSystem.deployed();
  console.log("Tier system deployed to:", tierSystem.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
//   Tier system deployed to: 0xDd650F2388C392DaD625b852CE7bbd2e41206246