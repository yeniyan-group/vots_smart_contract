-include .env

.PHONY: all test clean deploy help install snapshot format anvil


# Clean the repo
clean  :; forge clean


install :; forge install OpenZeppelin/openzeppelin-contracts@v5.3.0 --no-commit && forge install smartcontractkit/chainlink@v2.24.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

fork-test :; forge test --fork-url SEPOLIA_RPC_URL 

snapshot :; forge snapshot

format :; forge fmt

deploy-votsengine :; @forge script script/DeployVotsEngine.s.sol:DeployVotsEngine --rpc-url ${SEPOLIA_RPC_URL} --account vutsdefault --broadcast --verify  --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv