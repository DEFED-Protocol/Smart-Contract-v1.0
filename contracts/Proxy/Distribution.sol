
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;
import "./interfaces/ILendingPool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IIncentivesController.sol";
import "./libraries/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IAToken.sol";

contract Distribution is Ownable {
	 using SafeMath for uint;


	bytes32 public constant OPERATORROLE = keccak256("OPERATORROLE");

	address public lendingPOOL;
	address public rewardController;
    address public defeToken;
	uint256 public platformRatio;
	uint256 public bonusRatio;
	address public treasury;
	address public feeVault;

	event Distribute(address[]  aTokens);
	event ClaimRewards(address[]  tokens,uint256 amount,address to);


	constructor (address _rewardController,address _lendingPool,address _treasury,address _defeToken,address _feeVault) {
        rewardController = _rewardController;
        lendingPOOL = _lendingPool;
        defeToken = _defeToken;
		platformRatio = 70;
		bonusRatio = 30;
		treasury = _treasury;
		feeVault = _feeVault;
	}

	function setRewardController(address _rewardController) public onlyOwner{
        rewardController = _rewardController;
        
	}
	
	function setLendingPool(address _lendingPool) public onlyOwner{
        lendingPOOL = _lendingPool;
        
	}

	function setTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;
        
	}


	function distribute(address[] memory aTokens) public  onlyOwner {//鉴权
		for(uint256 i=0; i<aTokens.length; i++){
			uint256 aTokenBalance = IAToken(aTokens[i]).balanceOf(address(this));
			address vToken =  IAToken(aTokens[i]).UNDERLYING_ASSET_ADDRESS();
			require(vToken != address(0), "unknow token");
			ILendingPool(lendingPOOL).withdraw(vToken,aTokenBalance,address(this));
			uint256 vTokenBalance = IERC20(vToken).balanceOf(address(this));
			uint256 treasuryAmount = vTokenBalance.mul(platformRatio).div(100);
			uint256 feeValutAmount = vTokenBalance.mul(bonusRatio).div(100);
			IERC20(vToken).transfer(treasury,treasuryAmount);
			IERC20(vToken).transfer(feeVault,feeValutAmount);

		}
		emit Distribute (aTokens);
	}


	function claimRewards(address[] memory aTokens,uint256 amount,address to ) public onlyOwner {
		require(amount > 0, "amount error");
		IIncentivesController(rewardController).claimRewards(aTokens,amount);
        IERC20(defeToken).transfer(to,amount);
		emit ClaimRewards(aTokens,amount,to);
	}

	function setRatio(uint256 _platformRatio, uint256 _bonusRatio) external onlyOwner {
		require(_platformRatio + bonusRatio == 100,"ratio error");
        platformRatio = _platformRatio;
		bonusRatio = _bonusRatio;
    }

	
}