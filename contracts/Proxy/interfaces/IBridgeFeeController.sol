// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IBridgeFeeController {
    function getBridgeFee(address asset, uint256 amount)
        external
        view
        returns (uint256, address);
}
