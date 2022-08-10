// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;
interface IBridgeControl {

   function transferToEthereum(address vToken, address to, uint256 amount) external;
   function transferFromEthereumForDeposit(address token, address to, uint256 amount) external;
   function transferFromEthereumForRepay(address token, address to, uint256 amount,uint256 rateMode) external;
   function transferFromEthereum(address token, address to, uint256 amount) external;


}