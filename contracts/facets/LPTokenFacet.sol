// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDex.sol";

contract LPTokenFacet {

    function lpName() external view returns (string memory) {
        return LibDex.dexStorage().lpTokenName;
    }

    function lpSymbol() external view returns (string memory) {
        return LibDex.dexStorage().lpTokenSymbol;
    }

    function lpDecimals() external pure returns (uint8) {
        return 6;
    }

    function lpTotalSupply() external view returns (uint256) {
        return LibDex.dexStorage().lpTotalSupply;
    }

    function lpBalanceOf(address account) external view returns (uint256) {
        return LibDex.dexStorage().lpBalances[account];
    }

    function transferLP(address recipient, uint256 amount) external returns (bool) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 senderBalance = ds_.lpBalances[msg.sender];
        require(senderBalance >= amount, "LP: transfer amount exceeds balance");
        
        ds_.lpBalances[msg.sender] = senderBalance - amount;
        ds_.lpBalances[recipient] += amount;
        
        emit IERC20.Transfer(msg.sender, recipient, amount);
        return true;
    }
}
