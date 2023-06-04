node:
	yarn hardhat node

compile:
	yarn hardhat compile

deploy: 
	yarn hardhat run scripts/deploy.ts --network localhost

console:
	yarn hardhat console