// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuadraticFundingSplitter
 * @notice Allocation mechanism for distributing vault shares using quadratic funding
 * @dev Implements a decentralized funding distribution with community voting
 */
contract QuadraticFundingSplitter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Project {
        address recipient;
        string name;
        string description;
        uint256 totalVotes;
        uint256 uniqueVoters;
        bool active;
        uint256 totalReceived;
    }

    struct Vote {
        uint256 amount;
        uint256 timestamp;
    }

    /// @notice Mapping from project ID to Project details
    mapping(uint256 => Project) public projects;

    /// @notice Mapping from voter to project ID to vote
    mapping(address => mapping(uint256 => Vote)) public votes;

    /// @notice Total number of projects
    uint256 public projectCount;

    /// @notice Current round ID
    uint256 public currentRound;

    /// @notice Matching pool per round
    mapping(uint256 => uint256) public matchingPools;

    /// @notice Whether the current round is active
    bool public roundActive;

    /// @notice Round start time
    uint256 public roundStartTime;

    /// @notice Round duration
    uint256 public roundDuration;

    /// @notice Minimum vote amount
    uint256 public minVoteAmount;

    /// @notice Vault share token
    IERC20 public vaultToken;

    // Events
    event ProjectRegistered(uint256 indexed projectId, address indexed recipient, string name);
    event VoteCast(address indexed voter, uint256 indexed projectId, uint256 amount);
    event RoundStarted(uint256 indexed roundId, uint256 startTime, uint256 duration);
    event RoundEnded(uint256 indexed roundId, uint256 totalDistributed);
    event FundsDistributed(uint256 indexed projectId, uint256 amount, uint256 matchingAmount);
    event MatchingPoolIncreased(uint256 indexed roundId, uint256 amount);
    event ProjectDeactivated(uint256 indexed projectId);

    // Errors
    error InvalidProject();
    error RoundNotActive();
    error RoundActive();
    error InsufficientAmount();
    error InvalidDuration();
    error NoMatchingPool();

    constructor(address _vaultToken, uint256 _minVoteAmount) Ownable(msg.sender) {
        vaultToken = IERC20(_vaultToken);
        minVoteAmount = _minVoteAmount;
        roundDuration = 30 days;
    }

    /**
     * @notice Register a new project for funding
     * @param recipient Address to receive funds
     * @param name Project name
     * @param description Project description
     */
    function registerProject(
        address recipient,
        string calldata name,
        string calldata description
    ) external returns (uint256 projectId) {
        projectId = projectCount++;

        projects[projectId] = Project({
            recipient: recipient,
            name: name,
            description: description,
            totalVotes: 0,
            uniqueVoters: 0,
            active: true,
            totalReceived: 0
        });

        emit ProjectRegistered(projectId, recipient, name);
    }

    /**
     * @notice Start a new funding round
     * @param duration Duration of the round in seconds
     */
    function startRound(uint256 duration) external onlyOwner {
        if (roundActive) revert RoundActive();
        if (duration == 0) revert InvalidDuration();

        currentRound++;
        roundActive = true;
        roundStartTime = block.timestamp;
        roundDuration = duration;

        emit RoundStarted(currentRound, roundStartTime, duration);
    }

    /**
     * @notice Add funds to the matching pool
     * @param amount Amount of vault shares to add
     */
    function addToMatchingPool(uint256 amount) external {
        vaultToken.safeTransferFrom(msg.sender, address(this), amount);
        matchingPools[currentRound] += amount;

        emit MatchingPoolIncreased(currentRound, amount);
    }

    /**
     * @notice Cast a vote for a project
     * @param projectId Project to vote for
     * @param amount Amount of vault shares to vote with
     */
    function vote(uint256 projectId, uint256 amount) external nonReentrant {
        if (!roundActive) revert RoundNotActive();
        if (projectId >= projectCount) revert InvalidProject();
        if (!projects[projectId].active) revert InvalidProject();
        if (amount < minVoteAmount) revert InsufficientAmount();

        // Transfer voting tokens from voter
        vaultToken.safeTransferFrom(msg.sender, address(this), amount);

        Project storage project = projects[projectId];
        Vote storage userVote = votes[msg.sender][projectId];

        // Track unique voters
        if (userVote.amount == 0) {
            project.uniqueVoters++;
        }

        // Update vote amount
        userVote.amount += amount;
        userVote.timestamp = block.timestamp;
        project.totalVotes += amount;

        emit VoteCast(msg.sender, projectId, amount);
    }

    /**
     * @notice End the current round and distribute funds using quadratic funding
     */
    function endRound() external onlyOwner nonReentrant {
        if (!roundActive) revert RoundNotActive();
        if (block.timestamp < roundStartTime + roundDuration) revert RoundActive();

        roundActive = false;
        uint256 matchingPool = matchingPools[currentRound];
        
        if (matchingPool == 0) revert NoMatchingPool();

        // Calculate quadratic funding allocations
        uint256 totalQuadraticScore = 0;
        uint256[] memory quadraticScores = new uint256[](projectCount);

        // First pass: calculate quadratic scores
        for (uint256 i = 0; i < projectCount; i++) {
            if (projects[i].active) {
                // Quadratic funding: square root of average contribution times number of contributors
                uint256 avgContribution = projects[i].uniqueVoters > 0
                    ? projects[i].totalVotes / projects[i].uniqueVoters
                    : 0;
                
                // Simplified QF: sqrt(votes) * uniqueVoters
                quadraticScores[i] = sqrt(projects[i].totalVotes) * projects[i].uniqueVoters;
                totalQuadraticScore += quadraticScores[i];
            }
        }

        uint256 totalDistributed = 0;

        // Second pass: distribute matching funds proportionally
        for (uint256 i = 0; i < projectCount; i++) {
            if (projects[i].active && quadraticScores[i] > 0) {
                // Direct contributions (votes)
                uint256 directAmount = projects[i].totalVotes;
                
                // Matching amount based on quadratic score
                uint256 matchingAmount = totalQuadraticScore > 0
                    ? (matchingPool * quadraticScores[i]) / totalQuadraticScore
                    : 0;

                uint256 totalAmount = directAmount + matchingAmount;

                if (totalAmount > 0) {
                    vaultToken.safeTransfer(projects[i].recipient, totalAmount);
                    projects[i].totalReceived += totalAmount;
                    totalDistributed += totalAmount;

                    emit FundsDistributed(i, directAmount, matchingAmount);
                }
            }
        }

        emit RoundEnded(currentRound, totalDistributed);
    }

    /**
     * @notice Deactivate a project
     * @param projectId Project to deactivate
     */
    function deactivateProject(uint256 projectId) external onlyOwner {
        if (projectId >= projectCount) revert InvalidProject();
        projects[projectId].active = false;
        emit ProjectDeactivated(projectId);
    }

    /**
     * @notice Get project details
     * @param projectId Project ID
     */
    function getProject(uint256 projectId) external view returns (Project memory) {
        return projects[projectId];
    }

    /**
     * @notice Get user's vote for a project
     * @param voter Voter address
     * @param projectId Project ID
     */
    function getVote(address voter, uint256 projectId) external view returns (Vote memory) {
        return votes[voter][projectId];
    }

    /**
     * @notice Calculate square root (Babylonian method)
     * @param x Number to find square root of
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @notice Update minimum vote amount
     * @param _minVoteAmount New minimum vote amount
     */
    function setMinVoteAmount(uint256 _minVoteAmount) external onlyOwner {
        minVoteAmount = _minVoteAmount;
    }

    /**
     * @notice Check if round has ended
     */
    function hasRoundEnded() external view returns (bool) {
        return roundActive && block.timestamp >= roundStartTime + roundDuration;
    }
}
