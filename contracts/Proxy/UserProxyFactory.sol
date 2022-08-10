// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

import './interfaces/IUserProxyFactory.sol';
import './UserProxy.sol';

contract UserProxyFactory is IUserProxyFactory {
    mapping(address => address) public override getProxy;

    // // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    
    // keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x91ab3d17e3a50a9d89e63fd30b92be7f5336b03b287bb946787a83a9d62a2766;

    bytes32 public DOMAIN_SEPARATOR;
    string public constant name = 'User Proxy Factory V1';
    string public constant VERSION = "1";

    constructor() {
        // uint chainId;
        // assembly {
        //     chainId := chainid()
        // }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(VERSION)),
                address(this)
            )
        );
    }

    function createProxy(address owner) external override returns (address proxy) {
        require(owner != address(0), 'ZERO_ADDRESS');
        require(getProxy[owner] == address(0), 'PROXY_EXISTS');
        bytes memory bytecode = proxyCreationCode();
        bytes32 salt = keccak256(abi.encodePacked(address(this), owner));
        assembly {
            proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUserProxy(proxy).initialize(owner, DOMAIN_SEPARATOR);
        getProxy[owner] = proxy;
        emit ProxyCreated(owner, proxy);
    }

    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(UserProxy).runtimeCode;
    }

    function proxyCreationCode() public pure returns (bytes memory) {
        return type(UserProxy).creationCode;
    }

    function proxyCreationCodeHash() public pure returns (bytes32) {
        return keccak256(proxyCreationCode());
    }

}