-include .env

.PHONY: all test clean deploy help install snapshot format anvil


# Clean the repo
clean  :; forge clean


install :; forge install OpenZeppelin/openzeppelin-contracts@v5.3.0 --no-commit && forge install smartcontractkit/chainlink@v2.24.0 --no-commit && forge install Arachnid/solidity-stringutils --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

fork-test :; forge test --fork-url SEPOLIA_RPC_URL 

snapshot :; forge snapshot

format :; forge fmt

deploy-votsengine :; @forge script script/DeployVotsEngine.s.sol:DeployVotsEngine --rpc-url ${SEPOLIA_RPC_URL} --chain sepolia --account vutsdefault --broadcast --verify  --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-votsengine-fuji :; @forge script script/DeployVotsEngine.s.sol:DeployVotsEngine --rpc-url ${FUJI_RPC_URL} --account vutsdefault --broadcast --verifier-url ${FUJI_VERIFIER_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

verify-votsengine :; @forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain sepolia --watch 0x41A221CF6CD0d4BA6FDf18b6F492fFD048CbA287 "src/VotsEngine.sol:VotsEngine" --show-standard-json-input > standard-input2.json

verify-contract:
	@echo "Enter contract address:"
	@read CONTRACT_ADDRESS && \
	echo "Enter contract path and name (e.g., src/VotsEngine.sol:VotsEngine):" && \
	read CONTRACT_PATH && \
	forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain sepolia $$CONTRACT_ADDRESS "$$CONTRACT_PATH"