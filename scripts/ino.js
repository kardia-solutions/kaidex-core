// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000"; // KAI
const _tier = "0x104D8e975600a4c7C93faD7850F6927964B0aa94";
const _snapshotForm = 1;
const _snapshotTo = 3
const _startTime = "1663837200";
const _endTime = "1663844400";
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
  const erc721MinterAdapter = await ERC721MinterAdapter.deploy(nftMockup.address, _tier, _snapshotForm, _snapshotTo, { gasLimit: 30000000 })
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

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

  // FundRaising deployed to: 0xB8b177170deC5ecC647E87F37206f03321C5303d