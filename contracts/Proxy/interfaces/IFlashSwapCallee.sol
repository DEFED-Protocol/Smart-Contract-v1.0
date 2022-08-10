// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IFlashSwapCallee {
    function flashSwapCall(address sender, uint amount, bytes calldata data) external;
}