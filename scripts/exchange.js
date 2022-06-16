// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const dev_address="0x98E683845ceDC6fc4a70065ee95777e07Bb1FF0D";
const wkai_address="0xAF984E23EAA3E7967F3C5E007fbe397D8566D23d";

async function main() {

  // Deploy Kaidex Factory
  // const KaiDexFactory = await hre.ethers.getContractFactory("KaiDexFactory");
  // const kaiDexFactory = await KaiDexFactory.deploy(dev_address);
  // await kaiDexFactory.deployed();
  // console.log("************ KAIDEX Factory deployed to:", kaiDexFactory.address);

  // Deploy Kaidex v3 router
  const KaiDexRouter = await hre.ethers.getContractFactory("KaiDexRouter");
  const kaiDexRouter = await KaiDexRouter.deploy("0x6208a282a0Bb02db05211B6D15fE793419B70E5c", wkai_address);
  await kaiDexRouter.deployed();
  console.log("************ KAIDEX Router deployed to:", kaiDexRouter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


// KAIDEX Factory deployed to: 0x6208a282a0Bb02db05211B6D15fE793419B70E5c
// KAIDEX Router deployed to: 0x3CF950F3EEFA2daE3B076c493329241f844dDb09