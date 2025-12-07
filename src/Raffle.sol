// Contract Layout:
// 1. Version
// 2. Imports
// 3. Errors
// 4. Interfaces, Libraries, Contracts
// 5. Type Declarations
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Functions

// Function Layout:
// 1. Constructor
// 2. Receive function (if exists)
// 3. Fallback function (if exists)
// 4. External functions
// 5. Public functions
// 6. Internal functions
// 7. Private functions
// 8. View and pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample raffle contract
 * @author ChainCrafts
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * Errors
     */
    error Raffle__sendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLenght, uint256 raffleState);

    /* type decleratioin */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /*state variables */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint8 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_enteranceFee;
    address payable[] private s_players;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /**
     * @dev the duration of the lottary in seconds
     */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 enteranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_enteranceFee = enteranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //require(msg.value>= i_enteranceFee,"not enough ETH sent!");
        if (msg.value < i_enteranceFee) {
            revert Raffle__sendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // for sol version >0.8.26 only works in via-IR:
        //require(msg.value> i_enteranceFee, sendMoreToEnterRaffle());
        s_players.push(payable(msg.sender));
        // whenever we update a storage var we need to emit an event
        emit RaffleEntered(msg.sender);
    }

    // 1. get a random number
    // 2. use that random number to pick a winner
    // 3. be automatically called

    //when the winner should be picked?
    /**
     * @dev this is the function that chainlink nodes will call to see if
     * the lottary is ready to have a winner picked
     * The following should be true in order to ```updateneeded``` be true:
     * 1. The time interval has passed between the raffle runs.
     * 2. Lottery is open
     * 3. Contract has ETH (has balance and that means it has players)
     * 4. Implicitly your subscription has link
     * @param - ignored
     * @return updateNeeded true if it is time to start a new lottary
     * @return
     */
    function checkUpkeeper(
        bytes memory /*checkData */
    )
        public
        view
        returns (
            bool updateNeeded,
            bytes memory /*performData */
        )
    {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        updateNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (updateNeeded, hex"");
    }

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        // the first thing we need to know is to check to see if enough time has passed
        // if (block.timestamp - s_lastTimeStamp < i_interval) {
        //     revert();
        // }
        (bool upkeepNeeded,) = checkUpkeeper("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATION,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_OF_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        /* uint256 requestId = */
        s_vrfCoordinator.requestRandomWords(request);
    }

    //CEI : Checks, Effects, Interactions
    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    )
        internal
        override
    {
        //1.checks
        //2.effects (Update State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner); //emit should be before any external call or Interaction

        //3.Interactions (External Calls)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        // 4. Protocol Invariants (The Safety Net)
    }

    /**
     * getter functions
     */
    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }
}
