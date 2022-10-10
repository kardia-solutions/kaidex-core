// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

const _buyToken = "0x0000000000000000000000000000000000000000" // KAI
const _offeringToken = "0x1110A87c7664e819fca35B9B0f6d31f64aC78963";  // WKAI
const _startTime = "1665395700";
const _endTime = "1665399300";
const _harvestTime = "1665399300"
const _offeringAmount = "400000000000000000000";
const _raisingAmount = "1000000000000000000000";
const _maxAllocation = "200000000000000000000";
const addresses = ["0x01B3232Bc2AdfBa8c39Ba4A4002924d62e39aE5d", "0x9d8FC3f09059f1cF04c67bC6bE4aeF68e8F20B0F", "0xF931315EEa67916f98A8aB80Fe347a94AFdD69f4"]
async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');
    // We get the contract to deploy
    const WhitelistRaising = await hre.ethers.getContractFactory("WhitelistRaisingV2");
    const whitelistRaising = await WhitelistRaising.deploy(
        _buyToken,
        _offeringToken,
        _startTime,
        _endTime,
        _harvestTime,
        _offeringAmount,
        _raisingAmount,
        _maxAllocation,
        { gasLimit: 30000000 });
    await whitelistRaising.deployed();
    console.log("FundRaising deployed to:", whitelistRaising.address);
    // Whitelist 
    const {hash} = await whitelistRaising.addAddressesToWhitelist(addresses)
    console.log("Transfer_x", hash)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

