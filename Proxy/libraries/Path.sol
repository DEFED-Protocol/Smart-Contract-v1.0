
// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.5.0;

library Path {

    function proxyFor(address factory, address owner, bytes32 hash) public pure returns (address proxy) {
        proxy = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(factory, owner)),
                hash // init code hash
            )))));
    }

    function tokenFor(address factory, address token, bytes32 hash) public pure returns (address vtoken) {
        vtoken = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(factory, token)),
                hash // init code hash
            )))));
    }

    // function proxyFor(address factory, address owner) internal pure returns (address proxy) {
    //     proxy = address(uint256(keccak256(abi.encodePacked(
    //             hex'ff',
    //             factory,
    //             keccak256(abi.encodePacked(factory, owner)),
    //             hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
    //         ))));
    // }
}