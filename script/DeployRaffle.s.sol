// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

/**
 * @title DeployRaffle
 * @author ChainCrafts
 * @notice Script to deploy the Raffle contract with all necessary configurations
 * @dev Handles subscription creation, funding, and consumer registration for Chainlink VRF
 */
contract DeployRaffle is Script {
    /**
     * @notice Entry point for the deployment script
     * @dev Calls deployContract() to perform the actual deployment
     */
    function run() public {
        deployContract();
    }

    /**
     * @notice Deploys the Raffle contract with full VRF setup
     * @dev If no subscription exists, creates one, funds it, and adds the Raffle as a consumer
     * @return raffle The deployed Raffle contract instance
     * @return helperConfig The HelperConfig instance with network configuration
     */
    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            //create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            createSubscription.createSubscription(config.vrfCoordinator, config.account);

            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);

        return (raffle, helperConfig);
    }
}
