
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IUserProxyFactory.sol';
import './interfaces/IUserProxy.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/IERC20.sol';
import './interfaces/IBridgeControl.sol';
import './interfaces/ITokenController.sol';
import './interfaces/INetworkFeeController.sol';
import './interfaces/IIncentivesController.sol';


contract TokenController {

    struct Params {
    address  lendingPool;
    address  bridgeControl;
    address  vTokenFactory;
    address  proxyFactory;
    address  networkFeeController;
    }
    mapping(address => Params) addressParams;

	event BorrowToEthereum(address asset,uint256 value,address toEthAdr);
    
	event Borrow(address asset,uint256 value,address toEthAdr);

	event Repay(address asset,uint256 value,uint256 rateMode);

	event WithdrawToEthereum(address asset,uint256 value,address toEthAdr);

	event Transfer(address asset,uint256 value,address toEthAdr);

	event TransferToEthereum(address asset,uint256 value,address toEthAdr);

	event TransferCredit(address asset,uint256 value,address toEthAdr,uint256 interestRateMode,uint16 referralCode);

	event TransferCreditToEthereum(address asset,uint256 value,address toEthAdr,uint256 interestRateMode,uint16 referralCode);


    

    constructor(address _lendingPOOL, address _bridgeControl, address _vTokenFactory,address _proxyFactory,address _networkFeeController) {
        address tokenController = address(this);
        addressParams[tokenController].lendingPool = _lendingPOOL;
        addressParams[tokenController].bridgeControl = _bridgeControl;
        addressParams[tokenController].vTokenFactory = _vTokenFactory;
        addressParams[tokenController].proxyFactory = _proxyFactory;
        addressParams[tokenController].networkFeeController = _networkFeeController;
    }
    function withdrawToEthereum(address tokenController,address asset, uint256 amount) public {
        bytes4 method = bytes4(keccak256("withdrawToEthereum(address,address,uint256)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        address ethUser = IUserProxy(address(this)).owner();
        require(vToken != address(0), "unknow token");
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		ILendingPool(params.lendingPool).withdraw(vToken,targetAmount,params.bridgeControl);
		IBridgeControl(params.bridgeControl).transferToEthereum(vToken, address(this), targetAmount);
        emit WithdrawToEthereum(asset, amount, ethUser);

	}

    function borrowToEthereum(address tokenController,address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("borrowToEthereum(address,address,uint256,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
        address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
		ILendingPool(params.lendingPool).borrow(vToken, amount, interestRateMode, referralCode, address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).transfer(params.bridgeControl,targetAmount);
		IBridgeControl(params.bridgeControl).transferToEthereum(vToken, address(this), targetAmount);
        emit BorrowToEthereum(asset, amount, ethUser);
	}

    function borrow(address tokenController,address asset, uint256 amount,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("borrow(address,address,uint256,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).approve(params.lendingPool,targetAmount);
		ILendingPool(params.lendingPool).borrow(vToken,targetAmount,interestRateMode,referralCode,address(this));
		ILendingPool(params.lendingPool).deposit(vToken,targetAmount,address(this),referralCode);
        emit Borrow(asset,amount,ethUser);
	}

    function transfer(address tokenController,address asset, uint256 amount,address to) public {
        bytes4 method = bytes4(keccak256("transfer(address,address,uint256,address)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
       address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            ILendingPool(params.lendingPool).withdraw(vToken,fee,networkFeeVault);
        }
        uint256 targetAmount = amount-fee;
        ( , , , , , , ,address aToken, , , , ) = ILendingPool(params.lendingPool).getReserveData(vToken);
		IERC20(aToken).transfer(proxyAddr,targetAmount);
        emit Transfer(asset, amount, to);
	}
    function transferToEthereum(address tokenController,address asset, uint256 amount,address to) public {
        bytes4 method = bytes4(keccak256("transferToEthereum(address,address,uint256,address)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
        address ethUser = IUserProxy(address(this)).owner();
		ILendingPool(params.lendingPool).withdraw(vToken,amount,params.bridgeControl);
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		IBridgeControl(params.bridgeControl).transferToEthereum(vToken, proxyAddr, targetAmount);
        emit TransferToEthereum(asset, amount, to);
    }
    function transferCredit(address tokenController,address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("transferCredit(address,address,uint256,address,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
		ILendingPool(params.lendingPool).borrow(vToken,amount,interestRateMode,referralCode,address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
        IERC20(vToken).approve(params.lendingPool,targetAmount);
		ILendingPool(params.lendingPool).deposit(vToken,targetAmount,proxyAddr,referralCode);
        emit TransferCredit( asset, amount, to, interestRateMode, referralCode);
	}


    function transferCreditToEthereum(address tokenController,address asset, uint256 amount,address to,uint256 interestRateMode,uint16 referralCode) public {
        bytes4 method = bytes4(keccak256("transferCreditToEthereum(address,address,uint256,address,uint256,uint16)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(params.proxyFactory).getProxy(to);
        address ethUser = IUserProxy(address(this)).owner();
        if(proxyAddr == address(0)){
            proxyAddr = IUserProxyFactory(params.proxyFactory).createProxy(to);
        }
		ILendingPool(params.lendingPool).borrow(vToken,amount,interestRateMode,referralCode,address(this));
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
         if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		IERC20(vToken).transfer(params.bridgeControl,targetAmount);
		IBridgeControl(params.bridgeControl).transferToEthereum(vToken, proxyAddr, targetAmount);
        emit TransferCreditToEthereum( asset, amount,to, interestRateMode, referralCode);
	}

    function repay(address tokenController,address asset, uint256 amount,uint256 rateMode) public {
        bytes4 method = bytes4(keccak256("repay(address,address,uint256,uint256)"));
        Params memory  params = TokenController(tokenController).getParams();
		address vToken = IVTokenFactory(params.vTokenFactory).getVToken(asset);
        require(vToken != address(0), "unknow token");
		ILendingPool(params.lendingPool).withdraw(vToken,amount,address(this));
         address ethUser = IUserProxy(address(this)).owner();
        (uint256 fee,address networkFeeVault) =INetworkFeeController(params.networkFeeController).getNetworkFee(ethUser,method,vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(networkFeeVault,fee);
        }
        uint256 targetAmount = amount-fee;
		ILendingPool(params.lendingPool).repay(vToken, targetAmount,rateMode,address(this));
		uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
		if(balanceAfterRepay != 0){
			ILendingPool(params.lendingPool).deposit(vToken,balanceAfterRepay,address(this),0);
		}
        emit Repay( asset, amount, rateMode);
	}

    function getParams() external view returns (Params memory){
        return addressParams[address(this)];

    }
}