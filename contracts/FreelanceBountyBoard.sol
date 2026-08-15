// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title FreelanceBountyBoard
 * @dev A decentralised marketplace for skills and bounties
 * @notice PART 1 - Freelance Bounty Board (MANDATORY)
 *
 * ---------------------------------------------------------------------------
 * IMPORTANT: THE AUTO-MARKER CALLS THESE EXACT FUNCTION AND EVENT SIGNATURES.
 * Do not rename them, reorder their parameters, or change their return types.
 * You may add anything you like alongside them.
 * ---------------------------------------------------------------------------
 */
contract FreelanceBountyBoard {
    /// @notice Open = posted, Submitted = work handed in, Completed = paid
    enum Status {
        Open,
        Submitted,
        Completed
    }

    struct Freelancer {
        string skill;
        bool registered;
    }

    struct Bounty {
        address employer;
        string description;
        string skillRequired;
        uint256 amount;
        Status status;
    }

    // --- Events (the marker checks these are emitted) ---

    event FreelancerRegistered(address indexed freelancer, string skill);
    event BountyPosted(uint256 indexed bountyId, address indexed employer, uint256 amount);
    event AppliedForBounty(uint256 indexed bountyId, address indexed freelancer);
    event WorkSubmitted(uint256 indexed bountyId, address indexed freelancer, string submissionUrl);
    event BountyPaid(uint256 indexed bountyId, address indexed freelancer, uint256 amount);

    address public owner;

    /// @notice Total number of bounties ever posted. The first bounty has id 1.
    uint256 public bountyCount;

    // State Mappings
    mapping(address => Freelancer) private freelancers;
    mapping(uint256 => Bounty) private bounties;
    mapping(uint256 => mapping(address => bool)) private applications;

    constructor() {
        owner = msg.sender;
    }

    // -----------------------------------------------------------------------
    // TODO 1: registerFreelancer
    // -----------------------------------------------------------------------
    function registerFreelancer(string calldata skill) external {
        require(!freelancers[msg.sender].registered, "Already registered");
        require(bytes(skill).length > 0, "Skill cannot be empty");

        freelancers[msg.sender] = Freelancer({
            skill: skill,
            registered: true
        });

        emit FreelancerRegistered(msg.sender, skill);
    }

    // -----------------------------------------------------------------------
    // TODO 2: postBounty
    // -----------------------------------------------------------------------
    function postBounty(string calldata description, string calldata skillRequired)
        external
        payable
        returns (uint256)
    {
        // To be implemented in Commit 2
    }

    // -----------------------------------------------------------------------
    // TODO 3: applyForBounty
    // -----------------------------------------------------------------------
    function applyForBounty(uint256 bountyId) external {
        // To be implemented in Commit 2
    }

    // -----------------------------------------------------------------------
    // TODO 4: submitWork
    // -----------------------------------------------------------------------
    function submitWork(uint256 bountyId, string calldata submissionUrl) external {
        // To be implemented in Commit 3
    }

    // -----------------------------------------------------------------------
    // TODO 5: approveAndPay
    // -----------------------------------------------------------------------
    function approveAndPay(uint256 bountyId, address freelancer) external {
        // To be implemented in Commit 3
    }

    // -----------------------------------------------------------------------
    // TODO 6: View functions (the marker calls all four)
    // -----------------------------------------------------------------------

    /// @notice True if this address has registered as a freelancer
    function isRegistered(address freelancer) external view returns (bool) {
        return freelancers[freelancer].registered;
    }

    /// @notice The skill this freelancer registered with ("" if unregistered)
    function getSkill(address freelancer) external view returns (string memory) {
        return freelancers[freelancer].skill;
    }

    /// @notice True if this freelancer applied for this bounty
    function hasApplied(uint256 bountyId, address freelancer) external view returns (bool) {
        return applications[bountyId][freelancer];
    }

    /// @notice All of a bounty's details, in this exact order
    function getBounty(uint256 bountyId)
        external
        view
        returns (
            address employer,
            string memory description,
            string memory skillRequired,
            uint256 amount,
            Status status
        )
    {
        Bounty memory b = bounties[bountyId];
        return (b.employer, b.description, b.skillRequired, b.amount, b.status);
    }
}