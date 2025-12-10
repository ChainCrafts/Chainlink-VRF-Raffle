# 🎰 Chainlink VRF Raffle

A provably fair, decentralized lottery smart contract built with Foundry and Chainlink VRF v2.5.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-blue.svg)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://book.getfoundry.sh/)

## 📖 About

This project implements a trustless raffle system where:

- 🎫 Players enter by paying an entrance fee
- ⏰ A winner is automatically selected after a time interval
- 🎲 Randomness is provided by Chainlink VRF v2.5 (verifiably random)
- 🤖 Automation is handled by Chainlink Automation (Keepers)
- 💰 The winner receives the entire prize pool

## ✨ Features

- **Provably Fair**: Uses Chainlink VRF for verifiable randomness
- **Automated**: Chainlink Automation triggers winner selection
- **Secure**: Implements ReentrancyGuard, pausable functionality, and emergency withdrawal
- **Gas Optimized**: Short-circuit evaluation and efficient storage patterns
- **Well Tested**: Comprehensive unit and integration tests

## 🏗️ Architecture

```
src/
├── Raffle.sol          # Main raffle contract

script/
├── DeployRaffle.s.sol  # Deployment script
├── HelperConfig.s.sol  # Network configuration
└── Interactions.s.sol  # VRF subscription management

test/
├── unit/
│   └── RaffleTest.t.sol       # Unit tests
└── integration/
    └── Interactions.t.sol     # Integration tests
```

## 🚀 Getting Started

### Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```bash
# Clone the repository
git clone https://github.com/ChainCrafts/Chainlink-VRF-Raffle.git
cd Chainlink-VRF-Raffle

# Install dependencies
make install

# Build
make build
```

### Configuration

Create a `.env` file in the root directory:

```env
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests with verbosity
make test-v

# Run tests on Sepolia fork
make test-fork

# Generate coverage report
make coverage
```

## 📦 Deployment

### Local (Anvil)

```bash
# Start local node in terminal 1
make anvil

# Deploy in terminal 2
make deploy-anvil
```

### Sepolia Testnet

```bash
# Deploy to Sepolia
make deploy-sepolia
```

## 🔧 Makefile Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make build` | Compile contracts |
| `make test` | Run all tests |
| `make coverage` | Generate coverage report |
| `make deploy-anvil` | Deploy to local Anvil |
| `make deploy-sepolia` | Deploy to Sepolia |
| `make create-sub` | Create VRF subscription |
| `make fund-sub` | Fund VRF subscription |
| `make add-consumer` | Add consumer to subscription |

## 📜 Contract Details

### Raffle.sol

| Function | Description |
|----------|-------------|
| `enterRaffle()` | Enter the raffle by paying entrance fee |
| `checkUpkeep()` | Check if conditions are met for winner selection |
| `performUpkeep()` | Request random winner from Chainlink VRF |
| `fulfillRandomWords()` | Callback that picks winner and sends prize |
| `pause()` | Pause the raffle (owner only) |
| `unpause()` | Unpause the raffle (owner only) |
| `emergencyWithdraw()` | Withdraw stuck funds (owner only, no active players) |

### Configuration

| Parameter | Sepolia | Local |
|-----------|---------|-------|
| Entrance Fee | 0.01 ETH | 0.01 ETH |
| Interval | 30 seconds | 30 seconds |
| Callback Gas Limit | 500,000 | 500,000 |

## 🔐 Security

- **ReentrancyGuard**: Protects against reentrancy attacks on prize distribution
- **Pausable**: Owner can pause in case of emergency
- **Emergency Withdraw**: Owner can recover stuck funds (only when no active players)
- **CEI Pattern**: Follows Checks-Effects-Interactions pattern

## 🛠️ Technologies

- [Solidity](https://docs.soliditylang.org/) - Smart contract language
- [Foundry](https://book.getfoundry.sh/) - Development framework
- [Chainlink VRF v2.5](https://docs.chain.link/vrf) - Verifiable randomness
- [Chainlink Automation](https://docs.chain.link/chainlink-automation) - Automated execution
- [Solmate](https://github.com/transmissions11/solmate) - Gas-optimized contracts

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.




