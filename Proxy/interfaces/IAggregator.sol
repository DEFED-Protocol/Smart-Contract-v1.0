// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

interface IAggregator {
    function latestAnswer() external view returns (uint256);
    
}