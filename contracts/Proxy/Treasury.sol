
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
import "./interfaces/IERC20.sol";
import "./interfaces/IVTokenFactory.sol";
import "./libraries/Ownable.sol";
import "./interfaces/IBridgeControl.sol";
contract Treasury is Ownable {


    address public vTokenFactory;
    address public bridgeControl;

	event WithdrawToEthereum(address token,uint256 amount ,address user);


	constructor () {
			
	}

	function withdrawToEthereum(address asset, uint256 amount,address to) public onlyOwner{
		address vToken = IVTokenFactory(vTokenFactory).getVToken(asset);
        require(vToken == address(0), "unknow token");
		IERC20(vToken).transfer(bridgeControl,amount);
		IBridgeControl(bridgeControl).transferToEthereum(vToken, to, amount);
        emit WithdrawToEthereum(asset,amount,to);
	}

    function claimToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function setVTokenFactory(address _vTokenFactory) public onlyOwner{
        vTokenFactory = _vTokenFactory;
        
	}

    function setBridgeControl(address _bridgeControl) public onlyOwner{
        bridgeControl = _bridgeControl;
        
	}
	
}