// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMockup is ERC721("NFTMockup", "Mock") {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    function mint(address receiver) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        return newItemId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://be.sipher.xyz/api/sipher/v1.0/sc/tokenuri/";
    }
}