// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// This facet contains all the standard ERC-20 logic.
// Notice it doesn't have a constructor to set name, symbol, etc.
// All state is stored in the main TokenVM diamond contract.
contract ERC20Facet is IERC20 {
    // We define a storage struct to hold the token's state.
    // This must be stored in a unique slot to avoid collisions.
    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowance;
        uint256 totalSupply;
        string name;
        string symbol;
    }

    // A constant for the storage slot.
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("erc20.storage.paxeer");

    // Helper function to get the ERC20 storage.
    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    // --- ERC20 View Functions ---
    
    function name() external view returns (string memory) {
        return erc20Storage().name;
    }

    function symbol() external view returns (string memory) {
        return erc20Storage().symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return erc20Storage().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return erc20Storage().balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return erc20Storage().allowance[owner][spender];
    }
    
    // --- ERC20 State-Changing Functions ---

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        ERC20Storage storage es = erc20Storage();
        uint256 senderBalance = es.balances[msg.sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        es.balances[msg.sender] = senderBalance - amount;
        es.balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        ERC20Storage storage es = erc20Storage();
        es.allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        ERC20Storage storage es = erc20Storage();
        uint256 currentAllowance = es.allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        uint256 senderBalance = es.balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        es.balances[sender] = senderBalance - amount;
        es.balances[recipient] += amount;
        es.allowance[sender][msg.sender] = currentAllowance - amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    // --- Initialization Function ---
    // This is a special function to set up the initial state of the token.
    function init(string memory _name, string memory _symbol, uint256 _initialSupply) external {
        ERC20Storage storage es = erc20Storage();
        // Ensure it can only be initialized once
        require(bytes(es.name).length == 0, "Already initialized");
        es.name = _name;
        es.symbol = _symbol;
        es.totalSupply = _initialSupply * 10**18;
        es.balances[msg.sender] = es.totalSupply; // Mint to deployer
        emit Transfer(address(0), msg.sender, es.totalSupply);
    }
}