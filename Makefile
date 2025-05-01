-include .env

.PHONY: all test clean deploy help install snapshot format anvil


# Clean the repo
clean  :; forge clean


install :; forge install cyfrin/foundry-devops@0.3.2 --no-commit && forge install OpenZeppelin/openzeppelin-contracts@v5.3.0 --no-commit 
