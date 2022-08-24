// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "../interfaces/ICodec.sol";
import "../libs/Byte.sol";

contract SwapExactTokensForTokensCodec is ICodec {
    function decodeCalldata(ICodec.SwapDescription calldata _swap)
        external
        pure
        override
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        )
    {
        (uint256 _amountIn, , address[] memory path, , ) = abi.decode(
            (_swap.data[4:]),
            (uint256, uint256, address[], address, uint256)
        );
        return (_amountIn, path[0], path[path.length - 1]);
    }

    function encodeCalldataWithOverride(
        bytes calldata _data,
        uint256 _amountInOverride,
        address _receiverOverride
    ) external pure override returns (bytes memory swapCalldata) {
        bytes4 selector = Byte.bytesToBytes4(_data);
        (, uint256 amountOutMin, address[] memory path, , uint256 ddl) = abi.decode(
            (_data[4:]),
            (uint256, uint256, address[], address, uint256)
        );
        return abi.encodeWithSelector(selector, _amountInOverride, amountOutMin, path, _receiverOverride, ddl);
    }
}
