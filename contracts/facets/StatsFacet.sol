// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibDex.sol";

contract StatsFacet {
    modifier onlyDiamond() {
        require(msg.sender == address(this), "Must be called by the Diamond");
        _;
    }

    function getPrice() external view returns (uint256) {
        return LibDex.dexStorage().lastPrice;
    }

    function getReserves() external view returns (uint256 reserveToken, uint256 reserveUSDC) {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        return (ds_.tokenReserve, ds_.usdcReserve);
    }
    
    function getTotalVolume() external view returns (uint256) {
        return LibDex.dexStorage().totalVolumeUSDC;
    }

    function _update(uint256 usdcVolume) external onlyDiamond {
        LibDex.DexStorage storage ds_ = LibDex.dexStorage();
        
        ds_.tokenReserve = ds_.tokenBalances[address(this)];
        ds_.usdcReserve = ds_.usdcToken.balanceOf(address(this));

        if (ds_.tokenReserve > 0) {
            ds_.lastPrice = (ds_.usdcReserve * 1e6) / ds_.tokenReserve;
        }

        if (usdcVolume > 0) {
            ds_.totalVolumeUSDC += usdcVolume;
        }
    }
}
