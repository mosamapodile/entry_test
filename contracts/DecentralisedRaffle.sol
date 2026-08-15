// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DecentralisedRaffle
 * @dev A raffle contract with a circuit breaker and a fair payout split
 * @notice PART 2 - Decentralised Raffle (MANDATORY)
 *
 * ---------------------------------------------------------------------------
 * IMPORTANT: THE AUTO-MARKER CALLS THESE EXACT FUNCTION AND EVENT SIGNATURES.
 * Do not rename them, reorder their parameters, or change their return types.
 * You may add anything you like alongside them.
 * ---------------------------------------------------------------------------
 */
contract DecentralisedRaffle {
    // --- Events (the marker checks these are emitted) ---

    event RaffleEntered(address indexed player, uint256 entryCount);
    event WinnerSelected(uint256 indexed raffleId, address indexed winner, uint256 prize);
    event RafflePaused();
    event RaffleUnpaused();

    /// @notice The minimum a player must send for one entry
    uint256 public constant MINIMUM_ENTRY = 0.01 ether;

    /// @notice How long the raffle must run before a winner can be drawn
    uint256 public constant RAFFLE_DURATION = 24 hours;

    address public owner;
    uint256 public raffleId;
    uint256 public raffleStartTime;
    bool public isPaused;

    // State Variables
    address[] private players;
    mapping(address => uint256) private playerEntries;
    uint256 private uniquePlayerCount;

    constructor() {
        owner = msg.sender;
        raffleId = 1;
        raffleStartTime = block.timestamp;
        isPaused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    // -----------------------------------------------------------------------
    // TODO 1: enterRaffle
    // -----------------------------------------------------------------------
    function enterRaffle() external payable whenNotPaused {
        require(msg.value >= MINIMUM_ENTRY, "Entry fee below minimum");

        if (playerEntries[msg.sender] == 0) {
            uniquePlayerCount++;
        }

        players.push(msg.sender);
        playerEntries[msg.sender]++;

        emit RaffleEntered(msg.sender, playerEntries[msg.sender]);
    }

    // -----------------------------------------------------------------------
    // TODO 2: selectWinner
    // -----------------------------------------------------------------------
    function selectWinner() external onlyOwner {
        require(block.timestamp >= raffleStartTime + RAFFLE_DURATION, "Raffle duration not met");
        require(uniquePlayerCount >= 3, "At least 3 unique players required");

        // Pseudo-random index selection
        uint256 winningIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length))
        ) % players.length;

        address winner = players[winningIndex];

        uint256 totalPot = address(this).balance;
        uint256 prize = (totalPot * 90) / 100;
        uint256 ownerFee = totalPot - prize;

        emit WinnerSelected(raffleId, winner, prize);

        // Reset state for next round
        raffleId++;
        raffleStartTime = block.timestamp;

        for (uint256 i = 0; i < players.length; i++) {
            playerEntries[players[i]] = 0;
        }
        delete players;
        uniquePlayerCount = 0;

        // Payout transfers
        (bool successWinner, ) = winner.call{value: prize}("");
        require(successWinner, "Winner transfer failed");

        (bool successOwner, ) = owner.call{value: ownerFee}("");
        require(successOwner, "Owner transfer failed");
    }

    // -----------------------------------------------------------------------
    // TODO 3: Circuit breaker
    // -----------------------------------------------------------------------
    function pause() external onlyOwner {
        require(!isPaused, "Already paused");
        isPaused = true;
        emit RafflePaused();
    }

    function unpause() external onlyOwner {
        require(isPaused, "Not paused");
        isPaused = false;
        emit RaffleUnpaused();
    }

    // -----------------------------------------------------------------------
    // TODO 4: View functions (the marker calls all four)
    // -----------------------------------------------------------------------

    /// @notice The current pot, in wei
    function getPot() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice How many entries this player has bought this round
    function getEntryCount(address player) external view returns (uint256) {
        return playerEntries[player];
    }

    /// @notice Total number of entries this round, counting repeats
    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    /// @notice Number of distinct addresses that have entered this round
    function getUniquePlayerCount() external view returns (uint256) {
        return uniquePlayerCount;
    }
}