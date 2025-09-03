// File: contracts/AMMFacet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/LibERC20.sol"; // Using the new shared storage library

/**
 * @title AMMFacet
 * @author Paxeer-Foundation
 * @notice Implements a self-contained AMM for the CTM Diamond.
 * This facet handles all swapping and liquidity provision logic.
 */
contract AMMFacet {

    struct AMMStorage {
        IERC20 usdcToken;
        bool initialized;
    }

    bytes32 constant AMM_STORAGE_POSITION = keccak256("ctm.program.storage.amm.usd.v2");

    function ammStorage() internal pure returns (AMMStorage storage as_) {
        bytes32 position = AMM_STORAGE_POSITION;
        assembly { as_.slot := position }
    }

    // --- Events ---
    event Swap(address indexed sender, uint amountIn, uint amountOut, address indexed tokenIn);
    event LiquidityAdded(address indexed provider, uint amountNative, uint amountUSDC, uint liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint amountNative, uint amountUSDC, uint liquidityBurned);

    // --- Internal Mint & Burn ---
    // This logic now lives securely inside the only facet that needs it.
    function _mint(address _to, uint256 _amount) internal {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        require(_to != address(0), "ERC20: mint to zero address");
        es_.totalSupply += _amount;
        es_.balances[_to] += _amount;
        emit IERC20.Transfer(address(0), _to, _amount);
    }

    function _burn(address _from, uint256 _amount) internal {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        uint256 fromBalance = es_.balances[_from];
        require(fromBalance >= _amount, "ERC20: burn amount exceeds balance");
        es_.balances[_from] = fromBalance - _amount;
        es_.totalSupply -= _amount;
        emit IERC20.Transfer(_from, address(0), _amount);
    }
    
    // --- VIEW FUNCTIONS ---

    function getReserves() public view returns (uint reserveNative, uint reserveUSDC) {
        AMMStorage storage as_ = ammStorage();
        reserveNative = address(this).balance;
        if (address(as_.usdcToken) != address(0)) {
            reserveUSDC = as_.usdcToken.balanceOf(address(this));
        }
    }

    function getUSDPrice() external view returns (uint price) {
        (uint reserveNative, uint reserveUSDC) = getReserves();
        if (reserveNative == 0 || reserveUSDC == 0) return 0;
        // Normalize USDC's 6 decimals to 18 for a consistent price format
        return (reserveUSDC * 1e18 * 1e12) / reserveNative;
    }
    
    // --- MUTATIVE FUNCTIONS ---

    function addLiquidity(uint amountUSDCDesired) external payable {
        AMMStorage storage as_ = ammStorage();
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        uint amountNative = msg.value;
        uint amountUSDC;
        
        if (es_.totalSupply == 0) {
            // Initial liquidity deposit
            amountUSDC = amountUSDCDesired;
            uint liquidity = amountNative;
            require(liquidity > 0, "Initial liquidity must be > 0");
            _mint(msg.sender, liquidity);
            
            require(as_.usdcToken.transferFrom(msg.sender, address(this), amountUSDC), "USDC transfer failed");
            emit LiquidityAdded(msg.sender, amountNative, amountUSDC, liquidity);
        } else {
            // Adding to an existing pool
            (uint reserveNative, uint reserveUSDC) = getReserves();
            uint reserveNativeForCalc = reserveNative - amountNative;
            
            uint requiredUSDC = (amountNative * reserveUSDC) / reserveNativeForCalc;
            require(amountUSDCDesired >= requiredUSDC, "Insufficient USDC amount");
            amountUSDC = requiredUSDC;
            
            require(as_.usdcToken.transferFrom(msg.sender, address(this), amountUSDC), "USDC transfer failed");

            uint liquidity = (amountNative * es_.totalSupply) / reserveNativeForCalc;
            _mint(msg.sender, liquidity);
            emit LiquidityAdded(msg.sender, amountNative, amountUSDC, liquidity);
        }
    }

    function removeLiquidity(uint liquidity) external {
        LibERC20.ERC20Storage storage es_ = LibERC20.erc20Storage();
        uint totalSupply = es_.totalSupply;
        require(liquidity > 0 && liquidity <= totalSupply, "Invalid liquidity amount");
        
        (uint reserveNative, uint reserveUSDC) = getReserves();

        uint amountNative = (liquidity * reserveNative) / totalSupply;
        uint amountUSDC = (liquidity * reserveUSDC) / totalSupply;

        _burn(msg.sender, liquidity);
        
        payable(msg.sender).transfer(amountNative);
        ammStorage().usdcToken.transfer(msg.sender, amountUSDC);
        
        emit LiquidityRemoved(msg.sender, amountNative, amountUSDC, liquidity);
    }

    function swap(uint amountIn, address tokenIn) external payable {
        AMMStorage storage as_ = ammStorage();
        (uint reserveNative, uint reserveUSDC) = getReserves();
        
        uint amountOut;
        if (tokenIn == address(as_.usdcToken)) {
            require(amountIn > 0, "Amount in must be positive");
            require(as_.usdcToken.transferFrom(msg.sender, address(this), amountIn), "USDC transfer failed");
            uint amountInWithFee = amountIn * 997;
            amountOut = (reserveNative * amountInWithFee) / ((reserveUSDC * 1000) + amountInWithFee);
            payable(msg.sender).transfer(amountOut);
        } else {
            require(msg.value > 0, "Must send native asset for this swap");
            uint amountInWithFee = msg.value * 997;
            amountOut = (reserveUSDC * amountInWithFee) / ((reserveNative * 1000) + amountInWithFee);
            require(as_.usdcToken.transfer(msg.sender, amountOut), "USDC transfer failed");
            amountIn = msg.value;
        }
        emit Swap(msg.sender, amountIn, amountOut, tokenIn);
    }
    
    // --- INITIALIZER ---
    function init(address _usdcToken) external {
        AMMStorage storage as_ = ammStorage();
        require(!as_.initialized, "Already initialized");
        as_.usdcToken = IERC20(_usdcToken);
        as_.initialized = true;
    }
}