// File: contracts/facets/ERC20Facet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibERC20.sol"; // Using the new shared storage library

/**
 * @title ERC20Facet
 * @author Paxeer-Foundation
 * @notice Implements the standard ERC20 interface for the CTM Diamond.
 * This facet handles all standard token transfers and approvals.
 */
contract ERC20Facet is IERC20 {

    // --- VIEW FUNCTIONS ---
    
    function name() external view returns (string memory) {
        return LibERC20.erc20Storage().name;
    }

    function symbol() external view returns (string memory) {
        return LibERC20.erc20Storage().symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return LibERC20.erc20Storage().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return LibERC20.erc20Storage().balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return LibERC20.erc20Storage().allowance[owner][spender];
    }
    
    // --- STATE-CHANGING FUNCTIONS ---

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        uint256 senderBalance = es_.balances[msg.sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        es_.balances[msg.sender] = senderBalance - amount;
        es_.balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        es_.allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        uint256 currentAllowance = es_.allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        uint256 senderBalance = es_.balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        es_.balances[sender] = senderBalance - amount;
        es_.balances[recipient] += amount;
        es_.allowance[sender][msg.sender] = currentAllowance - amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // --- INITIALIZER ---

    /**
     * @notice Initializes the token's name and symbol. Can only be called once.
     */
    function init(string memory _name, string memory _symbol) external {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        require(bytes(es_.name).length == 0, "ERC20: Already initialized");
        es_.name = _name;
        es_.symbol = _symbol;
    }
}