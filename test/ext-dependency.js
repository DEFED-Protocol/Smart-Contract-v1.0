

const hre = require("hardhat");

ETHUSer = "0x0000000000000000000000000000000000000000"
chainId = "1234"

// placeBefore
exports.deployDep = async () => {

    // create account
    [owner, sender, receiver, purchaser, beneficiary] = await hre.ethers.getSigners();
    console.log("> create account success");

    // deploy MockERC20
    const TokenController = await hre.ethers.getContractFactory("TokenController");
    const tokenController = await (await TokenController.deploy()).deployed();
    console.log("deploy tokenController")    
    console.log("tokenController   deployed to: ", tokenController.address);
    
    console.log("\ndeploy mockProvider")    
    mockProvider = await deployProvider();
    console.log("\ndeploy LendingPool")    
    lendingPool = await deployLendingPool();
    lendingPool.initialize(mockProvider.address);

    const UserProxy = await hre.ethers.getContractFactory("UserProxy");
    const userProxy = await(await UserProxy.deploy(ETHUSer,lendingPool.address,chainId)).deployed();
    console.log("\ndeploy UserProxy")    
    console.log("userProxy         deployed to: ", userProxy.address);


}

async function deployProvider(){
    const MockOracle = await hre.ethers.getContractFactory("MockOracle");
    const mockOracle = await(await MockOracle.deploy()).deployed();
    console.log("mockOracle        deployed to: ", mockOracle.address);

    const MockProvider = await hre.ethers.getContractFactory("MockProvider");
    const mockProvider = await(await MockProvider.deploy()).deployed();
    console.log("mockProvider      deployed to: ", mockProvider.address);

    await mockProvider.setPriceOracle(mockProvider.address);
    return mockProvider;

}

async function deployLendingPool(){
    const ReserveLogic = await hre.ethers.getContractFactory("ReserveLogic");
    const reserveLogic = await(await ReserveLogic.deploy()).deployed();
    console.log("reserveLogic      deployed to: ", reserveLogic.address);

    const GenericLogic = await hre.ethers.getContractFactory("GenericLogic");
    const genericLogic = await(await GenericLogic.deploy()).deployed();

    console.log("genericLogic      deployed to: ", genericLogic.address);
    

    const ValidationLogic = await hre.ethers.getContractFactory("ValidationLogic",{libraries:{
        GenericLogic: genericLogic.address
    }
    });
    const validationLogic = await(await ValidationLogic.deploy()).deployed();
    console.log("validationLogic   deployed to: ", validationLogic.address);

    const LendingPool = await hre.ethers.getContractFactory("LendingPool",{libraries:{
        ReserveLogic:reserveLogic.address,
        ValidationLogic:validationLogic.address
        }
    });
    const lendingPool = await(await LendingPool.deploy()).deployed();

    console.log("lendingPool       deployed to: ", lendingPool.address);
    return lendingPool;
}