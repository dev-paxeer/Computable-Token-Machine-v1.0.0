// File: contracts/facets/TokenFacet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDex.sol";

/**
 * @title TokenFacet
 * @author Paxeer-Foundation
 * @notice Implements the standard ERC20 interface for the tradable PXL token.
 */
contract TokenFacet is IERC20 {

    // --- VIEW FUNCTIONS ---
    
    function name() external view returns (string memory) {
        return LibDex.dexStorage().tokenName;
    }

    function symbol() external view returns (string memory) {
        return LibDex.dexStorage().tokenSymbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return LibDex.dexStorage().tokenTotalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return LibDex.dexStorage().tokenBalances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return LibDex.dexStorage().tokenAllowances[owner][spender];
    }
    
    // --- STATE-CHANGING FUNCTIONS ---

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 senderBalance = ds_.tokenBalances[msg.sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        ds_.tokenBalances[msg.sender] = senderBalance - amount;
        ds_.tokenBalances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        ds_.tokenAllowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 currentAllowance = ds_.tokenAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        uint256 senderBalance = ds_.tokenBalances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        ds_.tokenBalances[sender] = senderBalance - amount;
        ds_.tokenBalances[recipient] += amount;
        ds_.tokenAllowances[sender][msg.sender] = currentAllowance - amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
}