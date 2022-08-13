// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IUserProxy {
    enum Operation {
        Call,
        DelegateCall
    }

    function owner() external view returns (address);

    function initialize(address, bytes32) external;

    function execTransaction(
        address,
        uint256,
        bytes calldata,
        Operation,
        uint256 nonce,
        bytes memory
    ) external;

    function execTransaction(
        address,
        uint256,
        bytes calldata,
        Operation
    ) external;
}
