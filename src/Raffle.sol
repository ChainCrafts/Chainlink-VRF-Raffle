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
pragma solidity ^0.8.26;
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

/**
 * @title A sample raffle contract
 * @author ChainCrafts
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5 with security features (ReentrancyGuard, Pausable, Owner withdraw)
 */
contract Raffle is VRFConsumerBaseV2Plus, ReentrancyGuard {
    /**
     * Errors
     */
    error Raffle__sendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);
    error Raffle__OnlyOwner();
    error Raffle__RafflePaused();
    error Raffle__NoFundsToWithdraw();
    error Raffle__CannotWithdrawDuringActiveRaffle();

    /* type declaration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /*state variables */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint8 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /**
     * @dev the duration of the lottery in seconds
     */
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    address private immutable i_owner;
    bool private s_paused;

    /**
     * @notice Emitted when a player enters the raffle
     */
    event RaffleEntered(address indexed player);
    /**
     * @notice Emitted when a winner is picked and paid
     */
    event WinnerPicked(address indexed winner);
    /**
     * @notice Emitted when a random winner request is sent to Chainlink VRF
     */
    event RequestedRaffleWinner(uint256 indexed requestId);
    /**
     * @notice Emitted when the raffle is paused
     */
    event RafflePaused(address indexed by);
    /**
     * @notice Emitted when the raffle is unpaused
     */
    event RaffleUnpaused(address indexed by);
    /**
     * @notice Emitted when emergency withdrawal is performed
     */
    event EmergencyWithdraw(address indexed owner, uint256 amount);

    /**
     * @notice Creates a new Raffle contract
     * @param entranceFee The minimum ETH required to enter the raffle
     * @param interval The duration of the lottery in seconds
     * @param vrfCoordinator The address of the Chainlink VRF Coordinator
     * @param gasLane The key hash for the VRF gas lane
     * @param subscriptionId The Chainlink VRF subscription ID
     * @param callbackGasLimit The gas limit for the VRF callback
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_owner = msg.sender;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        s_paused = false;
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the raffle contract owner
     */
    modifier onlyRaffleOwner() {
        if (msg.sender != i_owner) {
            revert Raffle__OnlyOwner();
        }
        _;
    }

    /**
     * @notice Ensures the contract is not paused
     */
    modifier whenNotPaused() {
        if (s_paused) {
            revert Raffle__RafflePaused();
        }
        _;
    }

    /**
     * @notice Allows a user to enter the raffle by paying the entrance fee
     * @dev Reverts if not enough ETH is sent or if the raffle is not open
     */
    function enterRaffle() external payable whenNotPaused {
        //require(msg.value>= i_entranceFee,"not enough ETH sent!");
        if (msg.value < i_entranceFee) {
            revert Raffle__sendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // for sol version >0.8.26 only works in via-IR:
        //require(msg.value> i_entranceFee, sendMoreToEnterRaffle());
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
     * the lottery is ready to have a winner picked
     * The following should be true in order to ```updateneeded``` be true:
     * 1. The time interval has passed between the raffle runs.
     * 2. Lottery is open
     * 3. Contract has ETH (has balance and that means it has players)
     * 4. Implicitly your subscription has link
     * @param - ignored
     * @return updateNeeded true if it is time to start a new lottery
     * @return
     */
    function checkUpkeep(
        bytes memory /*checkData */
    )
        public
        view
        returns (
            bool updateNeeded,
            bytes memory /*performData */
        )
    {
        // bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        // bool isOpen = s_raffleState == RaffleState.OPEN;
        // bool hasBalance = address(this).balance > 0;
        // bool hasPlayers = s_players.length > 0;

        // updateNeeded = isOpen && timeHasPassed && hasBalance && hasPlayers;

        updateNeeded = (s_raffleState == RaffleState.OPEN) && (block.timestamp - s_lastTimeStamp >= i_interval)
            && (address(this).balance > 0) && (s_players.length > 0); //more gas Optimized way

        return (updateNeeded, hex"");
    }

    /**
     * @notice Performs the upkeep by requesting a random winner from Chainlink VRF
     * @dev Called by Chainlink Automation when checkUpkeep returns true
     * @dev Reverts with Raffle__UpkeepNotNeeded if conditions are not met
     */
    function performUpkeep(
        bytes calldata /* performData */
    )
        external
        whenNotPaused
    {
        // the first thing we need to know is to check to see if enough time has passed
        // if (block.timestamp - s_lastTimeStamp < i_interval) {
        //     revert();
        // }
        (bool upkeepNeeded,) = checkUpkeep("");
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
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @notice Callback function called by Chainlink VRF with the random number
     * @dev Follows CEI (Checks, Effects, Interactions) pattern
     * @dev Picks a winner, resets the raffle, and sends the prize
     * @dev Protected by nonReentrant modifier for extra security
     * @param randomWords Array containing the random number(s) from Chainlink VRF
     */
    function fulfillRandomWords(
        uint256,
        /*requestId*/
        uint256[] calldata randomWords
    )
        internal
        override
        nonReentrant
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

    /*//////////////////////////////////////////////////////////////
                           OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses the raffle, preventing new entries and upkeep
     * @dev Can only be called by the owner
     */
    function pause() external onlyRaffleOwner {
        s_paused = true;
        emit RafflePaused(msg.sender);
    }

    /**
     * @notice Unpauses the raffle, allowing normal operation
     * @dev Can only be called by the owner
     */
    function unpause() external onlyRaffleOwner {
        s_paused = false;
        emit RaffleUnpaused(msg.sender);
    }

    /**
     * @notice Emergency withdrawal of funds by owner
     * @dev Can only be called when there are no active players to prevent fund loss
     * @dev This is a safety mechanism for stuck funds or emergency situations
     */
    function emergencyWithdraw() external onlyRaffleOwner nonReentrant {
        if (s_players.length > 0) {
            revert Raffle__CannotWithdrawDuringActiveRaffle();
        }
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert Raffle__NoFundsToWithdraw();
        }

        emit EmergencyWithdraw(msg.sender, balance);

        (bool success,) = payable(i_owner).call{value: balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the entrance fee required to enter the raffle
     * @return The entrance fee in wei
     */
    function getentranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    /**
     * @notice Returns the current state of the raffle
     * @return The current RaffleState (OPEN or CALCULATING)
     */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    /**
     * @notice Returns the address of a player at the given index
     * @param index The index of the player in the players array
     * @return The address of the player
     */
    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    /**
     * @notice Returns the total number of players in the current raffle
     * @return The number of players
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    /**
     * @notice Returns the timestamp of when the last winner was picked
     * @return The last timestamp in seconds
     */
    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    /**
     * @notice Returns the address of the most recent winner
     * @return The winner's address
     */
    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    /**
     * @notice Returns the Chainlink VRF subscription ID
     * @return The subscription ID
     */
    function getSubscriptionId() external view returns (uint256) {
        return i_subscriptionId;
    }

    /**
     * @notice Returns the owner address
     * @return The owner's address
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }

    /**
     * @notice Returns whether the raffle is paused
     * @return True if paused, false otherwise
     */
    function isPaused() external view returns (bool) {
        return s_paused;
    }
}
