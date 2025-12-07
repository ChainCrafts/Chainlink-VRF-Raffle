// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            //create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            createSubscription.createSubscription(config.vrfCoordinator);

            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);


        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.enteranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);


        return(raffle, helperConfig);
    }
}

// pragma solidity ^0.8.26;

// import {FundMe} from "../src/FundMe.sol";
// import {Script} from "forge-std/Script.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";

// contract DeployFundMe is Script {
//     function run() external returns (FundMe) {
//         //anything before start broadcast is not a transaction
//         HelperConfig helperConfig = new HelperConfig();
//         address EthUsdPriceFeed = helperConfig.activeNetworkConfig();
//         vm.startBroadcast(); //anything after startBroadcast is a real transaction
//         (FundMe fundMe) = new FundMe(EthUsdPriceFeed);
//         vm.stopBroadcast();
//         return fundMe;
//     }
// }
