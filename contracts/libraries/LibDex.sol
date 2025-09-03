// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibDex {
    // This single struct holds the state for the entire protocol
    struct DexStorage {
        // --- Tradable Token State (PXL) ---
        mapping(address => uint256) tokenBalances;
        mapping(address => mapping(address => uint256)) tokenAllowances;
        uint256 tokenTotalSupply;
        string tokenName;
        string tokenSymbol;

        // --- LP Token State ---
        mapping(address => uint256) lpBalances;
        uint256 lpTotalSupply;
        
        // --- AMM Pool State ---
        IERC20 usdcToken;
        bool initialized;
    }

    bytes32 constant DEX_STORAGE_POSITION = keccak256("paxeer.storage.dex.v1");

    function dexStorage() internal pure returns (DexStorage storage ds_) {
        bytes32 position = DEX_STORAGE_POSITION;
        assembly { ds_.slot := position }
    }
}