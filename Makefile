-include .env

.PHONY: all test clean deploy help install snapshot format anvil


# Clean the repo
clean  :; forge clean


install :; forge install cyfrin/foundry-devops@0.3.2 --no-commit && forge install OpenZeppelin/openzeppelin-contracts@v5.3.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

deploy-vutsengine :; @forge script script/DeployVutsEngine.s.sol:DeployVutsEngine --rpc-url ${SEPOLIA_RPC_URL} --account vutsdefault --broadcast --verify  --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv