const { time } = require('console');
const { verify } = require('crypto');
var fs = require('fs');

const hre = require("hardhat");




async function main() {
  const accounts = await hre.ethers.getSigners();
  console.log(accounts[0].address);
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
