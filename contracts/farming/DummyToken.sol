// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyToken is ERC20("MASTERCHEFDUMMY", "DUMMY") {
    constructor() {
        _mint(msg.sender, 1000 * 1e18);
    }
}
