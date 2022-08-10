
// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

import './interfaces/IUserProxy.sol';
import './libraries/ECDSA.sol';
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract UserProxy is IUserProxy {
    mapping(uint256 => bool) public nonces;

    // keccak256("ExecTransaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
    bytes32 internal constant EXEC_TX_TYPEHASH = 0xa609e999e2804ed92314c0c662cfdb3c1d8107df2fb6f2e4039093f20d5e6250;
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    // bytes32(uint256(keccak256('eip1967.proxy.domain')) - 1)
    bytes32 internal constant DOMAIN_SLOT = 0x5d29634e15c15fa29be556decae8ee5a34c9fee5f209623aed08a64bf865b694;

    function initialize(address _owner, bytes32 _DOMAIN_SEPARATOR) external override {
        require(owner() == address(0), 'initialize error');
        require(_owner != address(0), "ERC1967: new owner is the zero address");
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _owner;
        StorageSlot.getBytes32Slot(DOMAIN_SLOT).value = _DOMAIN_SEPARATOR;
    }

    function owner() public override view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function domain() public view returns (bytes32) {
        return StorageSlot.getBytes32Slot(DOMAIN_SLOT).value;
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation, uint256 nonce, bytes memory signature) external override {
        require(!nonces[nonce],"nonce had used");
        nonces[nonce] = true;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                domain(),
                keccak256(abi.encode(EXEC_TX_TYPEHASH, to, value, keccak256(data), operation, nonce))
            )
        );
        address recoveredAddress = ECDSA.recover(digest, signature);
        require(recoveredAddress != address(0) && recoveredAddress == owner(), "ECDSA: invalid signature");
        execute(to, value, data, operation);
    }

    function execTransaction(address to, uint256 value, bytes calldata data, Operation operation) external override  {
        require(msg.sender == owner(), "ECDSA: invalid signature");
        execute(to, value, data, operation);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) internal {
        if (operation == Operation.DelegateCall) {
            assembly {
                let result := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        } else {
            assembly {
                let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        }
    }

}
