// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;


import './libraries/Ownable.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPriceOracleGetter.sol';
import './interfaces/IBridgeFeeController.sol';

contract BridgeFeeController is IBridgeFeeController, Ownable {
    using SafeMath for uint;

    address public bridgeFeeVault;
    address public priceOracleGetter;
    uint256 public fee;

    constructor(address _priceOracleGetter, address _bridgeFeeVault)  {
        priceOracleGetter = _priceOracleGetter;
        bridgeFeeVault = _bridgeFeeVault;
    }

    function setBridgeFeeVault(address _bridgeFeeVault) public onlyOwner {
        bridgeFeeVault = _bridgeFeeVault;
    }

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 100, "_fee  > 100%");
        fee = _fee;
    }

    function getBridgeFee(address asset, uint256 amount) external override view returns (uint256,address) {
        if (fee == 0) {
            return (0, bridgeFeeVault);
        }
        uint256 fee_amount = amount.mul(fee).div(100);// ETH/token, token/ETH
        uint256 price = IPriceOracleGetter(priceOracleGetter).getAssetPrice(asset);
        uint256 ethUnit = 1*10**18;
        if (ethUnit.mul(25).div(100).mul(10**IERC20(asset).decimals()).div(price) < fee_amount){//>0.25e
            return (ethUnit.mul(25).div(100).mul(10**IERC20(asset).decimals()).div(price), bridgeFeeVault);
        } else if (ethUnit.div(100).mul(10**IERC20(asset).decimals()).div(price) > fee_amount){//<0.01e
            return (ethUnit.div(100).mul(10**IERC20(asset).decimals()).div(price), bridgeFeeVault);
        } else {
            return (fee_amount, bridgeFeeVault);
        }
    }

}