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

deploy-votsengine-fuji :; @forge script script/DeployVotsEngine.s.sol:DeployVotsEngine --rpc-url ${FUJI_RPC_URL} --account vutsdefault --broadcast --verifier-url ${FUJI_VERIFIER_URL} --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

verify-votsengine :;forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain sepolia 0xbC9aFaB1b833427195F9674b0f34B501b408f810 "src/VotsEngine.sol:VotsEngine"

verify-contract:
	@echo "Enter contract address:"
	@read CONTRACT_ADDRESS && \
	echo "Enter contract path and name (e.g., src/VotsEngine.sol:VotsEngine):" && \
	read CONTRACT_PATH && \
	forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain sepolia $$CONTRACT_ADDRESS "$$CONTRACT_PATH"