// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    //VRF mock values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // link/eth price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;


    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig is CodeConstants, Script{
    error  HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 enteranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 subscriptionId;
    }
    NetworkConfig public localNetworkConfig;
    mapping (uint256 chainId => NetworkConfig ) networkConfigs;

    constructor (){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainID(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        }else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilEthConfig();

        }else{
            revert HelperConfig__InvalidChainId();
        }
    }


    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            enteranceFee : 0.01 ether, //10e16
            interval : 30, //every 30 second
            vrfCoordinator : 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit : 500000, //500,000
            subscriptionId : 0
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        //check to see if we have an active networkk config
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }
        //if we don't have then we need to deploy mocks and such

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UNIT_LINK);
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            enteranceFee : 0.01 ether, //10e16
            interval : 30, //every 30 second
            vrfCoordinator : address(vrfCoordinatorMock),
            
            // gasLane does not matter it will work in our mock anyways!
            gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit : 500000, //500,000
            subscriptionId : 0
        });
    }

}