// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./interfaces/IVTokenFactory.sol";
import "./VToken.sol";
import "./libraries/Ownable.sol";

contract VTokenFactory is IVTokenFactory, Ownable {
    mapping(address => address) public override getVToken;
    address public override bridgeControl;

    function createVToken(
        address token,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public override onlyOwner returns (address vToken) {
        require(bridgeControl != address(0), "error");
        require(token != address(0), "ZERO_ADDRESS");
        require(getVToken[token] == address(0), "VTOKEN_EXISTS");
        bytes memory bytecode = creationCode();
        bytes32 salt = keccak256(abi.encodePacked(address(this), token));
        assembly {
            vToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getVToken[token] = vToken;
        VToken(vToken).initialize(token, tokenName, tokenSymbol, tokenDecimals);
        emit VTokenCreated(token, vToken);
    }

    function setBridgeControl(address _bridgeControl)
        public
        override
        onlyOwner
    {
        require(_bridgeControl != address(0));
        bridgeControl = _bridgeControl;
    }

    function runtimeCode() public pure returns (bytes memory) {
        return type(VToken).runtimeCode;
    }

    function creationCode() public pure returns (bytes memory) {
        return type(VToken).creationCode;
    }

    function creationCodeHash() public pure returns (bytes32) {
        return keccak256(creationCode());
    }
}
