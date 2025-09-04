// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibDex {
    struct DexStorage {
        // --- Tradable Token State ---
        mapping(address => uint256) tokenBalances;
        mapping(address => mapping(address => uint256)) tokenAllowances;
        uint256 tokenTotalSupply;
        string tokenName;
        string tokenSymbol;

        // --- LP Token State ---
        mapping(address => uint256) lpBalances;
        uint256 lpTotalSupply;
        string lpTokenName;
        string lpTokenSymbol;
        
        // --- AMM Pool & Stats State ---
        IERC20 usdcToken;
        uint256 tokenReserve;
        uint256 usdcReserve;
        uint256 lastPrice; // Stored with 6 decimals of precision
        uint256 totalVolumeUSDC; // Stored with 6 decimals of precision
        bool initialized;
    }

    bytes32 constant DEX_STORAGE_POSITION = keccak256("paxeer.storage.dex.final.v3");

    function dexStorage() internal pure returns (DexStorage storage ds_) {
        bytes32 position = DEX_STORAGE_POSITION;
        assembly {
            ds_.slot := position
        }
    }
}
