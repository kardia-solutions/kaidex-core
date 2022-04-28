const { ethers } = require("hardhat");


async function advanceBlock() {
  return ethers.provider.send("evm_mine", [])
}

async function advanceBlockTo(blockNumber) {
  for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
    await advanceBlock()
  }
}

module.exports = {
    advanceBlockTo
}