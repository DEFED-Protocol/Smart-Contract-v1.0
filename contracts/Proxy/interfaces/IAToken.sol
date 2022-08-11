// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    
}