// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const masterchef="0x1bc8FaF3F74939b3961F6ceB053EE43297b11BD9";
const masterpool=1;
const kdx_token="0xDc9b08850CBBAb62aA13274af3F42737900342e3";


async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const KaidexMasterChefV2 = await hre.ethers.getContractFactory("KaidexMasterChefV2");
  const kaidexMasterChefV2 = await KaidexMasterChefV2.deploy(masterchef, kdx_token, masterpool);

  await kaidexMasterChefV2.deployed();

  console.log("KAIDEX Masterchef v2 deployed to:", kaidexMasterChefV2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
