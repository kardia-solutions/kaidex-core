// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000"; // KAI
const _tier = "0x104D8e975600a4c7C93faD7850F6927964B0aa94";
const _snapshotForm = 1;
const _snapshotTo = 5;
const _startTime = "1666865700";
const _endTime = "1666867200";
const _tierBuySchedules = ["1666866900","1666866600","1666866300","1666866000","1666865700"] //  [tier 1, tier 2, tier 3, tier 4, tier 5]

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
  const ERC721MinterAdapter = await hre.ethers.getContractFactory("ERC721MinterAdapter");
  const erc721MinterAdapter = await ERC721MinterAdapter.deploy(nftMockup.address, _tier, _snapshotForm, _snapshotTo, _tierBuySchedules, { gasLimit: 30000000 })
  await erc721MinterAdapter.deployed();
  console.log("ERC721MinterAdapter deployed to:", erc721MinterAdapter.address);

  // Deploy ERC721 INO
  const ERC721INO = await hre.ethers.getContractFactory("ERC721INO");
  const erc721INO = await ERC721INO.deploy(_buyToken, erc721MinterAdapter.address, _startTime, _endTime, { gasLimit: 30000000 })
  await erc721INO.deployed();
  console.log("ERC721INO deployed to:", erc721INO.address);

  // Minter adapter set INO contract
  const tx = await erc721MinterAdapter.setINOContract(erc721INO.address, { gasLimit: 30000000 })
  console.log("Set INO Contract", tx.hash)

  const INOManager = await hre.ethers.getContractFactory("INOManager");
  const inoManager = await INOManager.attach("0x1A1a98C3D3F08B5C8e3cabaa1684eAC3847fb437");
  const tx1 = await inoManager.addINO(erc721INO.address, nftMockup.address, { gasLimit: 30000000 })
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