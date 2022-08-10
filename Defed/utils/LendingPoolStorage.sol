// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {UserConfiguration} from "../lib/UserConfiguration.sol";
import {ReserveConfiguration} from "../lib/ReserveConfiguration.sol";
import {ReserveLogic} from "../lib/ReserveLogic.sol";
import {ILendingPoolAddressesProvider} from "../interfaces/ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../lib/DataTypes.sol";

contract LendingPoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    ILendingPoolAddressesProvider internal _addressesProvider;

    mapping(address => DataTypes.ReserveData) internal _reserves;
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => address) internal _reservesList;

    uint256 internal _reservesCount;

    bool internal _paused;
}
