// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/nft-marketplace/INO/interfaces/IMinterAdapter.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinterAdapter {
    function isMinter() external view returns (bool);    
    function mint(address receiver) external returns(uint256);
    function maximumTicketByUser (address userAddr) external view returns(uint256);
    function maximumNFTSales () external view returns (uint256);
    function getSnapshotFrom() external view returns(uint256);
    function getSnapshotTo() external view returns(uint256);
    function getAllocationByTier(uint256 _tier) external view returns(uint256);
    function isValidTierTime (address _user) external view returns (bool);
    function getBuySchedulesBuyTier(uint256 _tier) external view returns(uint256);
    function getTier (address userAddr) external view returns(uint256);
}


// File @openzeppelin/contracts/utils/Context.sol@v4.7.3

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


// File @openzeppelin/contracts/access/Ownable.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.7.3

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/nft-marketplace/INO/interfaces/IMinter.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IMinter {  
    function mint(address receiver) external returns (uint256);
}


// File contracts/interfaces/ITierSystem.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ITierSystem {
    function getTierFromTo (address _account, uint256 _snapshotIdFrom, uint256 _snapshotIdTo) external view returns(uint256);
    function getTier (address _account) external view returns(uint256);
    function getAllocationPoint(uint256 _tier) external view returns(uint256);
}


// File contracts/nft-marketplace/INO/ERC721MinterAdapter.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;





contract ERC721MinterAdapter is IMinterAdapter, Ownable {

    address public inoContract;
    IMinter public erc721NFTContract;
    uint256 public constant MAX_NFT_SALES = 1000;

    // Tier system
    ITierSystem public tierSystem;

    // snapshot ids
    uint256 snapshotFrom;
    uint256 snapshotTo;

    // Total NFT minted
    uint256 public minted;

    // Tier allocation
    uint256[5] public tierAllocations = [1,2,4,8,15];
    uint256[5] public tierBuySchedules; // Tier 1,2,3,4,5

    constructor(
        address nft,
        ITierSystem _tierSystem,
        uint256 _snapshotFrom,
        uint256 _snapshotTo,
        uint256[5] memory _tierBuySchedules
    ){
        require(nft != address(0), "address is invalid");
        erc721NFTContract = IMinter(nft);
        snapshotFrom = _snapshotFrom;
        snapshotTo = _snapshotTo;
        tierSystem = _tierSystem;
        require(_verifySchedules(_tierBuySchedules), "schedules were invalid");
        tierBuySchedules = _tierBuySchedules;
    }

    function _verifySchedules (uint256[5] memory _tierBuySchedules) private view returns (bool) {
        if (_tierBuySchedules.length != 5) return false;
        for(uint256 index = 0; index < _tierBuySchedules.length; ++index) {
            if (index == 0 && _tierBuySchedules[index] <= 0) return false;
            if (index > 0 && _tierBuySchedules[index] > _tierBuySchedules[index - 1]) return false;
            if (_tierBuySchedules[index] < block.timestamp) return false;
        }
        return true;
    }

    modifier onlyINO {
        require(msg.sender == inoContract, "Only call by ino contract");
        _;
    }

    function setSnapshotFrom (uint256 id) public onlyOwner {
        require(id > 0, 'Id invalid');
        snapshotFrom = id;
    }

    function setSnapshotTo (uint256 id) public onlyOwner {
        require(id > 0, 'Id invalid');
        snapshotTo = id;
    }

    function setINOContract (address _ino) public onlyOwner {
        require(_ino != address(0), "address is invalid");
        inoContract = _ino;
    }

    function isValidTierTime (address _user) external view override returns (bool) {
        uint256 tier = tierSystem.getTierFromTo(_user, snapshotFrom, snapshotTo);
        if (tier == 0) return false;
        if (tierBuySchedules[tier - 1] < block.timestamp) return true;
        return false;
    }


    function isMinter() external pure override returns (bool) {
        return true;
    }

    function mint(address receiver) external override onlyINO returns(uint256)  {
        require(minted < MAX_NFT_SALES, "maximum!!");
        uint256 tokenId = erc721NFTContract.mint(receiver);
        minted ++;
        return tokenId;
    }

    // maximum nft amount user can mint
    function maximumTicketByUser (address userAddr) external view override returns(uint256) {
        uint256 tier = tierSystem.getTierFromTo(userAddr, snapshotFrom, snapshotTo);
        if (tier == 0) return 0;
        return tierAllocations[tier-1];
    }

    // Maximum NFT sales
    function maximumNFTSales () external view override returns (uint256) {
        return MAX_NFT_SALES;
    }


    function getSnapshotFrom() external view override returns(uint256) {
        return snapshotFrom;
    }

    function getSnapshotTo() external view override returns(uint256) {
        return snapshotTo;
    }

    function getAllocationByTier(uint256 _tier) external view override returns(uint256) {
        require(_tier > 0 && _tier <= 5, "Tier was invalid");
        return tierAllocations[_tier - 1];
    }

    function getBuySchedulesBuyTier(uint256 _tier) external view override returns(uint256) {
        require(_tier > 0 && _tier <= 5, "Tier was invalid");
        return tierBuySchedules[_tier - 1];
    }

    // get tier system
    function getTier (address userAddr) external view override returns(uint256) {
        return tierSystem.getTierFromTo(userAddr, snapshotFrom, snapshotTo);
    }
}
