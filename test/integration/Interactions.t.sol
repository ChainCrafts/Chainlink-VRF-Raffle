// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract InteractionsTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    address account;
    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        link = config.link;
        account = config.account;
    }

    /*/////////////////////////////////////////////////////
                    INTERACTION TESTS
    /////////////////////////////////////////////////////*/

    function testUserCanCreateSubscription() public skipFork {
        // TODO: Implement this test
        // 1. Create a new instance of the CreateSubscription script
        // 2. Call the createSubscription function (using the config values)
        // 3. Assert that the returned subscriptionId is not 0
        // 4. (Optional) Check if the subscription actually exists on the vrfCoordinator
        CreateSubscription createSub = new CreateSubscription();
        (uint256 subId, address returnedVrfCoordinator) = createSub
            .createSubscription(vrfCoordinator, account);
        assert(subId > 0);

        // Optional: Verify the subscription exists on the VRF Coordinator
        (, , , address subOwner, ) = VRFCoordinatorV2_5Mock(
            returnedVrfCoordinator
        ).getSubscription(subId);
        assert(subOwner != address(0));
    }

    function testUserCanFundSubscription() public skipFork {
        // TODO: Implement this test
        // 1. Create a new instance of the FundSubscription script
        // 2. Call the fundSubscription function
        // 3. Assert that the subscription balance has increased (you might need to mock the coordinator or check logs)
        // Note: This might be tricky on a local chain vs a fork, consider how your script handles it.
        CreateSubscription createSub = new CreateSubscription();
        (uint256 subId, ) = createSub.createSubscription(
            vrfCoordinator,
            account
        );
        (uint96 balanceBefore, , , , ) = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .getSubscription(subId);
        FundSubscription fundSub = new FundSubscription();
        fundSub.fundSubscription(vrfCoordinator, subId, link, account);
        (uint96 balanceAfter, , , , ) = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .getSubscription(subId);

        assert(uint256(balanceAfter - balanceBefore) == fundSub.FUND_AMOUNT());
    }

    function testUserCanAddConsumer() public skipFork {
        // TODO: Implement this test
        // 1. Create a new instance of the AddConsumer script
        // 2. Call the addConsumer function to add the 'raffle' contract to the subscription
        // 3. Assert that the raffle contract is now a valid consumer on the vrfCoordinator
        AddConsumer addConsumer = new AddConsumer();

        CreateSubscription createSub = new CreateSubscription();
        (uint256 subId, ) = createSub.createSubscription(
            vrfCoordinator,
            account
        );
        FundSubscription fundSub = new FundSubscription();
        fundSub.fundSubscription(vrfCoordinator, subId, link, account);

        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subId,
            account
        );

        bool isConsumer = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .consumerIsAdded(subId, address(raffle));

        assert(isConsumer);
    }

    function testDeployRaffleCreatesFullSetup() public skipFork {
        // Verify the raffle contract was deployed
        assert(address(raffle) != address(0));

        // Verify raffle is in OPEN state
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);

        // Verify entrance fee is set correctly
        assert(raffle.getentranceFee() == entranceFee);

        // Get the subscription ID from the raffle (need to check if raffle is added as consumer)
        // The deployment script should have created a subscription, funded it, and added raffle as consumer
        uint256 raffleSubId = raffle.getSubscriptionId();

        // Verify the subscription exists and has balance
        (uint96 balance, , , address subOwner, ) = VRFCoordinatorV2_5Mock(
            vrfCoordinator
        ).getSubscription(raffleSubId);
        assert(subOwner != address(0));
        assert(balance > 0);

        // Verify raffle is a consumer of the subscription
        bool isConsumer = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .consumerIsAdded(raffleSubId, address(raffle));
        assert(isConsumer);
    }

    function testUserCanEnterRaffleAndWinnerIsSelected() public skipFork {
        // Arrange - Create players
        address player1 = makeAddr("player1");
        address player2 = makeAddr("player2");
        address player3 = makeAddr("player3");

        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.deal(player3, 1 ether);

        // Record balances before entering
        uint256 player1BalanceBefore = player1.balance;
        uint256 player2BalanceBefore = player2.balance;
        uint256 player3BalanceBefore = player3.balance;

        // Act - Players enter the raffle
        vm.prank(player1);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(player2);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(player3);
        raffle.enterRaffle{value: entranceFee}();

        // Verify players entered
        assert(raffle.getNumberOfPlayers() == 3);

        // Calculate total prize
        uint256 totalPrize = entranceFee * 3;

        // Time passes
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Perform upkeep (request random number)
        vm.recordLogs();
        raffle.performUpkeep("");

        // Get the request ID from logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Raffle should be in CALCULATING state
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        // Fulfill randomness (simulate Chainlink VRF callback)
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        // Assert - Winner is selected and paid
        address winner = raffle.getRecentWinner();
        assert(winner == player1 || winner == player2 || winner == player3);

        // Get the winner's balance before they entered
        uint256 winnerBalanceBefore;
        if (winner == player1) {
            winnerBalanceBefore = player1BalanceBefore;
        } else if (winner == player2) {
            winnerBalanceBefore = player2BalanceBefore;
        } else {
            winnerBalanceBefore = player3BalanceBefore;
        }

        // Winner should have: (initial balance - entrance fee) + total prize
        uint256 expectedWinnerBalance = winnerBalanceBefore -
            entranceFee +
            totalPrize;
        assert(winner.balance == expectedWinnerBalance);

        // Raffle should be back to OPEN state
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);

        // Players array should be reset
        assert(raffle.getNumberOfPlayers() == 0);
    }
}
