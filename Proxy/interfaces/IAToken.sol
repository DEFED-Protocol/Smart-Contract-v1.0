// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

interface IAToken {
    function RESERVE_TREASURY_ADDRESS() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    
}