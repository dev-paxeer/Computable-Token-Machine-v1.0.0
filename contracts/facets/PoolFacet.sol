// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDex.sol";
import "./StatsFacet.sol";
import "./TokenFacet.sol";

contract PoolFacet {
    event LiquidityAdded(address indexed user, uint256 lpMinted, uint256 tokenAmount, uint256 usdcAmount);
    event LiquidityRemoved(address indexed user, uint256 lpBurned, uint256 tokenAmount, uint256 usdcAmount);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, address indexed tokenIn);

    function _mintLP(address _to, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        ds_.lpTotalSupply += _amount;
        ds_.lpBalances[_to] += _amount;
        emit IERC20.Transfer(address(0), _to, _amount);
    }
    function _burnLP(address _from, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 fromBalance = ds_.lpBalances[_from];
        require(fromBalance >= _amount, "LP: burn amount exceeds balance");
        ds_.lpBalances[_from] = fromBalance - _amount;
        ds_.lpTotalSupply -= _amount;
        emit IERC20.Transfer(_from, address(0), _amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdcAmount) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        
        TokenFacet(address(this)).transferFrom(msg.sender, address(this), tokenAmount);
        ds_.usdcToken.transferFrom(msg.sender, address(this), usdcAmount);
        
        (uint256 reserveTokenBefore, uint256 reserveUSDCBefore) = StatsFacet(address(this)).getReserves();
        
        uint256 lpToMint;
        if (ds_.lpTotalSupply == 0) {
            lpToMint = 1_000_000 * (10**6); // Seed with 1M LP shares
        } else {
            uint256 lpFromToken = (tokenAmount * ds_.lpTotalSupply) / reserveTokenBefore;
            uint256 lpFromUSDC = (usdcAmount * ds_.lpTotalSupply) / reserveUSDCBefore;
            lpToMint = lpFromToken < lpFromUSDC ? lpFromToken : lpFromUSDC;
        }
        
        require(lpToMint > 0, "Insufficient liquidity minted");
        _mintLP(msg.sender, lpToMint);
        
        StatsFacet(address(this))._update(0);
        emit LiquidityAdded(msg.sender, lpToMint, tokenAmount, usdcAmount);
    }

    function removeLiquidity(uint256 lpAmount) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        (uint256 reserveToken, uint256 reserveUSDC) = StatsFacet(address(this)).getReserves();
        
        uint256 tokenToSend = (lpAmount * reserveToken) / ds_.lpTotalSupply;
        uint256 usdcToSend = (lpAmount * reserveUSDC) / ds_.lpTotalSupply;
        
        _burnLP(msg.sender, lpAmount);
        
        // Use the TokenFacet to transfer the token from the contract to the user
        TokenFacet(address(this)).transfer(msg.sender, tokenToSend);
        require(ds_.usdcToken.transfer(msg.sender, usdcToSend));
        
        StatsFacet(address(this))._update(0);
        emit LiquidityRemoved(msg.sender, lpAmount, tokenToSend, usdcToSend);
    }

    function swap(uint256 amountIn, address tokenIn) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        (uint256 reserveToken, uint256 reserveUSDC) = StatsFacet(address(this)).getReserves();
        uint256 amountOut;
        uint256 usdcVolume;
        
        if (tokenIn == address(ds_.usdcToken)) { // USDC -> Tradable Token
            usdcVolume = amountIn;
            require(ds_.usdcToken.transferFrom(msg.sender, address(this), amountIn));
            uint256 amountInWithFee = amountIn * 997;
            amountOut = (amountInWithFee * reserveToken) / ((reserveUSDC * 1000) + amountInWithFee);
            TokenFacet(address(this)).transfer(msg.sender, amountOut);
        } else { // Tradable Token -> USDC
            TokenFacet(address(this)).transferFrom(msg.sender, address(this), amountIn);
            uint256 amountInWithFee = amountIn * 997;
            amountOut = (amountInWithFee * reserveUSDC) / ((reserveToken * 1000) + amountInWithFee);
            usdcVolume = amountOut;
            require(ds_.usdcToken.transfer(msg.sender, amountOut));
        }

        StatsFacet(address(this))._update(usdcVolume);
        emit Swap(msg.sender, amountIn, amountOut, tokenIn);
    }
}
