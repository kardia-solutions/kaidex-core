// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICodec.sol";
import "./CodecRegistry.sol";
import "./DexRegistry.sol";
import "./libs/Byte.sol";

contract Swapper is CodecRegistry, DexRegistry {
    using SafeERC20 for IERC20;

    constructor(
        string[] memory _funcSigs,
        address[] memory _codecs,
        address[] memory _supportedDexList,
        string[] memory _supportedDexFuncs
    ) DexRegistry(_supportedDexList, _supportedDexFuncs) CodecRegistry(_funcSigs, _codecs) {}

    /**
     * @dev Checks the input swaps for that tokenIn and tokenOut for every swap should be the same
     * @param _swaps the swaps the check
     * @return sumAmtIn the sum of all amountIns in the swaps
     * @return tokenIn the input token of the swaps
     * @return tokenOut the desired output token of the swaps
     * @return codecs a list of codecs which each of them corresponds to a swap
     */
    function sanitizeSwaps(ICodec.SwapDescription[] memory _swaps)
        internal
        view
        returns (
            uint256 sumAmtIn,
            address tokenIn,
            address tokenOut,
            ICodec[] memory codecs // _codecs[i] is for _swaps[i]
        )
    {
        address prevTokenIn;
        address prevTokenOut;
        codecs = loadCodecs(_swaps);

        for (uint256 i = 0; i < _swaps.length; i++) {
            require(dexRegistry[_swaps[i].dex][Byte.bytesToBytes4(_swaps[i].data)], "unsupported dex");
            (uint256 _amountIn, address _tokenIn, address _tokenOut) = codecs[i].decodeCalldata(_swaps[i]);
            require(prevTokenIn == address(0) || prevTokenIn == _tokenIn, "tkin mismatch");
            prevTokenIn = _tokenIn;
            require(prevTokenOut == address(0) || prevTokenOut == _tokenOut, "tko mismatch");
            prevTokenOut = _tokenOut;
            sumAmtIn += _amountIn;
            tokenIn = _tokenIn;
            tokenOut = _tokenOut;
        }
    }

    /**
     * @notice Executes the swaps, decode their return values and sums the returned amount
     * @dev This function is intended to be used on src chain only
     * @dev This function immediately fails (return false) if any swaps fail. There is no "partial fill" on src chain
     * @param _swaps swaps. this function assumes that the swaps are already sanitized
     * @param _codecs the codecs for each swap
     * @return ok whether the operation is successful
     * @return sumAmtOut the sum of all amounts gained from swapping
     */
    function executeSwaps(
        ICodec.SwapDescription[] memory _swaps,
        ICodec[] memory _codecs // _codecs[i] is for _swaps[i]
    ) internal returns (bool ok, uint256 sumAmtOut) {
        for (uint256 i = 0; i < _swaps.length; i++) {
            (uint256 amountIn, address tokenIn, address tokenOut) = _codecs[i].decodeCalldata(_swaps[i]);
            bytes memory data = _codecs[i].encodeCalldataWithOverride(_swaps[i].data, amountIn, address(this));
            IERC20(tokenIn).safeIncreaseAllowance(_swaps[i].dex, amountIn);
            uint256 balBefore = IERC20(tokenOut).balanceOf(address(this));
            (ok, ) = _swaps[i].dex.call(data);
            if (!ok) {
                return (false, 0);
            }
            uint256 balAfter = IERC20(tokenOut).balanceOf(address(this));
            sumAmtOut += balAfter - balBefore;
        }
    }
}