const { time } = require('console');
const { verify } = require('crypto');
var fs = require('fs');
const filePath = './scripts/deploy/'

const hre = require("hardhat");
const { writeHeapSnapshot } = require('v8');
var json = {};




async function main() {
 
  const fallbackOracle = "0x0000000000000000000000000000000000000000";
  const weth=  "0x4004b240c428de5b16ee4dc88beffd39eaef22e9";
  const wbtc= "0x708956f5109Bc3433dA4BE7DEaC79BE2f4b9b7FE";
  


  const accounts = await hre.ethers.getSigners();
  console.log(accounts[0].address);
  const PriceOracle = await hre.ethers.getContractFactory("ChainlinkProxyPriceProvider");
  const priceOracle = await(await PriceOracle.deploy(fallbackOracle)).deployed();
  console.log("priceOracle      deployed to: ", priceOracle.address);

  await priceOracle.setAssetSources([weth],[wbtc]);
  const priceOracle22 = await(await PriceOracle.deploy(fallbackOracle)).deployed();
  console.log("priceOracle22      deployed to: ", priceOracle22.address);

 

  const price  = await priceOracle.getSourceOfAsset(weth);
  const aaa  = await priceOracle.getAssetPrice(weth);


  console.log("priceOracle  price",aaa )
  
  


 


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
  
