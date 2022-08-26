// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _weth="0x1110A87c7664e819fca35B9B0f6d31f64aC78963";
const _feeRecipient="0x5D94B6dA25A95067e0647bc8F6597823ea09162e";
const _feePercent=250;

async function main() {

  // Deploy ERC721NFTMarket
  const ERC721NFTMarket = await hre.ethers.getContractFactory("ERC721NFTMarket");
  const erc721NFTMarket = await ERC721NFTMarket.deploy(_weth, _feeRecipient, _feePercent);
  await erc721NFTMarket.deployed();
  console.log("************ ERC721NFTMarket deployed to:", erc721NFTMarket.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
