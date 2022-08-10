
// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import './libraries/Ownable.sol';
import './libraries/SafeMath.sol';
import './interfaces/IPriceOracleGetter.sol';
import './interfaces/INetworkFeeController.sol';
import './interfaces/IERC20.sol';
import './interfaces/IAggregator.sol';

contract NetworkFeeController is INetworkFeeController, Ownable {
    using SafeMath for uint;

    struct NetworkFee {
        uint256 gasUsed;
        uint256 fee;
        address callback;
    }

    mapping(bytes4 => NetworkFee) public methodNetworkFees;

    address public networkFeeVault;
    address public priceOracleGetter;
    address public maticEthAggregator;

    constructor(address _priceOracleGetter, address _networkFeeVault,address _maticEthAggregator)  public{
        priceOracleGetter = _priceOracleGetter;
        networkFeeVault = _networkFeeVault;
        maticEthAggregator =_maticEthAggregator;
    }

    function setNetworkFeeVault(address _networkFeeVault) public onlyOwner {
        networkFeeVault = _networkFeeVault;
    }

    function setMethodNetworkFees(bytes4 method, NetworkFee memory _networkFee) public onlyOwner {
        require(_networkFee.fee <= 300, "unknow token");
        methodNetworkFees[method] = _networkFee;
    }

    function getNetworkFee(address sender, bytes4 method, address asset, uint256 amount) external override view returns (uint256,address) {
        NetworkFee memory methodNetworkFee = methodNetworkFees[method];
        if (methodNetworkFee.fee == 0) {
            return (0, networkFeeVault);
        }
        if (methodNetworkFee.callback != address(0)) {
            return INetworkFeeController(methodNetworkFee.callback).getNetworkFee(sender, method, asset, amount);
        }
        uint256 need_gas = methodNetworkFee.gasUsed.mul(tx.gasprice).mul(methodNetworkFee.fee).div(100);// Matic/token, token/Matic
        uint256 matic_eth_price = IAggregator(maticEthAggregator).latestAnswer();
        uint256 price = IPriceOracleGetter(priceOracleGetter).getAssetPrice(asset);
        return (need_gas.mul(matic_eth_price).div(price).div(10**(18-IERC20(asset).decimals())), networkFeeVault);
    }

}