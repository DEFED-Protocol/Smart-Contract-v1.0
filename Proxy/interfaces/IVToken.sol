// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

interface IVToken {
    function ETHToken() external view  returns (address);
    function initialize(address _token, address _PToken,string memory tokenName,string memory tokenSymbol,uint8 tokenDecimals) external;
    function flashSwap(address to, bytes calldata data) external;
}