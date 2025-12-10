// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title CreateSubscription
 * @author ChainCrafts
 * @notice Script to create a new Chainlink VRF subscription
 * @dev Creates a subscription on the VRF Coordinator for the current network
 */
contract CreateSubscription is Script {
    /**
     * @notice Creates a subscription using the current network configuration
     * @return subId The newly created subscription ID
     * @return vrfCoordinator The address of the VRF Coordinator used
     */
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator, account);

        return (subId, vrfCoordinator);
    }

    /**
     * @notice Creates a new VRF subscription on the specified coordinator
     * @param vrfCoordinator The address of the VRF Coordinator contract
     * @param account The account to broadcast the transaction from
     * @return subId The newly created subscription ID
     * @return The address of the VRF Coordinator used
     */
    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("creating subscription on chain id :", block.chainid);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("now you sub id =", subId);
        console.log("update sub id in your helperconfig.s.sol file");

        return (subId, vrfCoordinator);
    }

    /**
     * @notice Entry point for the script
     * @dev Calls createSubscriptionUsingConfig to create a new subscription
     */
    function run() public {
        createSubscriptionUsingConfig();
    }
}

/**
 * @title FundSubscription
 * @author ChainCrafts
 * @notice Script to fund a Chainlink VRF subscription with LINK tokens
 * @dev Handles both local (mock) and testnet funding mechanisms
 */
contract FundSubscription is Script, CodeConstants {
    /// @notice Amount of LINK tokens to fund the subscription (3 LINK)
    uint256 public constant FUND_AMOUNT = 3 ether;

    /**
     * @notice Funds a subscription using the current network configuration
     * @dev Retrieves config values and calls fundSubscription
     */
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    /**
     * @notice Funds a VRF subscription with LINK tokens
     * @dev Uses direct mock funding on local chain, transferAndCall on testnets
     * @param vrfCoordinator The address of the VRF Coordinator contract
     * @param subscriptionId The subscription ID to fund
     * @param linkToken The address of the LINK token contract
     * @param account The account to broadcast the transaction from
     */
    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account)
        public
    {
        console.log("funding subscription: ", subscriptionId);
        console.log("using vrfCoordinator: ", vrfCoordinator);
        console.log("on chainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    /**
     * @notice Entry point for the script
     * @dev Calls fundSubscriptionUsingConfig to fund the subscription
     */
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

/**
 * @title AddConsumer
 * @author ChainCrafts
 * @notice Script to add a contract as a consumer to a Chainlink VRF subscription
 * @dev Registers a contract address as an authorized consumer of the VRF subscription
 */
contract AddConsumer is Script {
    /**
     * @notice Adds a consumer using the current network configuration
     * @param mostRecentlyDeployed The address of the contract to add as consumer
     */
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subscriptionId, account);
    }

    /**
     * @notice Adds a contract as a consumer to a VRF subscription
     * @param contractToAddToVrf The address of the contract to add as consumer
     * @param vrfCoordinator The address of the VRF Coordinator contract
     * @param subId The subscription ID to add the consumer to
     * @param account The account to broadcast the transaction from
     */
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("adding consumer contract: ", contractToAddToVrf);
        console.log("to vrf coordinator: ", vrfCoordinator);
        console.log("on chainId: ", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    /**
     * @notice Entry point for the script
     * @dev Uses DevOpsTools to find the most recently deployed Raffle contract
     *      and adds it as a consumer to the VRF subscription
     */
    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
