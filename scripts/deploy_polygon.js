const { time } = require('console');
const { verify } = require('crypto');
var fs = require('fs');
const filePath = './scripts/deploy/'

const hre = require("hardhat");
var json = {};




async function main() {
  const ZEROAddress ="0x0000000000000000000000000000000000000000";
  const rewardController = "0xC6b2b24bDd1100024534d8d5b2ebb046Baef54DF";
  const defeToken = "0x3bC22170Cdf8d3B270F9eAbDDbC626b0d7DF6dAF";
  const feeVault = "0x103BBc3965669abFD9061B3D464A0B92fa1c526E";
  //const lendingPoolAddress = "0x51cA8452cE5C7a03D8427499488f2c4E35e4feC9";
  const fallbackOracle = "0x0000000000000000000000000000000000000000";
  const maticETH = "0xF7CEacF2Fd740916925b424393477e6BEc7F183A";


  const weth=  "0x4004b240c428de5b16ee4dc88beffd39eaef22e9";
  const wbtc= "0x22a3e165cca3b96e52595e2faf26e412ae09d444";
  const usdt= "0x3b9d4256daff1e6ca9b71d3f447a99b74d39ee9e";
  const usdc = "0xc334a566310446b80ab115d87bc45d18842b81a7";

  const PWETH="0x4E5F8fD6ED0b924Cc98085017B5648533CE4c79B";
  const PUSDC="0xE8828D51c6970fDc3EAA58c7fe54Fd8880c31b28";
  const PUSDT="0x90c424098711cc053906282d95cbBfa06B706549";
  const PWBTC="0xBB99fEF7664066d86C096368F2ce900936c2B51B";




  //const lendingPoolAddress = "0xc46927c170564a7425eb6e94628ee3ccefdfebf7";


  // We get the contract to deploy
  const accounts = await hre.ethers.getSigners();
  console.log(accounts[0].address);
  const ReserveLogic = await hre.ethers.getContractFactory("ReserveLogic");
  const reserveLogic = await(await ReserveLogic.deploy()).deployed();
  json.reserveLogic = reserveLogic.address
  console.log("reserveLogic      deployed to: ", reserveLogic.address);

  const GenericLogic = await hre.ethers.getContractFactory("GenericLogic");
  const genericLogic = await(await GenericLogic.deploy()).deployed();
  json.genericLogic = genericLogic.address
  console.log("genericLogic      deployed to: ", genericLogic.address);
  

  const ValidationLogic = await hre.ethers.getContractFactory("ValidationLogic",{libraries:{
    GenericLogic: genericLogic.address
   }
  });
  const validationLogic = await(await ValidationLogic.deploy()).deployed();
  json.validationLogic = validationLogic.address
  console.log("validationLogic      deployed to: ", validationLogic.address);

  const LendingPool = await hre.ethers.getContractFactory("LendingPool",{libraries:{
      ReserveLogic:reserveLogic.address,
      ValidationLogic:validationLogic.address
    }
  });
  const lendingPool = await(await LendingPool.deploy()).deployed();
  json.lendingPool = lendingPool.address
  console.log("lendingPool       deployed to: ", lendingPool.address);
  const lendingPoolAddress = lendingPool.address;


  const PriceOracle = await hre.ethers.getContractFactory("ChainlinkProxyPriceProvider");
  const priceOracle = await(await PriceOracle.deploy(fallbackOracle)).deployed();
  console.log("priceOracle      deployed to: ", priceOracle.address)

  const LendingPoolAddressesProviderRegistry = await hre.ethers.getContractFactory("LendingPoolAddressesProviderRegistry");
  const lendingPoolAddressesProviderRegistry = await(await LendingPoolAddressesProviderRegistry.deploy()).deployed();
  json.lendingPoolAddressesProviderRegistry = lendingPoolAddressesProviderRegistry.address
  console.log("lendingPoolAddressesProviderRegistry deployed to: ", lendingPoolAddressesProviderRegistry.address);
  
  const LendingPoolAddressesProvider = await hre.ethers.getContractFactory("LendingPoolAddressesProvider");
  const lendingPoolAddressesProvider = await(await LendingPoolAddressesProvider.deploy()).deployed();
  json.lendingPoolAddressesProvider = lendingPoolAddressesProvider.address
  console.log("lendingPoolAddressesProvider  deployed to: ", lendingPoolAddressesProvider.address);
  
  
  const LendingPoolConfigurator = await hre.ethers.getContractFactory("LendingPoolConfigurator");
  const lendingPoolConfigurator = await(await LendingPoolConfigurator.deploy()).deployed();
  json.lendingPoolConfigurator = lendingPoolConfigurator.address
  console.log("lendingPoolConfigurator       deployed to: ", lendingPoolConfigurator.address);

  const LendingPoolCollateralManager = await hre.ethers.getContractFactory("LendingPoolCollateralManager");
  const lendingPoolCollateralManager = await(await LendingPoolCollateralManager.deploy()).deployed();
  json.lendingPoolCollateralManager = lendingPoolCollateralManager.address
  console.log("lendingPoolCollateralManager  deployed to: ", lendingPoolCollateralManager.address);

  const DefedProtocolDataProvider = await hre.ethers.getContractFactory("DefedProtocolDataProvider");
  const defedProtocolDataProvider = await(await DefedProtocolDataProvider.deploy(lendingPoolAddressesProvider.address)).deployed();
  json.defedProtocolDataProvider = defedProtocolDataProvider.address
  console.log("defedProtocolDataProvider      deployed to: ", defedProtocolDataProvider.address);

  const LendingRateOracle = await hre.ethers.getContractFactory("LendingRateOracle");
  const lendingRateOracle = await(await LendingRateOracle.deploy()).deployed();
  json.lendingRateOracle = lendingRateOracle.address
  console.log("lendingRateOracle             deployed to: ", lendingRateOracle.address);

  await lendingPoolAddressesProviderRegistry.registerAddressesProvider(lendingPoolAddressesProvider.address,1);
  await lendingPoolAddressesProvider.setLendingPoolImpl(lendingPoolAddress);
  await lendingPoolAddressesProvider.setLendingPoolConfiguratorImpl(lendingPoolConfigurator.address);
  await lendingPoolAddressesProvider.setLendingPoolCollateralManager(lendingPoolCollateralManager.address);
  await lendingPoolAddressesProvider.setPriceOracle(priceOracle.address);
  await lendingPoolAddressesProvider.setLendingRateOracle(lendingRateOracle.address);
  await lendingPoolConfigurator.initialize(lendingPoolAddressesProvider.address);
  await lendingPoolAddressesProvider.setPoolAdmin(accounts[0].address);
  await lendingPoolAddressesProvider.setEmergencyAdmin(accounts[0].address);



  
  const UserProxyFactory = await hre.ethers.getContractFactory("UserProxyFactory");
  const userProxyFactory = await(await UserProxyFactory.deploy()).deployed();
  json.userProxyFactory = userProxyFactory.address
  console.log("userProxyFactory      deployed to: ", userProxyFactory.address);

  const Treasury = await hre.ethers.getContractFactory("Treasury");
  const treasury = await(await Treasury.deploy()).deployed();
  json.treasury = treasury.address
  console.log("treasury      deployed to: ", treasury.address);

  const BridgeFeeController = await hre.ethers.getContractFactory("BridgeFeeController");
  const bridgeFeeController = await(await BridgeFeeController.deploy(priceOracle.address,treasury.address)).deployed();
  json.userProxyFactory = bridgeFeeController.address
  console.log("bridgeFeeController      deployed to: ", bridgeFeeController.address);
  const VTokenFactory = await hre.ethers.getContractFactory("VTokenFactory");
  const vTokenFactory = await(await VTokenFactory.deploy()).deployed();
  json.vTokenFactory = vTokenFactory.address
  console.log("vTokenFactory      deployed to: ", vTokenFactory.address);

  const NetworkFeeController = await hre.ethers.getContractFactory("NetworkFeeController");
  const networkFeeController = await(await NetworkFeeController.deploy(priceOracle.address,treasury.address,maticETH)).deployed();
  json.networkFeeController = networkFeeController.address
  console.log("networkFeeController      deployed to: ", networkFeeController.address);

  const BridgeControl = await hre.ethers.getContractFactory("BridgeControl");
  const bridgeControl = await(await BridgeControl.deploy(userProxyFactory.address,vTokenFactory.address,lendingPoolAddress,bridgeFeeController.address)).deployed();
  json.bridgeControl = bridgeControl.address
  console.log("bridgeControl      deployed to: ", bridgeControl.address);
  await vTokenFactory.setBridgeControl(bridgeControl.address);
  console.log("vTokenFactory  setBridgeControl");
  const TokenController = await hre.ethers.getContractFactory("TokenController");
  const tokenController = await(await TokenController.deploy(lendingPoolAddress,bridgeControl.address,vTokenFactory.address,userProxyFactory.address,networkFeeController.address)).deployed();
  json.tokenController = tokenController.address
  console.log("tokenController      deployed to: ", tokenController.address);
  await vTokenFactory.createVToken(weth,PWETH,"VWETH","VWETH",18);
  await vTokenFactory.createVToken(wbtc,PWBTC,"VWBTC","VWBTC",8);
  await vTokenFactory.createVToken(usdt,PUSDT,"VUSDT","VUSDT",6);
  await vTokenFactory.createVToken(usdc,PUSDC,"VUSDC","VUSDC",6);
  console.log("four created ");

  const owners = ["0x3749f569fbE231056392c408323446A4795093E7","0xDF70AC60b838BD75131663aC768d364F6938B824","0xA192E61f9475D0Da5BBD242E666029b690F40427"];
  const GnosisSafe = await hre.ethers.getContractFactory("GnosisSafe");
  const gnosisSafe = await(await GnosisSafe.deploy(owners,2)).deployed();
  json.gnosisSafe = gnosisSafe.address
  console.log("gnosisSafe      deployed to: ", gnosisSafe.address);

  bridgeControl.transferOwnership(gnosisSafe.address);

 
  const Distribution = await hre.ethers.getContractFactory("Distribution");
  const distribution = await(await Distribution.deploy(rewardController,lendingPoolAddress,treasury.address,defeToken,feeVault)).deployed();
  json.distribution = distribution.address
  console.log("Distribution       deployed to: ",distribution.address);
  
  await treasury.setVTokenFactory(vTokenFactory.address);
  console.log("treasury      setVTokenFactory: ");

  const VWETH = await vTokenFactory.getVToken(weth);
  console.log("VWETH :",VWETH);
  const VWBTC = await vTokenFactory.getVToken(wbtc);
  console.log("VWBTC :",VWBTC);
  const VUSDT = await vTokenFactory.getVToken(usdt);
  console.log("VUSDT ",VUSDT);
  const VUSDC = await vTokenFactory.getVToken(usdc);
  console.log("VUSDC :",VUSDC);

  await treasury.setBridgeControl(bridgeControl.address);
  console.log("treasury      setBridgeControl: ");

  



  

//WETH

  const WETHDecimal = 18;
  const WETHaTokenName = "AVWETH";
  const WETHaTokenSymbol = "AVWETH";
  const WETHstableTokenName = "StableVWETH";
  const WETHstableTokenSymbol = "StableVWETH";
  const WETHvariableTokenName = "VariableVWETH";
  const WETHvariableokenSymbol = "VariableVWETH";

  const WETHoptimalUtilizationRate="700000000000000000000000000";
  const WETHbaseVariableBorrowRate = 0;
  const WETHvariableRateSlope1 = "30000000000000000000000000";
  const WETHvariableRateSlope2 = "1000000000000000000000000000";
  const WETHstableRateSlope1 = "40000000000000000000000000";
  const WETHstableRateSlope2 = "1000000000000000000000000000";
  const WETHdescription = "VWETH/ETH";


  //WBTC

  const WBTCDecimal = 8;
  const WBTCaTokenName = "AVWBTC";
  const WBTCaTokenSymbol = "AVWBTC";
  const WBTCstableTokenName = "StableVWBTC";
  const WBTCstableTokenSymbol = "StableVWBTC";
  const WBTCvariableTokenName = "VariableVWBTC";
  const WBTCvariableokenSymbol = "VariableVWBTC";

  const WBTCoptimalUtilizationRate="650000000000000000000000000";
  const WBTCbaseVariableBorrowRate = 0;
  const WBTCvariableRateSlope1 = "80000000000000000000000000";
  const WBTCvariableRateSlope2 = "3000000000000000000000000000";
  const WBTCstableRateSlope1 = "100000000000000000000000000";
  const WBTCstableRateSlope2 = "3000000000000000000000000000";
  const WBTCdescription = "VWBTC/ETH";

  //USDT
  const USDTDecimal = 6;
  const USDTaTokenName = "AVUSDT";
  const USDTaTokenSymbol = "AVUSDT";
  const USDTstableTokenName = "StableVUSDT";
  const USDTstableTokenSymbol = "StableVUSDT";
  const USDTvariableTokenName = "VariableVUSDT";
  const USDTvariableokenSymbol = "VariableVUSDT";

  const USDToptimalUtilizationRate="900000000000000000000000000";
  const USDTbaseVariableBorrowRate = 0;
  const USDTvariableRateSlope1 = "40000000000000000000000000";
  const USDTvariableRateSlope2 = "600000000000000000000000000";
  const USDTstableRateSlope1 = "20000000000000000000000000";
  const USDTstableRateSlope2 = "600000000000000000000000000";
  const USDTdescription = "VUSDT/ETH";

 //USDC
 const USDCDecimal = 6;
 const USDCaTokenName = "AVUSDC";
 const USDCaTokenSymbol = "AVUSDC";
 const USDCstableTokenName = "StableVUSDC";
 const USDCstableTokenSymbol = "StableVUSDC";
 const USDCvariableTokenName = "VariableVUSDC";
 const USDCvariableokenSymbol = "VariableVUSDC";

 const USDCoptimalUtilizationRate="900000000000000000000000000";
 const USDCbaseVariableBorrowRate = 0;
 const USDCvariableRateSlope1 = "40000000000000000000000000";
 const USDCvariableRateSlope2 = "600000000000000000000000000";
 const USDCstableRateSlope1 = "20000000000000000000000000";
 const USDCstableRateSlope2 = "600000000000000000000000000";
 const USDCdescription = "VUSDC/ETH";





  const AToken = await hre.ethers.getContractFactory("AToken");
  const WETHaToken = await(await AToken.deploy(lendingPoolAddress,VWETH,distribution.address,WETHaTokenName,WETHaTokenSymbol,rewardController,WETHDecimal)).deployed();
  json.WETHaToken = WETHaToken.address
  console.log("VWETH      deployed to: ", VWETH);
  console.log("WETHaToken      deployed to: ", WETHaToken.address);
  const WBTCaToken = await(await AToken.deploy(lendingPoolAddress,VWBTC,distribution.address,WBTCaTokenName,WBTCaTokenSymbol,rewardController,WBTCDecimal)).deployed();
  json.WBTCaToken = WBTCaToken.address
  console.log("VWBTC      deployed to: ", VWBTC);
  console.log("WBTCaToken      deployed to: ", WBTCaToken.address);
  const USDTaToken = await(await AToken.deploy(lendingPoolAddress,VUSDT,distribution.address,USDTaTokenName,USDTaTokenSymbol,rewardController,USDTDecimal)).deployed();
  json.WBTCaToken = USDTaToken.address
  console.log("VUSDT      deployed to: ", VUSDT);
  console.log("USDTaToken      deployed to: ", USDTaToken.address);
  const USDCaToken = await(await AToken.deploy(lendingPoolAddress,VUSDC,distribution.address,USDCaTokenName,USDCaTokenSymbol,rewardController,USDCDecimal)).deployed();
  json.USDCaToken = USDCaToken.address
  console.log("VUSDC      deployed to: ", VUSDC);
  console.log("USDCaToken      deployed to: ", USDCaToken.address);


  const StableToken = await hre.ethers.getContractFactory("StableDebtToken");
  const WETHstableToken = await(await StableToken.deploy(lendingPoolAddress,VWETH,WETHstableTokenName,WETHstableTokenSymbol,rewardController,WETHDecimal)).deployed();
  json.WETHstableToken = WETHstableToken.address
  console.log("WETHstableToken      deployed to: ", WETHstableToken.address);
  const WBTCstableToken = await(await StableToken.deploy(lendingPoolAddress,VWBTC,WBTCstableTokenName,WBTCstableTokenSymbol,rewardController,WBTCDecimal)).deployed();
  json.WBTCstableToken = WBTCstableToken.address
  console.log("WBTCstableToken      deployed to: ", WBTCstableToken.address);
  const USDTstableToken = await(await StableToken.deploy(lendingPoolAddress,VUSDT,USDTstableTokenName,USDTstableTokenSymbol,rewardController,USDTDecimal)).deployed();
  json.USDTstableToken = USDTstableToken.address
  console.log("USDTstableToken      deployed to: ", USDTstableToken.address);
  const USDCstableToken = await(await StableToken.deploy(lendingPoolAddress,VUSDC,USDCstableTokenName,USDCstableTokenSymbol,rewardController,USDCDecimal)).deployed();
  json.USDCstableToken = USDCstableToken.address
  console.log("USDCstableToken      deployed to: ", USDCstableToken.address);


  const VariableToken = await hre.ethers.getContractFactory("VariableDebtToken");
  const WETHvariableToken = await(await VariableToken.deploy(lendingPoolAddress,VWETH,WETHvariableTokenName,WETHvariableokenSymbol,rewardController,WETHDecimal)).deployed();
  json.WETHvariableToken = WETHvariableToken.address
  console.log("WETHvariableToken      deployed to: ", WETHvariableToken.address);
 
  const WBTCvariableToken = await(await VariableToken.deploy(lendingPoolAddress,VWBTC,WBTCvariableTokenName,WBTCvariableokenSymbol,rewardController,WBTCDecimal)).deployed();
  json.WBTCvariableToken = WBTCvariableToken.address
  console.log("WBTCvariableToken      deployed to: ", WBTCvariableToken.address);
  
  const USDTvariableToken = await(await VariableToken.deploy(lendingPoolAddress,VUSDT,USDTvariableTokenName,USDTvariableokenSymbol,rewardController,USDTDecimal)).deployed();
  json.USDTvariableToken = USDTvariableToken.address
  console.log("USDTvariableToken      deployed to: ", USDTvariableToken.address);

  const USDCvariableToken = await(await VariableToken.deploy(lendingPoolAddress,VUSDC,USDCvariableTokenName,USDCvariableokenSymbol,rewardController,USDCDecimal)).deployed();
  json.USDCvariableToken = USDCvariableToken.address
  console.log("USDCvariableToken      deployed to: ", USDCvariableToken.address);
  
  const RateStrategy = await hre.ethers.getContractFactory("DefaultReserveInterestRateStrategy");
  const WETHrateStrategy = await(await RateStrategy.deploy(lendingPoolAddressesProvider.address,WETHoptimalUtilizationRate,WETHbaseVariableBorrowRate,WETHvariableRateSlope1,WETHvariableRateSlope2,WETHstableRateSlope1,WETHstableRateSlope2)).deployed();
  json.WETHrateStrategy = WETHrateStrategy.address
  console.log("WETHrateStrategy      deployed to: ", WETHrateStrategy.address);
  const WBTCrateStrategy = await(await RateStrategy.deploy(lendingPoolAddressesProvider.address,WBTCoptimalUtilizationRate,WBTCbaseVariableBorrowRate,WBTCvariableRateSlope1,WBTCvariableRateSlope2,WBTCstableRateSlope1,WBTCstableRateSlope2)).deployed();
  json.WBTCrateStrategy = WBTCrateStrategy.address
  console.log("WBTCrateStrategy      deployed to: ", WBTCrateStrategy.address);
  const USDTrateStrategy = await(await RateStrategy.deploy(lendingPoolAddressesProvider.address,USDToptimalUtilizationRate,USDTbaseVariableBorrowRate,USDTvariableRateSlope1,USDTvariableRateSlope2,USDTstableRateSlope1,USDTstableRateSlope2)).deployed();
  json.USDTrateStrategy = USDTrateStrategy.address
  console.log("USDTrateStrategy      deployed to: ", USDTrateStrategy.address);
  const USDCrateStrategy = await(await RateStrategy.deploy(lendingPoolAddressesProvider.address,USDCoptimalUtilizationRate,USDCbaseVariableBorrowRate,USDCvariableRateSlope1,USDCvariableRateSlope2,USDCstableRateSlope1,USDCstableRateSlope2)).deployed();
  json.USDCrateStrategy = USDCrateStrategy.address
  console.log("USDCrateStrategy      deployed to: ", USDCrateStrategy.address);

  const TokenAggregator = await hre.ethers.getContractFactory("TokenAggregator");
  const WETHtokenAggregator = await(await TokenAggregator.deploy(WETHdescription,VWETH,WETHDecimal)).deployed();
  json.WETHtokenAggregator = WETHtokenAggregator.address
  await WETHtokenAggregator.submit("1000000000000000000");
  console.log("WETHtokenAggregator      deployed to: ", WETHtokenAggregator.address);
  const WBTCtokenAggregator = await(await TokenAggregator.deploy(WBTCdescription,VWBTC,WBTCDecimal)).deployed();
  json.WBTCtokenAggregator = WBTCtokenAggregator.address
  console.log("WBTCtokenAggregator      deployed to: ", WBTCtokenAggregator.address);
  await WBTCtokenAggregator.submit("16761649346295680000");
  const USDTtokenAggregator = await(await TokenAggregator.deploy(USDTdescription,VUSDT,USDTDecimal)).deployed();
  json.USDTtokenAggregator = USDTtokenAggregator.address
  console.log("USDTtokenAggregator      deployed to: ", USDTtokenAggregator.address);
  await USDTtokenAggregator.submit("818787760000000");
  const USDCtokenAggregator = await(await TokenAggregator.deploy(USDCdescription,VUSDC,USDCDecimal)).deployed();
  json.USDCtokenAggregator = USDCtokenAggregator.address
  console.log("USDCtokenAggregator      deployed to: ", USDCtokenAggregator.address);
  await USDCtokenAggregator.submit("818787760000000");

  priceOracle.setAssetSources([VWBTC, VUSDT,VUSDC], [WBTCtokenAggregator.address, USDTtokenAggregator.address, USDCtokenAggregator.address])
  console.log("priceOracle      setAssetSources ");

   

  await lendingPoolConfigurator.initReserve(WETHaToken.address,WETHstableToken.address,WETHvariableToken.address,WETHDecimal,WETHrateStrategy.address);
  console.log("initReserve WETH")
  await lendingPoolConfigurator.configureReserveAsCollateral(VWETH,8250,8500,10500);
  console.log("configureReserveAsCollateral WETH")
  await lendingPoolConfigurator.enableBorrowingOnReserve(VWETH,true);
  console.log("enableBorrowingOnReserve WETH")
  await lendingPoolConfigurator.setReserveFactor(VWETH,1000);
  console.log("setReserveFactor WETH")

  await lendingPoolConfigurator.initReserve(WBTCaToken.address,WBTCstableToken.address,WBTCvariableToken.address,WBTCDecimal,WBTCrateStrategy.address);
  console.log("initReserve WBTC")
  await lendingPoolConfigurator.configureReserveAsCollateral(VWBTC,7000,7500,10650);
  console.log("configureReserveAsCollateral WBTC")
  await lendingPoolConfigurator.enableBorrowingOnReserve(VWBTC,true);
  console.log("enableBorrowingOnReserve WBTC")
  await lendingPoolConfigurator.setReserveFactor(VWBTC,1000);
  console.log("setReserveFactor WBTC")


  await lendingPoolConfigurator.initReserve(USDTaToken.address,USDTstableToken.address,USDTvariableToken.address,USDTDecimal,USDTrateStrategy.address);
  console.log("initReserve USDT")
  await lendingPoolConfigurator.configureReserveAsCollateral(VUSDT,8550,8800,10450);
  console.log("configureReserveAsCollateral USDT")
  await lendingPoolConfigurator.enableBorrowingOnReserve(VUSDT,true);
  console.log("enableBorrowingOnReserve USDT")
  await lendingPoolConfigurator.setReserveFactor(VUSDT,1000);
  console.log("setReserveFactor USDT")

  await lendingPoolConfigurator.initReserve(USDCaToken.address,USDCstableToken.address,USDCvariableToken.address,USDCDecimal,USDCrateStrategy.address);
  console.log("initReserve USDC")
  await lendingPoolConfigurator.configureReserveAsCollateral(VUSDC,8550,8800,10450);
  console.log("configureReserveAsCollateral USDC")
  await lendingPoolConfigurator.enableBorrowingOnReserve(VUSDC,true);
  console.log("enableBorrowingOnReserve USDC")
  await lendingPoolConfigurator.setReserveFactor(VUSDC,1000);
  console.log("setReserveFactor USDC")









 


  t = new Date().getTime()
  write(json,t)
  
  
}

function write(json,t){
  var jsonstr = JSON.stringify(json);
  
  fs.writeFileSync(filePath+t+".json", jsonstr, function(err) {
      if (err) {
         console.error(err);
      }else{
        console.log(jsonstr)
      }
   });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
