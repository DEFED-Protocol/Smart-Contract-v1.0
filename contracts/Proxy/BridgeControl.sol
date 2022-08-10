// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IUserProxy.sol';
import './interfaces/IUserProxyFactory.sol';
import './interfaces/IVTokenFactory.sol';
import './interfaces/IVToken.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/IERC20.sol';
import './libraries/Ownable.sol';
import './interfaces/IBridgeFeeController.sol';
import './interfaces/IIncentivesController.sol';

interface IVeDEFE {
    struct LockedBalance {
        int256 amount;
        uint256 end;
    }
    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external;

    function increaseAmountFor(address _beneficiary, uint256 _value) external;
    function getLocked(address _addr) external view returns (LockedBalance memory);
}

contract BridgeControl is Ownable{

    address public proxyFactory;
    address public vTokenFactory;
    address public lendingPool;
    address public virtualDefedToken;
    address public bridgeFeeController;
    address public veDEFE;
    mapping(bytes32=>bool) transactions;

    event TransferToEthereum(address indexed toEthAdr, address indexed toProxyAdr, address token, address vToken, uint256 value);
    event TransferFromEthereum(address indexed fromEthAdr, address indexed fromProxyAdr, address token, address vToken, uint256 value,bytes32 transactionId);
    event TransferFromEthereumForDeposit(address indexed fromEthAdr, address indexed fromProxyAdr, address token, address vToken, uint256 value,bytes32 transactionId);
    event TransferFromEthereumForRepay(address indexed fromEthAdr, address indexed fromProxyAdr, address token, address vToken, uint256 value,bytes32 transactionId);
    event lockFromEthereumLog(address indexed fromEthAdr, address indexed fromProxyAdr, address virtualDefedToken, uint256 value, uint256 time,bytes32 transactionId);
    constructor(address _proxyFactory, address _vTokenFactory,address _lendingPool,address _bridgeFeeController) {
        proxyFactory = _proxyFactory;
        vTokenFactory = _vTokenFactory;
        lendingPool = _lendingPool;
        bridgeFeeController = _bridgeFeeController;
    }

    function setVirtualDefedToken(address _virtualDefedToken,address _veDEFE) external onlyOwner{
        virtualDefedToken = _virtualDefedToken;
        veDEFE = _veDEFE;
    }



	function transferToEthereum(address vToken, address to, uint256 amount) external {
        address ethAddr = IUserProxy(to).owner();
        require(ethAddr != address(0), 'PROXY_EXISTS');
        address token = IVToken(vToken).ETHToken();
        require(token != address(0), "unknow token");
        (uint256 fee,address bridgeFeeVault) = IBridgeFeeController(bridgeFeeController).getBridgeFee(vToken,amount);
        if(fee > 0){
            IERC20(vToken).transfer(bridgeFeeVault,fee);
        }
        uint256 targetAmount = amount - fee;
		IERC20(vToken).burn(address(this), targetAmount);
        emit TransferToEthereum(ethAddr, to, token, vToken, targetAmount);
	}

	function transferFromEthereumForDeposit(bytes32 transactionId,address token, address to, uint256 amount) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(address(this), amount);
        IERC20(vToken).approve(lendingPool,amount);
        ILendingPool(lendingPool).deposit(vToken,amount,proxyAddr,0);
        emit TransferFromEthereumForDeposit(to, proxyAddr, token, vToken, amount,transactionId);
	}

    function transferFromEthereumForRepay(bytes32 transactionId,address token, address to, uint256 amount,uint256 rateMode) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(address(this),amount);
        IERC20(vToken).approve(lendingPool,amount);
        ILendingPool(lendingPool).repay(vToken, amount,rateMode,proxyAddr);
        uint256 balanceAfterRepay = IERC20(vToken).balanceOf(address(this));
        if(balanceAfterRepay > 0){
            ILendingPool(lendingPool).deposit(vToken,balanceAfterRepay,proxyAddr,0);
        }
        emit TransferFromEthereumForRepay(to, proxyAddr, token, vToken, amount,transactionId);
	}
     function transferFromEthereum(bytes32 transactionId,address token, address to, uint256 amount) public onlyOwner {
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address vToken = IVTokenFactory(vTokenFactory).getVToken(token);
        require(vToken != address(0), "unknow token");
        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(to);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(to);
        }
		IERC20(vToken).mint(proxyAddr, amount);
        emit TransferFromEthereum(to, proxyAddr, token, vToken, amount,transactionId);
	}

    function lockFromEthereum(bytes32 transactionId,address user, uint256 amount,uint256 time) public  onlyOwner{
        require(!transactions[transactionId], "transactionId already exec");
        transactions[transactionId] = true;

        address proxyAddr = IUserProxyFactory(proxyFactory).getProxy(user);
        if (proxyAddr == address(0)) {
            proxyAddr = IUserProxyFactory(proxyFactory).createProxy(user);
        }
		lockDefe(proxyAddr,amount,time);
        emit lockFromEthereumLog(user, proxyAddr, virtualDefedToken, amount,time,transactionId);
	}

    function lockDefe(address proxyAddr,uint256 amount,uint256 time) internal{
        IVeDEFE.LockedBalance memory locked = IVeDEFE(veDEFE).getLocked(proxyAddr);
        IERC20(virtualDefedToken).approve(veDEFE,amount);
        if(locked.amount == 0){
            IVeDEFE(veDEFE).createLockFor(proxyAddr,amount,time);
        }else{
            IVeDEFE(veDEFE).increaseAmountFor(proxyAddr,amount);
        }
    }

}