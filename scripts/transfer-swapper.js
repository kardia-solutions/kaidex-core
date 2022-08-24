// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");


async function main() {

    // Codecs token deploy
    const Codecs = await hre.ethers.getContractFactory("SwapExactTokensForTokensCodec");
    const codecs = await Codecs.deploy();
    await codecs.deployed();
    console.log("************ Codecs deployed to:", codecs.address);

    // TransferSwapper token deploy
    const _nativeWrap = "0xAF984E23EAA3E7967F3C5E007fbe397D8566D23d";
    const _funcSigs = ["swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"]
    const _codecs = [codecs.address];
    const _supportedDexList = ["0xbAFcdabe65A03825a131298bE7670c0aEC77B37f"]
    const _supportedDexFuncs = ["swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"]
    const TransferSwapper = await hre.ethers.getContractFactory("TransferSwapper");
    const transferSwapper = await TransferSwapper.deploy(
        _nativeWrap,
        _funcSigs,
        _codecs,
        _supportedDexList,
        _supportedDexFuncs
    );
    await transferSwapper.deployed();
    console.log("************ TransferSwapper deployed to:", transferSwapper.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
