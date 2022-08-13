// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IVTokenFactory {
    event VTokenCreated(address indexed token, address vToken);

    function bridgeControl() external view returns (address);

    function getVToken(address token) external view returns (address vToken);

    function createVToken(
        address token,
        address PToken,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) external returns (address vToken);

    function setBridgeControl(address _bridgeControl) external;
}
