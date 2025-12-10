// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

/**
 * @title CodeConstants
 * @author ChainCrafts
 * @notice Contains constant values used across deployment and testing scripts
 * @dev Provides VRF mock parameters and chain ID constants
 */
abstract contract CodeConstants {
    /// @notice Base fee for VRF mock (0.001 ETH)
    uint96 public MOCK_BASE_FEE = 0.001 ether;
    /// @notice Gas price for LINK token in VRF mock
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    /// @notice LINK/ETH price ratio for VRF mock
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    /// @notice Chain ID for Ethereum Sepolia testnet
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    /// @notice Chain ID for local Anvil network
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    /**
     * @notice Default Anvil account (Account #0)
     * @dev This is the first default account provided by Anvil/Foundry for local testing
     *      Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
     *      DO NOT use this account on mainnet or testnets with real funds!
     */
    address public constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
}

/**
 * @title HelperConfig
 * @author ChainCrafts
 * @notice Manages network-specific configurations for the Raffle contract deployment
 * @dev Supports Sepolia testnet and local Anvil network with automatic mock deployment
 */
contract HelperConfig is CodeConstants, Script {
    /// @notice Thrown when an unsupported chain ID is used
    error HelperConfig__InvalidChainId();

    /**
     * @notice Configuration parameters for each supported network
     * @param entranceFee Minimum ETH required to enter the raffle
     * @param interval Duration between raffle rounds in seconds
     * @param vrfCoordinator Address of the Chainlink VRF Coordinator
     * @param gasLane Key hash for the VRF gas lane
     * @param callbackGasLimit Gas limit for the VRF callback function
     * @param subscriptionId Chainlink VRF subscription ID
     * @param link Address of the LINK token contract
     * @param account Default account for broadcasting transactions
     */
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
        address link;
        address account;
    }

    /// @notice Stores the local network configuration (for Anvil)
    NetworkConfig public localNetworkConfig;
    /// @notice Maps chain IDs to their respective network configurations
    mapping(uint256 chainId => NetworkConfig) networkConfigs;

    /**
     * @notice Initializes the HelperConfig with Sepolia configuration
     */
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    /**
     * @notice Retrieves the network configuration for a specific chain ID
     * @param chainId The chain ID to get the configuration for
     * @return NetworkConfig memory The configuration for the specified chain
     * @dev Reverts with HelperConfig__InvalidChainId if chain is not supported
     */
    function getConfigByChainID(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /**
     * @notice Retrieves the network configuration for the current chain
     * @return NetworkConfig memory The configuration for the current chain
     */
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainID(block.chainid);
    }

    /**
     * @notice Returns the configuration for Ethereum Sepolia testnet
     * @return NetworkConfig memory The Sepolia network configuration
     */
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether, //10e16
            interval: 30, //every 30 second
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, //500,000
            subscriptionId: 111487715276674919122243232754352777667747705596574764393310397527054366917148,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x8301eb30c92B619bEe4EC759e9b2C707EFE6eCFf
        });
    }

    /**
     * @notice Returns or creates the configuration for local Anvil network
     * @dev Deploys VRFCoordinatorV2_5Mock and LinkToken if not already deployed
     * @return NetworkConfig memory The Anvil network configuration
     */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we have an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        //if we don't have then we need to deploy mocks and such

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether, //10e16
            interval: 30, //every 30 second
            vrfCoordinator: address(vrfCoordinatorMock),
            // gasLane does not matter it will work in our mock anyways!
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000, //500,000
            subscriptionId: 0,
            link: address(linkToken),
            account: ANVIL_DEFAULT_ACCOUNT
        });

        return localNetworkConfig;
    }
}
