// File: contracts/facets/PoolFacet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/LibDex.sol";

contract PoolFacet {

    // --- Events ---
    event Swap(address indexed user, uint amountIn, uint amountOut, address indexed tokenIn);
    event LiquidityAdded(address indexed user, uint lpMinted, uint usdcAmount);
    event LiquidityRemoved(address indexed user, uint lpBurned, uint pxlAmount, uint usdcAmount);

    // --- Internal Mint/Burn Functions ---

    function _mintPXL(address _to, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        ds_.tokenTotalSupply += _amount;
        ds_.tokenBalances[_to] += _amount;
        emit IERC20.Transfer(address(0), _to, _amount);
    }
    
    function _burnPXL(address _from, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 fromBalance = ds_.tokenBalances[_from];
        require(fromBalance >= _amount, "PXL: burn amount exceeds balance");
        ds_.tokenBalances[_from] = fromBalance - _amount;
        ds_.tokenTotalSupply -= _amount;
        emit IERC20.Transfer(_from, address(0), _amount);
    }

    function _mintLP(address _to, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        ds_.lpTotalSupply += _amount;
        ds_.lpBalances[_to] += _amount;
    }
    
    function _burnLP(address _from, uint256 _amount) internal {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint256 fromBalance = ds_.lpBalances[_from];
        require(fromBalance >= _amount, "LP: burn amount exceeds balance");
        ds_.lpBalances[_from] = fromBalance - _amount;
        ds_.lpTotalSupply -= _amount;
    }

    // --- View Functions ---

    function getReserves() public view returns (uint reservePXL, uint reserveUSDC) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        reservePXL = ds_.tokenBalances[address(this)];
        if (address(ds_.usdcToken) != address(0)) {
            reserveUSDC = ds_.usdcToken.balanceOf(address(this));
        }
    }
    
    function getPXLPrice() external view returns (uint price) {
        (uint reservePXL, uint reserveUSDC) = getReserves();
        if (reservePXL == 0 || reserveUSDC == 0) return 0;
        // Price = (USDC / PXL), adjusted for decimals (18 for PXL, 6 for USDC)
        return (reserveUSDC * 1e18) / (reservePXL / 1e12);
    }
    
    function lpBalanceOf(address account) external view returns (uint256) {
        return LibDex.dexStorage().lpBalances[account];
    }

    // --- Liquidity & Swapping Functions ---

    function addLiquidity(uint usdcAmount) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        uint lpToMint;
        if (ds_.lpTotalSupply == 0) {
            // First liquidity provider
            uint initialPXLReserve = ds_.tokenBalances[address(this)];
            lpToMint = initialPXLReserve; // Mint LP shares 1:1 with initial PXL
        } else {
            (uint reservePXL, uint reserveUSDC) = getReserves();
            uint pxlAmount = (usdcAmount * reservePXL) / reserveUSDC;
            require(pxlAmount > 0, "Insufficient amount");
            // Mint PXL from treasury to match the USDC deposit
            _mintPXL(address(this), pxlAmount); 
            lpToMint = (usdcAmount * ds_.lpTotalSupply) / reserveUSDC;
        }
        
        require(lpToMint > 0, "Must mint LP shares");
        _mintLP(msg.sender, lpToMint);
        require(ds_.usdcToken.transferFrom(msg.sender, address(this), usdcAmount), "USDC transfer failed");
        emit LiquidityAdded(msg.sender, lpToMint, usdcAmount);
    }

    function removeLiquidity(uint lpAmount) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        (uint reservePXL, uint reserveUSDC) = getReserves();
        
        uint pxlToSend = (lpAmount * reservePXL) / ds_.lpTotalSupply;
        uint usdcToSend = (lpAmount * reserveUSDC) / ds_.lpTotalSupply;
        
        _burnLP(msg.sender, lpAmount);
        _burnPXL(address(this), pxlToSend); // Burn the PXL from the pool
        
        require(ds_.usdcToken.transfer(msg.sender, usdcToSend), "USDC transfer failed");
        emit LiquidityRemoved(msg.sender, lpAmount, pxlToSend, usdcToSend);
    }

    function swap(uint amountIn, address tokenIn) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        (uint reservePXL, uint reserveUSDC) = getReserves();
        uint amountOut;
        
        if (tokenIn == address(ds_.usdcToken)) { // USDC -> PXL
            require(ds_.usdcToken.transferFrom(msg.sender, address(this), amountIn), "USDC transfer failed");
            uint amountInWithFee = amountIn * 997; // 0.3% fee
            amountOut = (amountInWithFee * reservePXL) / ((reserveUSDC * 1000) + amountInWithFee);
            _burnPXL(address(this), amountOut); // Burn from pool, send to user
            ds_.tokenBalances[msg.sender] += amountOut; 
        } else { // PXL -> USDC
            ds_.tokenBalances[msg.sender] -= amountIn;
            _mintPXL(address(this), amountIn); // User sends to pool
            uint amountInWithFee = amountIn * 997;
            amountOut = (amountInWithFee * reserveUSDC) / ((reservePXL * 1000) + amountInWithFee);
            require(ds_.usdcToken.transfer(msg.sender, amountOut), "USDC transfer failed");
        }
        emit Swap(msg.sender, amountIn, amountOut, tokenIn);
    }

    // --- Initializer ---
    function init(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _initialTokenSupply,
        address _usdcAddress
    ) external {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        require(!ds_.initialized, "Already initialized");
        
        ds_.tokenName = _tokenName;
        ds_.tokenSymbol = _tokenSymbol;
        ds_.usdcToken = IERC20(_usdcAddress);
        
        // Mint the initial supply of PXL tokens to the contract itself to seed the pool
        _mintPXL(address(this), _initialTokenSupply);
        
        ds_.initialized = true;
    }
}