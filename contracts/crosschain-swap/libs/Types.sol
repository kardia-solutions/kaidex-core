// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/ICodec.sol";

library Types {

    struct Request {
        bytes32 id; // see _computeId()
        ICodec.SwapDescription[] swaps; // the swaps need to happen on the destination chain
        address receiver; // see TransferDescription.receiver
        bool nativeOut; // see TransferDescription.nativeOut
        // uint256 fee; // see TransferDescription.fee
        bool allowPartialFill; // see TransferDescription.allowPartialFill
    }
    
    struct TransferDescription {
        address receiver; // The receiving party (the user) of the final output token
        uint64 dstChainId; // Destination chain id
        // The address of the TransferSwapper on the destination chain.
        // Ignored if there is no swaps on the destination chain.
        address dstTransferSwapper;
        // A number unique enough to be used in request ID generation.
        uint64 nonce;
        // bridge provider identifier
        string bridgeProvider;
        // Bridge transfers quoted and abi encoded by backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes bridgeParams;
        bool nativeIn; // whether to check msg.value and wrap token before swapping/sending
        bool nativeOut; // whether to unwrap before sending the final token to user
        // uint256 fee; // this fee is only executor fee. it does not include msg bridge fee
        // uint256 feeDeadline; // the unix timestamp before which the fee is valid
         // sig of sha3("executor fee", srcChainId, dstChainId, amountIn, tokenIn, feeDeadline, fee)
        // see _verifyFee()
        // bytes feeSig;
        // IMPORTANT: amountIn & tokenIn is completely ignored if src chain has a swap
        uint256 amountIn;
        address tokenIn;
        // only used if the swap on the src chain is an external swap
        address bridgeTokenIn;
        address dstTokenOut; // the final output token, emitted in event for display purpose only
        // in case of multi route swaps, whether to allow the successful swaps to go through
        // and sending the amountIn of the failed swaps back to user
        bool allowPartialFill;
    }
}