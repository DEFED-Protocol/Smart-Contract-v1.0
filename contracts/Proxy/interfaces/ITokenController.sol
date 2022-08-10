// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface ITokenController {  
   function getParams() external view returns (address,address,address,address);
}