// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/security/ReentrancyGuard.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/Address.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/Strings.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/cryptography/ECDSA.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/crosschain-swap/interfaces/ICodec.sol

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface ICodec {
    struct SwapDescription {
        address dex; // the DEX to use for the swap, zero address implies no swap needed
        bytes data; // the data to call the dex with
    }

    function decodeCalldata(SwapDescription calldata swap)
        external
        view
        returns (
            uint256 amountIn,
            address tokenIn,
            address tokenOut
        );

    function encodeCalldataWithOverride(
        bytes calldata data,
        uint256 amountInOverride,
        address receiverOverride
    ) external pure returns (bytes memory swapCalldata);
}


// File contracts/crosschain-swap/libs/Types.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

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


// File contracts/crosschain-swap/interfaces/IBridgeAdapter.sol

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface IBridgeAdapter {
    function bridge(
        uint64 _dstChainId,
        // the address that the fund is transfered to on the destination chain
        address _receiver,
        uint256 _amount,
        address _token,
        // Bridge transfers quoted and abi encoded by chainhop backend server.
        // Bridge adapter implementations need to decode this themselves.
        bytes memory _bridgeParams,
        // The message to be bridged alongside the transfer.
        // Note if the bridge adapter doesn't support message passing, the call should revert when
        // this field is set.
        bytes memory _requestMessage
    ) external payable returns (bytes memory bridgeResp);
}


// File contracts/crosschain-swap/interfaces/IWETH.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}


// File @openzeppelin/contracts/utils/Context.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/crosschain-swap/BridgeRegistry.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;


/**
 * @title Manages a list of supported bridges
 * @author lionelhoho
 */
abstract contract BridgeRegistry is Ownable {
    event SupportedBridgesUpdated(string[] _bridgeProviders, address[] _bridgeAdapters);

    mapping(bytes32 => IBridgeAdapter) public bridges;

    // to disable a bridge, set the bridge addr of the corresponding provider to address(0)
    function setSupportedBridges(
        string[] calldata _bridgeProviders,
        address[] calldata _bridgeAdapters
    ) external onlyOwner {
        require(_bridgeProviders.length == _bridgeAdapters.length, "params size mismatch");
        for (uint256 i = 0; i < _bridgeProviders.length; i++) {
            bridges[keccak256(bytes(_bridgeProviders[i]))] = IBridgeAdapter(_bridgeAdapters[i]);
        }
        emit SupportedBridgesUpdated(_bridgeProviders, _bridgeAdapters);
    }
}


// File contracts/crosschain-swap/libs/Byte.sol

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


// File contracts/crosschain-swap/CodecRegistry.sol

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;



abstract contract CodecRegistry is Ownable {
    // Initially supported swap functions
    // 0x3df02124 exchange(int128,int128,uint256,uint256)
    // 0xa6417ed6 exchange_underlying(int128,int128,uint256,uint256)
    // 0x44ee1986 exchange_underlying(int128,int128,uint256,uint256,address)
    // 0x38ed1739 swapExactTokensForTokens(uint256,uint256,address[],address,uint256)
    // 0xc04b8d59 exactInput((bytes,address,uint256,uint256,uint256))
    mapping(bytes4 => ICodec) public selector2codec;

    // not used programmatically, but added for contract transparency
    address[] public codecs;

    event CodecUpdated(bytes4 selector, address codec);

    constructor(string[] memory _funcSigs, address[] memory _codecs) {
        require(_funcSigs.length == _codecs.length, "len mm");
        for (uint256 i = 0; i < _funcSigs.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_funcSigs[i])));
            _setCodec(selector, _codecs[i]);
        }
    }

    function setCodec(string calldata _funcSig, address _codec) public onlyOwner {
        bytes4 selector = bytes4(keccak256(bytes(_funcSig)));
        _setCodec(selector, _codec);
        emit CodecUpdated(selector, _codec);
    }

    function _setCodec(bytes4 _selector, address _codec) private {
        selector2codec[_selector] = ICodec(_codec);
        codecs.push(_codec);
    }

    function loadCodecs(ICodec.SwapDescription[] memory _swaps) internal view returns (ICodec[] memory) {
        ICodec[] memory _codecs = new ICodec[](_swaps.length);
        for (uint256 i = 0; i < _swaps.length; i++) {
            bytes4 selector = Byte.bytesToBytes4(_swaps[i].data);
            _codecs[i] = selector2codec[selector];
            require(address(_codecs[i]) != address(0), "cdc no found");
        }
        return (_codecs);
    }

    function getCodec(
        bytes4[] memory _selectors,
        ICodec[] memory _codecs,
        bytes4 _selector
    ) internal pure returns (ICodec) {
        for (uint256 i = 0; i < _codecs.length; i++) {
            if (_selector == _selectors[i]) {
                return _codecs[i];
            }
        }
        revert("cdc no found");
    }

}


// File contracts/crosschain-swap/DexRegistry.sol

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

abstract contract DexRegistry is Ownable {
    event SupportedDexUpdated(address dex, bytes4 selector, bool enabled);

    mapping(address => mapping(bytes4 => bool)) public dexRegistry;

    constructor(address[] memory _supportedDexList, string[] memory _supportedFuncs) {
        for (uint256 i = 0; i < _supportedDexList.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(_supportedFuncs[i])));
            _setSupportedDex(_supportedDexList[i], selector, true);
        }
    }

    function setSupportedDex(
        address _dex,
        string memory _supportedFuncs,
        bool _enabled
    ) external onlyOwner {
        bytes4 selector = bytes4(keccak256(bytes(_supportedFuncs)));
        _setSupportedDex(_dex, selector, _enabled);
        emit SupportedDexUpdated(_dex, selector, _enabled);
    }

    function _setSupportedDex(
        address _dex,
        bytes4 _selector,
        bool _enabled
    ) private {
        bool enabled = dexRegistry[_dex][_selector];
        require(enabled != _enabled, "nop");
        dexRegistry[_dex][_selector] = _enabled;
    }
}


// File contracts/crosschain-swap/Swapper.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;





contract Swapper is CodecRegistry, DexRegistry {
    using SafeERC20 for IERC20;

    // Externally encoded swaps are not encoded by backend, and are differenciated by the target dex address.
    mapping(address => bool) public externalSwap;

    event ExternalSwapUpdated(address dex, bool enabled);

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

    // Checks whether a swap is an "externally encoded swap"
    function isExternalSwap(ICodec.SwapDescription memory _swap) internal view returns (bool ok) {
        require(dexRegistry[_swap.dex][Byte.bytesToBytes4(_swap.data)], "unsupported dex");
        return externalSwap[_swap.dex];
    }

    function setExternalSwap(address _dex, bool _enabled) external onlyOwner {
        _setExternalSwap(_dex, _enabled);
        emit ExternalSwapUpdated(_dex, _enabled);
    }

    function _setExternalSwap(address _dex, bool _enabled) private {
        bool enabled = externalSwap[_dex];
        require(enabled != _enabled, "nop");
        externalSwap[_dex] = _enabled;
    }

    /**
     * @notice Executes the externally encoded swaps
     * @dev This function is intended to be used on src chain only
     * @dev This function immediately fails (return false) if any swaps fail. There is no "partial fill" on src chain
     * @param _swap. this function assumes that the swaps are already sanitized
     * @return ok whether the operation is successful
     * @return amtOut the amount gained from swapping
     */
    function executeExternalSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        ICodec.SwapDescription memory _swap
    ) internal returns (bool ok, uint256 amtOut) {
        IERC20(tokenIn).safeIncreaseAllowance(_swap.dex, amountIn);
        uint256 balBefore = IERC20(tokenOut).balanceOf(address(this));
        (ok, ) = _swap.dex.call(_swap.data);
        if (!ok) {
            return (false, 0);
        }
        uint256 balAfter = IERC20(tokenOut).balanceOf(address(this));
        amtOut = balAfter - balBefore;
    }

}


// File contracts/crosschain-swap/TransferSwapper.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;








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
