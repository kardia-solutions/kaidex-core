// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Byte {
    function bytesToBytes4(bytes memory inBytes)
        internal
        pure
        returns (bytes4 outBytes4)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }
        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }
}
