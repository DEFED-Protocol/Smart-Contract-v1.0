const { time } = require('console');
const { verify } = require('crypto');
var fs = require('fs');
const filePath = './scripts/Eth/'

const hre = require("hardhat");
var json = {};




async function main() {

  const nftName = "DEMONFT";
  const nftSymbol = "DEMONFT";
  const initBaseURI = "http://1234/";
  const initNotRevealedUri = "http://1234/";

  const accounts = await hre.ethers.getSigners();
  console.log(accounts[0].address);
  const CardNFT = await hre.ethers.getContractFactory("CardNFT");
  const cardNFT = await(await CardNFT.deploy(nftName,nftSymbol,initBaseURI,initNotRevealedUri)).deployed();
  json.cardNFT = cardNFT.address
  console.log("cardNFT     deployed to: ", cardNFT.address);

  const WETH = "0x4004b240c428de5b16ee4dc88beffd39eaef22e9";
  const WBTC = "0x22a3e165cca3b96e52595e2faf26e412ae09d444";
  const USDT = "0x3b9d4256daff1e6ca9b71d3f447a99b74d39ee9e";
  const USDC = "0xc334a566310446b80ab115d87bc45d18842b81a7";
  const AssetManagementt = await hre.ethers.getContractFactory("AssetManagement");
  const assetManagement = await(await AssetManagementt.deploy(WETH,cardNFT.address)).deployed();
  json.assetManagement = assetManagement.address
  const AssetmanagementAddress = assetManagement.address
  console.log("assetManagemnet      deployed to: ", AssetmanagementAddress);
  
  await cardNFT.setManagement(AssetmanagementAddress);
  console.log("cardNFT      setManagement to: ",AssetmanagementAddress);
  await assetManagement.activeToken(WBTC);
  await assetManagement.activeToken(USDT);
  await assetManagement.activeToken(USDC);
  console.log("assetManagemnet      addToken : four");

  const owners = ["0x3749f569fbE231056392c408323446A4795093E7","0xDF70AC60b838BD75131663aC768d364F6938B824","0xA192E61f9475D0Da5BBD242E666029b690F40427"];
  const GnosisSafe = await hre.ethers.getContractFactory("GnosisSafe");
  const gnosisSafe = await(await GnosisSafe.deploy(owners,2)).deployed();
  json.gnosisSafe = gnosisSafe.address
  console.log("gnosisSafe      deployed to: ", gnosisSafe.address);

  assetManagement.transferOwnership(gnosisSafe.address);
  console.log("gnosisSafe      dtransferOwnership ", assetManagement.address);




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
  
