// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const dev_address="0x5D94B6dA25A95067e0647bc8F6597823ea09162e";
const kdx_per_block="100000000000000000000";
const start_block=7957800;
const lp_mock_token="0x9F19540d920E64a4E5aA8E27A7cB9E8Ed6be473D"


async function main() {

  // KAIDEX token deploy
  const KaiDexToken = await hre.ethers.getContractFactory("KaiDexToken");
  const kaiDexToken = await KaiDexToken.deploy();
  await kaiDexToken.deployed();
  console.log("************ KAIDEX Token deployed to:", kaiDexToken.address);
  
  // Deploy masterchef v1
  const KaidexMasterChef = await hre.ethers.getContractFactory("KaidexMasterChef");
  const kaidexMasterChef = await KaidexMasterChef.deploy(kaiDexToken.address, dev_address, kdx_per_block, start_block, 0);
  await kaidexMasterChef.deployed();
  console.log("************ KAIDEX Masterchef deployed to:", kaidexMasterChef.address);

  // Create the first pool
  const first_pool = await kaidexMasterChef.add("10000000000000000000", lp_mock_token, true)
  console.log("first_pool", first_pool.hash)

  // Transfer ownership
  const transfer_x = await kaiDexToken.transferOwnership(kaidexMasterChef.address)
  console.log("Transfer_x", transfer_x.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
