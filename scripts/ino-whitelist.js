// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000"; // KAI
const _startTime = "1667188200";
const _endTime = "1667188500";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy

  // Deploy Mockup NFT
  const NFTMockup = await hre.ethers.getContractFactory("NFTMockup");
  const nftMockup = await NFTMockup.deploy()
  await nftMockup.deployed();
  console.log("NFTMockup deployed to:", nftMockup.address);

  // Deploy minter adapter
  const ERC721MinterAdapterWhitelist = await hre.ethers.getContractFactory("ERC721MinterAdapterWhitelist");
  const erc721MinterAdapterWhitelist = await ERC721MinterAdapterWhitelist.deploy(nftMockup.address, { gasLimit: 30000000 })
  await erc721MinterAdapterWhitelist.deployed();
  console.log("ERC721MinterAdapterWhitelist deployed to:", erc721MinterAdapterWhitelist.address);

  // Deploy ERC721 INO
  const ERC721INOWhitelist = await hre.ethers.getContractFactory("ERC721INOWhitelist");
  const erc721INOWhitelist = await ERC721INOWhitelist.deploy(_buyToken, erc721MinterAdapterWhitelist.address, _startTime, _endTime, { gasLimit: 30000000 })
  await erc721INOWhitelist.deployed();
  console.log("ERC721INO deployed to:", erc721INOWhitelist.address);

  // Minter adapter set INO contract
  const tx = await erc721MinterAdapterWhitelist.setINOContract(erc721INOWhitelist.address, { gasLimit: 30000000 })
  console.log("Set INO Contract", tx.hash)

  const INOManager = await hre.ethers.getContractFactory("INOManager");
  const inoManager = await INOManager.attach("0x1A1a98C3D3F08B5C8e3cabaa1684eAC3847fb437");
  const tx1 = await inoManager.addINO(erc721INOWhitelist.address, nftMockup.address, { gasLimit: 30000000 })
  console.log("Set addINO Contract", tx1.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });