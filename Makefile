-include .env

.PHONY: all test deploy clean install update build snapshot format lint coverage anvil help

# Default target
all: clean install build

# Display help
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Clean, install dependencies, and build"
	@echo "  build            - Compile contracts"
	@echo "  test             - Run all tests"
	@echo "  test-v           - Run tests with verbosity"
	@echo "  test-fork        - Run tests on Sepolia fork"
	@echo "  coverage         - Generate test coverage report"
	@echo "  snapshot         - Create gas snapshot"
	@echo "  format           - Format code with forge fmt"
	@echo "  lint             - Run forge lint"
	@echo "  clean            - Remove build artifacts"
	@echo "  install          - Install dependencies"
	@echo "  update           - Update dependencies"
	@echo "  anvil            - Start local Anvil node"
	@echo "  deploy-anvil     - Deploy to local Anvil"
	@echo "  deploy-sepolia   - Deploy to Sepolia testnet"
	@echo "  create-sub       - Create VRF subscription"
	@echo "  fund-sub         - Fund VRF subscription"
	@echo "  add-consumer     - Add consumer to VRF subscription"

# Build & Test
build:; forge build
clean:; forge clean
test:; forge test
test-v:; forge test -vvvv
test-fork:; forge test --fork-url $(SEPOLIA_RPC_URL)
coverage:; forge coverage --report lcov && forge coverage
snapshot:; forge snapshot

# Code Quality
format:; forge fmt
lint:; forge lint

# Dependencies
install:
	forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-git
	forge install foundry-rs/forge-std@v1.11.0 --no-git
	forge install Cyfrin/foundry-devops@0.4.0 --no-git
	forge install transmissions11/solmate@v6 --no-git

update:; forge update

# Local Development
anvil:; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Deployment - Local Anvil
deploy-anvil:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url http://localhost:8545 --private-key $(ANVIL_PRIVATE_KEY) --broadcast -vvvv

# Deployment - Sepolia Testnet
deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account myAccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# VRF Subscription Management - Sepolia
create-sub:
	@forge script script/Interactions.s.sol:CreateSubscription --rpc-url $(SEPOLIA_RPC_URL) --account myAccount --broadcast -vvvv

fund-sub:
	@forge script script/Interactions.s.sol:FundSubscription --rpc-url $(SEPOLIA_RPC_URL) --account myAccount --broadcast -vvvv

add-consumer:
	@forge script script/Interactions.s.sol:AddConsumer --rpc-url $(SEPOLIA_RPC_URL) --account myAccount --broadcast -vvvv