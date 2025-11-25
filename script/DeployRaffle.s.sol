// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";


contract DeployRaffle is Script{
    function run() public{

    }

    //function deployRaffel() public returns(Raffle, HelperConfig){}
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
