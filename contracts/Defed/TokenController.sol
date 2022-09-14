// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IUserProxyFactory.sol";
import "./interfaces/IUserProxy.sol";
import "./interfaces/IVTokenFactory.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IBridgeControl.sol";
import "./interfaces/ITokenController.sol";
import "./interfaces/INetworkFeeController.sol";
import "./interfaces/IIncentivesController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenController {
    using SafeERC20 for IERC20;
    struct Params {
        address lendingPool;
        address bridgeControl;
        address vTokenFactory;
        address proxyFactory;
        address networkFeeController;
    }
    mapping(address => Params) public addressParams;

    event BorrowToEthereum(address asset, uint256 value, address toEthAdr);

    event Borrow(address asset, uint256 value, address toEthAdr);

    event Repay(address asset, uint256 value, uint256 rateMode);

    event WithdrawToEthereum(address asset, uint256 value, address toEthAdr);

    event Transfer(address asset, uint256 value, address toEthAdr);

    event TransferToEthereum(address asset, uint256 value, address toEthAdr);

    event TransferCredit(
        address asset,
        uint256 value,
        address toEthAdr,
        uint256 interestRateMode,
        uint16 referralCode
    );

    event TransferCreditToEthereum(
        address asset,
        uint256 value,
        address toEthAdr,
        uint256 interestRateMode,
        uint16 referralCode
    );

    event NetworkFeeLog(
        address fromUserProxy,
        address token,
        uint256 fee,
        uint256 action
    );

    constructor(
        address _lendingPOOL,
        address _bridgeControl,
        address _vTokenFactory,
        address _proxyFactory,
        address _networkFeeController
    ) {
        address tokenController = address(this);
        addressParams[tokenController].lendingPool = _lendingPOOL;
        addressParams[tokenController].bridgeControl = _bridgeControl;
        addressParams[tokenController].vTokenFactory = _vTokenFactory;
        addressParams[tokenController].proxyFactory = _proxyFactory;
        addressParams[tokenController]
            .networkFeeController = _networkFeeController;
    }

    function withdrawToEthereum(
        address tokenController,
        address asset,
        uint256 amount
    ) public {
        bytes4 method = bytes4(
            keccak256("withdrawToEthereum(address,address,uint256)")
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        address ethUser = IUserProxy(address(this)).owner();
        require(vToken != address(0), "unknow token");
        ILendingPool(params.lendingPool).withdraw(
            vToken,
            amount,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 1);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).safeTransfer(params.bridgeControl, targetAmount);
        IBridgeControl(params.bridgeControl).transferToEthereum(
            address(this),
            vToken,
            address(this),
            targetAmount,
            1
        );
        emit WithdrawToEthereum(asset, targetAmount, ethUser);
    }

    function borrowToEthereum(
        address tokenController,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode
    ) public {
        bytes4 method = bytes4(
            keccak256(
                "borrowToEthereum(address,address,uint256,uint256,uint16)"
            )
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
        ILendingPool(params.lendingPool).borrow(
            vToken,
            amount,
            interestRateMode,
            referralCode,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 2);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).safeTransfer(params.bridgeControl, targetAmount);
        IBridgeControl(params.bridgeControl).transferToEthereum(
            address(this),
            vToken,
            address(this),
            targetAmount,
            2
        );
        emit BorrowToEthereum(asset, targetAmount, ethUser);
    }

    function borrow(
        address tokenController,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode
    ) public {
        bytes4 method = bytes4(
            keccak256("borrow(address,address,uint256,uint256,uint16)")
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
        ILendingPool(params.lendingPool).borrow(
            vToken,
            amount,
            interestRateMode,
            referralCode,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 3);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).approve(params.lendingPool, targetAmount);
        ILendingPool(params.lendingPool).deposit(
            vToken,
            targetAmount,
            address(this),
            referralCode
        );
        emit Borrow(asset, targetAmount, ethUser);
    }

    function transfer(
        address tokenController,
        address asset,
        uint256 amount,
        address to
    ) public {
        bytes4 method = bytes4(
            keccak256("transfer(address,address,uint256,address)")
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            ILendingPool(params.lendingPool).withdraw(
                vToken,
                fee,
                networkFeeVault
            );
            emit NetworkFeeLog(address(this), vToken, fee, 4);
        }
        uint256 targetAmount = amount - fee;
        (, , , , , , , address aToken, , , , ) = ILendingPool(
            params.lendingPool
        ).getReserveData(vToken);
        IERC20(aToken).safeTransfer(proxyAddr, targetAmount);
        emit Transfer(asset, targetAmount, to);
    }

    function transferToEthereum(
        address tokenController,
        address asset,
        uint256 amount,
        address to
    ) public {
        bytes4 method = bytes4(
            keccak256("transferToEthereum(address,address,uint256,address)")
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        address ethUser = IUserProxy(address(this)).owner();
        ILendingPool(params.lendingPool).withdraw(
            vToken,
            amount,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 5);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).safeTransfer(params.bridgeControl, targetAmount);
        IBridgeControl(params.bridgeControl).transferToEthereum(
            address(this),
            vToken,
            proxyAddr,
            targetAmount,
            3
        );
        emit TransferToEthereum(asset, targetAmount, to);
    }

    function transferCredit(
        address tokenController,
        address asset,
        uint256 amount,
        address to,
        uint256 interestRateMode,
        uint16 referralCode
    ) public {
        bytes4 method = bytes4(
            keccak256(
                "transferCredit(address,address,uint256,address,uint256,uint16)"
            )
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        ILendingPool(params.lendingPool).borrow(
            vToken,
            amount,
            interestRateMode,
            referralCode,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 6);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).approve(params.lendingPool, targetAmount);
        ILendingPool(params.lendingPool).deposit(
            vToken,
            targetAmount,
            proxyAddr,
            referralCode
        );
        emit TransferCredit(
            asset,
            targetAmount,
            to,
            interestRateMode,
            referralCode
        );
    }

    function transferCreditToEthereum(
        address tokenController,
        address asset,
        uint256 amount,
        address to,
        uint256 interestRateMode,
        uint16 referralCode
    ) public {
        bytes4 method = bytes4(
            keccak256(
                "transferCreditToEthereum(address,address,uint256,address,uint256,uint16)"
            )
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        ILendingPool(params.lendingPool).borrow(
            vToken,
            amount,
            interestRateMode,
            referralCode,
            address(this)
        );
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 7);
        }
        uint256 targetAmount = amount - fee;
        IERC20(vToken).safeTransfer(params.bridgeControl, targetAmount);
        IBridgeControl(params.bridgeControl).transferToEthereum(
            address(this),
            vToken,
            proxyAddr,
            targetAmount,
            4
        );
        emit TransferCreditToEthereum(
            asset,
            targetAmount,
            to,
            interestRateMode,
            referralCode
        );
    }

    function repay(
        address tokenController,
        address asset,
        uint256 amount,
        uint256 rateMode
    ) public {
        bytes4 method = bytes4(
            keccak256("repay(address,address,uint256,uint256)")
        );
        Params memory params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        ILendingPool(params.lendingPool).withdraw(
            vToken,
            amount,
            address(this)
        );
        address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee, address networkFeeVault) = INetworkFeeController(
            params.networkFeeController
        ).getNetworkFee(ethUser, method, vToken, amount);
        if (fee > 0) {
            IERC20(vToken).safeTransfer(networkFeeVault, fee);
            emit NetworkFeeLog(address(this), vToken, fee, 8);
        }
        uint256 targetAmount = amount - fee;
        ILendingPool(params.lendingPool).repay(
            vToken,
            targetAmount,
            rateMode,
            address(this)
        );
        uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
        if (balanceAfterRepay != 0) {
            ILendingPool(params.lendingPool).deposit(
                vToken,
                balanceAfterRepay,
                address(this),
                0
            );
        }
        emit Repay(asset, targetAmount, rateMode);
    }

    function getParams() external view returns (Params memory) {
        return addressParams[address(this)];
    }
}
