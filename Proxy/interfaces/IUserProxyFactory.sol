// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

interface IUserProxyFactory {
    event ProxyCreated(address indexed owner, address proxy);
    function getProxy(address owner) external view returns (address proxy);
    function createProxy(address owner) external returns (address proxy);
}