# Smart-Contract-v1.0

# DEFED



DEFED creates a super account system for users and divides the entire account into asset storage mediums and interaction tools. The DEFE token is both a governance token and a utility token. Users can enjoy these benefits by locking DEFE for a period of time and exchanging it for veDEFE.

## Project deploy to polygon mumbai testnet
### Environment preparation
node V14.2.0
cp .env_example .env
add config params
### step
1. npm install 
2. npx hardhat run scripts/deploy_lendingPool.js --network mumbai
3. npx hardhat run scripts/deploy.js --network mumbai