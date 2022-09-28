// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./libs/Types.sol";
import "./interfaces/ICodec.sol";
import "./interfaces/IBridgeAdapter.sol";
import "./interfaces/IWETH.sol";

import "./BridgeRegistry.sol";
import "./Swapper.sol";

contract TransferSwapper is ReentrancyGuard, BridgeRegistry, Swapper {

    using SafeERC20 for IERC20;    
    using ECDSA for bytes32;


    bytes32 public immutable MULTICHAIN_PROVIDER_HASH;
    /// @notice erc20 wrap of the gas token of this chain, e.g. WETH
    address public nativeWrap;

    /**
     * @notice Emitted when requested dstChainId == srcChainId, no bridging
     * @param id see _computeId()
     * @param amountIn the input amount approved by the sender
     * @param tokenIn the input token approved by the sender
     * @param amountOut the output amount gained after swapping using the input tokens
     * @param tokenOut the output token gained after swapping using the input tokens
     */
    event DirectSwap(bytes32 id, uint256 amountIn, address tokenIn, uint256 amountOut, address tokenOut);

    /**
     * @notice Emitted when operations on src chain is done, the transfer is sent through the bridge
     * @param id see _computeId()
     * @param bridgeResp arbitrary response data returned by bridge
     * @param dstChainId destination chain id
     * @param srcAmount input amount approved by the sender
     * @param srcToken the input token approved by the sender
     * @param dstToken the final output token (after bridging and swapping) desired by the sender
     * @param bridgeOutReceiver the receiver (user or dst TransferSwapper) of the bridge token
     * @param bridgeToken the token used for bridging
     * @param bridgeAmount the amount of the bridgeToken to bridge
     * @param bridgeProvider the bridge provider
     */
    event RequestSent(
        bytes32 id,
        bytes bridgeResp,
        uint64 dstChainId,
        uint256 srcAmount,
        address srcToken,
        address dstToken,
        address bridgeOutReceiver,
        address bridgeToken,
        uint256 bridgeAmount,
        string bridgeProvider
    );

    constructor(
        address _nativeWrap,
        string[] memory _funcSigs,
        address[] memory _codecs,
        address[] memory _supportedDexList,
        string[] memory _supportedDexFuncs
    )
        Swapper(_funcSigs, _codecs, _supportedDexList, _supportedDexFuncs)
    {
        nativeWrap = _nativeWrap;
        MULTICHAIN_PROVIDER_HASH = keccak256(bytes("multichain"));
    }

    /**
     * @notice swaps if needed, then transfer the token to another chain along with an instruction on how to swap
     * on that chain
     */
    function transferWithSwap (
        Types.TransferDescription calldata _desc,
        ICodec.SwapDescription[] calldata _srcSwaps,
        ICodec.SwapDescription[] calldata _dstSwaps
    ) external payable nonReentrant {
        // a request needs to incur a swap, a transfer, or both. otherwise it's a nop and we revert early to save gas
        require(_srcSwaps.length != 0 || _desc.dstChainId != uint64(block.chainid), "nop");
        require(_srcSwaps.length != 0 || (_desc.amountIn != 0 && _desc.tokenIn != address(0)), "nop");
        // swapping on the dst chain requires message passing. only integrated with multichain for now
        bytes32 bridgeProviderHash = keccak256(bytes(_desc.bridgeProvider));
        require(
            (_dstSwaps.length == 0) || bridgeProviderHash == MULTICHAIN_PROVIDER_HASH,
            "bridge does not support msg"
        );

        IBridgeAdapter bridge = bridges[bridgeProviderHash];
        // if not DirectSwap, the bridge provider should be a valid one
        require(_desc.dstChainId == uint64(block.chainid) || address(bridge) != address(0), "unsupported bridge");

        uint256 amountIn = _desc.amountIn;
        ICodec[] memory codecs;

        address srcTokenIn = _desc.tokenIn;
        address srcTokenOut = _desc.tokenIn;
        if (_srcSwaps.length != 0) {
            if (isExternalSwap(_srcSwaps[0])) {
                srcTokenOut = _desc.bridgeTokenIn;
            } else {
                (amountIn, srcTokenIn, srcTokenOut, codecs) = sanitizeSwaps(_srcSwaps);
            }
            require(srcTokenIn != srcTokenOut, "token in/out must not equal if exists swaps");
        }
        if (_desc.nativeIn) {
            require(srcTokenIn == nativeWrap, "tkin no nativeWrap");
            require(msg.value >= amountIn, "insfcnt amt"); // insufficient amount
            IWETH(nativeWrap).deposit{value: amountIn}();
        } else {
            IERC20(srcTokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }
        _swapAndSend(srcTokenIn, srcTokenOut, amountIn, _desc, _srcSwaps, _dstSwaps, codecs);
    }

    function _swapAndSend(
        address _srcToken,
        address _bridgeToken,
        uint256 _amountIn,
        Types.TransferDescription memory _desc,
        ICodec.SwapDescription[] memory _srcSwaps,
        ICodec.SwapDescription[] memory _dstSwaps,
        ICodec[] memory _codecs
    ) private {
        // swap if needed
        uint256 amountOut = _amountIn;
        if (_srcSwaps.length != 0) {
            bool ok;
            if (isExternalSwap(_srcSwaps[0])) {
                // for external swaps, it is only possible that there is one element in the array
                (ok, amountOut) = executeExternalSwap(_srcToken, _bridgeToken, _amountIn, _srcSwaps[0]);
            } else {
                (ok, amountOut) = executeSwaps(_srcSwaps, _codecs);
                require(ok, "swap fail");
            }
        }
        bytes32 id = _computeId(_desc.receiver, _desc.nonce);
        // direct send if needed
        if (_desc.dstChainId == uint64(block.chainid)) {
            _sendToken(_bridgeToken, amountOut, _desc.receiver, _desc.nativeOut);
            emit DirectSwap(id, _amountIn, _srcToken, amountOut, _bridgeToken);
            return;
        }
        _transfer(id, _srcToken, _bridgeToken, _desc, _dstSwaps, _amountIn, amountOut);
    }

    function _transfer(
        bytes32 _id,
        address srcTokenIn,
        address srcTokenOut,
        Types.TransferDescription memory _desc,
        ICodec.SwapDescription[] memory _dstSwaps,
        uint256 _amountIn,
        uint256 _amountOut
    ) private {
        // fund is directly to user if there is no swaps needed on the destination chain
        address bridgeOutReceiver = _dstSwaps.length > 0 ? _desc.dstTransferSwapper : _desc.receiver;
        bytes memory bridgeResp;
        {
            IBridgeAdapter bridge = bridges[keccak256(bytes(_desc.bridgeProvider))];
            IERC20(srcTokenOut).safeIncreaseAllowance(address(bridge), _amountOut);
            bytes memory requestMessage = _encodeRequestMessage(_id, _desc, _dstSwaps);
            bridgeResp = bridge.bridge(
                _desc.dstChainId,
                bridgeOutReceiver,
                _amountOut,
                srcTokenOut,
                _desc.bridgeParams,
                requestMessage
            );
        }
        emit RequestSent(
            _id,
            bridgeResp,
            _desc.dstChainId,
            _amountIn,
            srcTokenIn,
            _desc.dstTokenOut,
            bridgeOutReceiver,
            srcTokenOut,
            _amountOut,
            _desc.bridgeProvider
        );
    }

    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut
    ) private {
        if (_nativeOut) {
            require(_token == nativeWrap, "tk no native");
            IWETH(nativeWrap).withdraw(_amount);
            (bool sent, ) = _receiver.call{value: _amount, gas: 50000}("");
            require(sent, "send fail");
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _computeId(address _receiver, uint64 _nonce) private view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, _receiver, uint64(block.chainid), _nonce));
    }
    
    function _encodeRequestMessage(
        bytes32 _id,
        Types.TransferDescription memory _desc,
        ICodec.SwapDescription[] memory _swaps
    ) internal pure returns (bytes memory message) {
        message = abi.encode(
            Types.Request({
                id: _id,
                swaps: _swaps,
                receiver: _desc.receiver,
                nativeOut: _desc.nativeOut,
                allowPartialFill: _desc.allowPartialFill
            })
        );
    }

}