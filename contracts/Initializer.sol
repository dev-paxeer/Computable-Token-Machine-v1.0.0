// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./libraries/LibDex.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Initializer {
    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _initialTokenSupply,
        address _usdcAddress,
        address _initialOwner
    ) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        require(!ds_.initialized, "Already initialized");
        
        // Setup Tradable Token
        ds_.tokenName = _tokenName;
        ds_.tokenSymbol = _tokenSymbol;
        uint256 initialTokens = _initialTokenSupply * (10**6);
        ds_.tokenTotalSupply = initialTokens;
        ds_.tokenBalances[_initialOwner] = initialTokens;
        emit IERC20.Transfer(address(0), _initialOwner, initialTokens);
        
        // Setup LP Token
        ds_.lpTokenName = string.concat(_tokenName, " LP");
        ds_.lpTokenSymbol = string.concat(_tokenSymbol, "-LP");

        // Setup Pool
        ds_.usdcToken = IERC20(_usdcAddress);
        ds_.initialized = true;
    }
}
