// File: contracts/libraries/LibERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LibERC20
 * @author Paxeer-Foundation
 * @notice A library to define the storage layout for a Diamond-compatible ERC20 token.
 * This allows multiple facets to safely access and manage the same ERC20 state.
 */
library LibERC20 {
    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowance;
        uint256 totalSupply;
        string name;
        string symbol;
    }

    // A unique, constant storage slot for the ERC20 state.
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("erc20.storage.paxeer.v2");

    /**
     * @notice Returns a pointer to the ERC20Storage struct.
     */
    function erc20Storage() internal pure returns (ERC20Storage storage es_) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es_.slot := position
        }
    }
}