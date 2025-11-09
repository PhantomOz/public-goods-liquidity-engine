// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {QuadraticFundingSplitter} from "../src/QuadraticFundingSplitter.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interactive Demo Script
 * @notice Provides individual functions for judges to interact with the platform
 * @dev Each function represents a specific user action that can be called independently
 * 
 * USAGE:
 * ======
 * 1. Get DAI: forge script script/Interactive.s.sol --sig "getDai()" --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 2. Deposit: forge script script/Interactive.s.sol --sig "depositToVault(uint256)" 1000000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 3. Deploy: forge script script/Interactive.s.sol --sig "deployToStrategies(uint256)" 800000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 4. Harvest: forge script script/Interactive.s.sol --sig "harvestYield()" --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 5. Register: forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x1111... "Name" --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 6. Start Round: forge script script/Interactive.s.sol --sig "startRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 7. Vote: forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 0 50000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 8. End Round: forge script script/Interactive.s.sol --sig "endRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 9. Distribute: forge script script/Interactive.s.sol --sig "distribute(uint256)" 1 --rpc-url $TENDERLY_RPC --broadcast --legacy
 * 10. Check Stats: forge script script/Interactive.s.sol --sig "viewStats()" --rpc-url $TENDERLY_RPC
 */
contract Interactive is Script {
    // Deployed contract addresses (Tenderly Fork)
    address constant VAULT = 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680;
    address constant SPLITTER = 0x35391ca5F9bEb7f4488671fCbad0Ee709603Fec4;
    address constant AGGREGATOR = 0x11515c43c025016d2ac8d627889c721ef7042317;
    uint256 constant DEMO_ROUND_DURATION = 7 days;
    
    // Token addresses (Mainnet)
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WHALE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf; // DAI whale
    
    // ============================================
    // USER ACTIONS - GETTING STARTED
    // ============================================
    
    /**
     * @notice Get DAI tokens from a whale for testing
     * @dev Impersonates a DAI whale and transfers 10,000 DAI to caller
     */
    function getDai() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Get DAI for Testing");
        console.log("==========================================");
        console.log("");
        console.log("User:", user);
        
        // Impersonate whale
        vm.startPrank(WHALE);
        
        // Transfer 10,000 DAI
        IERC20(DAI).transfer(user, 10_000 * 1e18);
        
        vm.stopPrank();
        
        uint256 balance = IERC20(DAI).balanceOf(user);
        console.log("DAI received:", balance / 1e18, "DAI");
        console.log("");
        console.log("Success! You now have DAI to deposit.");
    }
    
    /**
     * @notice Check your current balances
     * @dev View DAI and pgDAI (vault shares) balance
     */
    function checkBalance() external view {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("Your Balances");
        console.log("==========================================");
        console.log("");
        console.log("Address:", user);
        
        uint256 daiBalance = IERC20(DAI).balanceOf(user);
        console.log("DAI Balance:", daiBalance / 1e18, "DAI");
        
        uint256 pgDaiBalance = IERC20(VAULT).balanceOf(user);
        console.log("pgDAI Balance:", pgDaiBalance / 1e18, "pgDAI");
        
        // Check allowance
        uint256 allowance = IERC20(DAI).allowance(user, VAULT);
        console.log("Vault Allowance:", allowance / 1e18, "DAI");
        console.log("");
    }
    
    // ============================================
    // USER ACTIONS - VAULT INTERACTIONS
    // ============================================
    
    /**
     * @notice Deposit DAI into the vault
     * @param amount Amount of DAI to deposit (in wei, e.g., 1000000000000000000000 for 1000 DAI)
     * @dev Approves vault and deposits DAI, receives pgDAI shares
     */
    function depositToVault(uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address user = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Deposit to Vault");
        console.log("==========================================");
        console.log("");
        console.log("Amount:", amount / 1e18, "DAI");
        
        // Check balance
        uint256 balance = IERC20(DAI).balanceOf(user);
        require(balance >= amount, "Insufficient DAI balance");
        
        // Approve vault
        IERC20(DAI).approve(VAULT, amount);
        console.log("Approved vault to spend", amount / 1e18, "DAI");
        
        // Deposit
        uint256 sharesBefore = IERC20(VAULT).balanceOf(user);
        PublicGoodsVault(VAULT).deposit(amount, user);
        uint256 sharesAfter = IERC20(VAULT).balanceOf(user);
        
        uint256 sharesReceived = sharesAfter - sharesBefore;
        console.log("Received", sharesReceived / 1e18, "pgDAI shares");
        console.log("");
        console.log("Success! Your deposit is earning yield for public goods.");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Withdraw DAI from the vault
     * @param shares Amount of pgDAI shares to redeem (in wei)
     * @dev Burns pgDAI shares and receives DAI back
     */
    function withdrawFromVault(uint256 shares) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address user = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Withdraw from Vault");
        console.log("==========================================");
        console.log("");
        console.log("Shares to redeem:", shares / 1e18, "pgDAI");
        
        uint256 daiBefore = IERC20(DAI).balanceOf(user);
        PublicGoodsVault(VAULT).redeem(shares, user, user);
        uint256 daiAfter = IERC20(DAI).balanceOf(user);
        
        uint256 daiReceived = daiAfter - daiBefore;
        console.log("Received", daiReceived / 1e18, "DAI");
        console.log("");
        console.log("Success! Your principal has been withdrawn.");
        
        vm.stopBroadcast();
    }
    
    // ============================================
    // KEEPER ACTIONS - YIELD MANAGEMENT
    // ============================================
    
    /**
     * @notice Deploy idle vault funds to yield strategies
     * @param amount Amount of DAI to deploy to strategies (in wei)
     * @dev Splits funds between Aave and Spark based on allocation
     */
    function deployToStrategies(uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Deploy to Yield Strategies");
        console.log("==========================================");
        console.log("");
        console.log("Amount:", amount / 1e18, "DAI");
        
        PublicGoodsVault(VAULT).depositToStrategies(amount);
        
        console.log("");
        console.log("Success! Funds are now generating yield.");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Harvest accumulated yield from strategies
     * @dev Collects yield from Aave and Spark, converts to pgDAI shares for splitter
     */
    function harvestYield() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Harvest Yield");
        console.log("==========================================");
        console.log("");
        
        uint256 splitterBalanceBefore = IERC20(VAULT).balanceOf(SPLITTER);
        
        PublicGoodsVault(VAULT).harvest();
        
        uint256 splitterBalanceAfter = IERC20(VAULT).balanceOf(SPLITTER);
        uint256 yieldHarvested = splitterBalanceAfter - splitterBalanceBefore;
        
        console.log("Yield harvested:", yieldHarvested / 1e18, "pgDAI");
        console.log("Splitter balance:", splitterBalanceAfter / 1e18, "pgDAI");
        console.log("");
        console.log("Success! Yield is ready for distribution.");
        
        vm.stopBroadcast();
    }

    /**
     * @notice Initialize harvest baseline so the first harvest does not revert
     * @dev Keeper should call this right after the initial deposits are in place
     */
    function initializeHarvest() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("==========================================");
        console.log("ACTION: Initialize Harvest");
        console.log("==========================================");
        console.log("");

        uint256 totalAssetsBefore = PublicGoodsVault(VAULT).totalAssets();
        console.log("Total assets baseline:", totalAssetsBefore / 1e18, "DAI");

        PublicGoodsVault(VAULT).initializeHarvest();

        console.log("Initialization complete. Vault can harvest once yield accrues.");

        vm.stopBroadcast();
    }
    
    /**
     * @notice Withdraw funds from strategies back to vault
     * @param amount Amount to withdraw (in wei)
     * @dev Useful for rebalancing or emergency situations
     */
    function withdrawFromStrategies(uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Withdraw from Strategies");
        console.log("==========================================");
        console.log("");
        console.log("Amount:", amount / 1e18, "DAI");
        
        PublicGoodsVault(VAULT).withdrawFromStrategies(amount);
        
        console.log("Success! Funds withdrawn to vault.");
        
        vm.stopBroadcast();
    }
    
    // ============================================
    // PROJECT ACTIONS - QUADRATIC FUNDING
    // ============================================
    
    /**
     * @notice Register a new public goods project
     * @param projectAddress Recipient address for the project
     * @param projectName Name of the project
     * @dev Anyone can register a project for funding consideration
     */
    function registerProject(address projectAddress, string memory projectName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Register Project");
        console.log("==========================================");
        console.log("");
        console.log("Project:", projectName);
        console.log("Address:", projectAddress);
        
        QuadraticFundingSplitter(SPLITTER).registerProject(projectAddress, projectName, "");
        
        uint256 newProjectCount = QuadraticFundingSplitter(SPLITTER).projectCount();
        console.log("");
        console.log("Success! Project registered as ID:", newProjectCount - 1);
        console.log("Total projects:", newProjectCount);
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice View all registered projects
     * @dev Lists all projects with their IDs and addresses
     */
    function listProjects() external view {
        console.log("==========================================");
        console.log("Registered Projects");
        console.log("==========================================");
        console.log("");
        
        uint256 count = QuadraticFundingSplitter(SPLITTER).projectCount();
        console.log("Total projects:", count);
        console.log("");
        
        for (uint256 i = 0; i < count; i++) {
            (address recipient, string memory name, , , , , ) = 
                QuadraticFundingSplitter(SPLITTER).projects(i);
            console.log("ID", i, ":", name);
            console.log("  Address:", recipient);
        }
        console.log("");
    }
    
    // ============================================
    // FUNDING ROUND ACTIONS
    // ============================================
    
    /**
     * @notice Start a new funding round
     * @dev Only owner can start rounds, requires duration in seconds
     */
    function startRound() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Start Funding Round");
        console.log("==========================================");
        console.log("");
        
        // Start round with 7 days duration (for demo)
        QuadraticFundingSplitter(SPLITTER).startRound(7 days);
        
        uint256 newCurrentRound = QuadraticFundingSplitter(SPLITTER).currentRound();
        console.log("Round", newCurrentRound, "started!");
        console.log("");
        console.log("Community can now vote for projects.");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Add funds to the matching pool
     * @param amount Amount of pgDAI to add to matching pool (in wei)
     * @dev This increases the total funds available for distribution
     */
    function addToMatchingPool(uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Add to Matching Pool");
        console.log("==========================================");
        console.log("");
        console.log("Amount:", amount / 1e18, "pgDAI");
        
        // Approve and add to matching pool
        IERC20(VAULT).approve(SPLITTER, amount);
        QuadraticFundingSplitter(SPLITTER).addToMatchingPool(amount);
        
        uint256 currentRoundId = QuadraticFundingSplitter(SPLITTER).currentRound();
        uint256 poolAmount = QuadraticFundingSplitter(SPLITTER).matchingPools(currentRoundId);
        
        console.log("");
        console.log("Success! Matching pool increased.");
        console.log("Total matching pool:", poolAmount / 1e18, "pgDAI");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Vote for a project with pgDAI tokens
     * @param projectId ID of the project to vote for
     * @param amount Amount of pgDAI to vote with (in wei)
     * @dev Quadratic funding formula applied during distribution
     */
    function vote(uint256 projectId, uint256 amount) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Vote for Project");
        console.log("==========================================");
        console.log("");
        console.log("Project ID:", projectId);
        console.log("Vote amount:", amount / 1e18, "pgDAI");
        
        // Approve splitter
        IERC20(VAULT).approve(SPLITTER, amount);
        
        QuadraticFundingSplitter(SPLITTER).vote(projectId, amount);
        
        // Get updated project stats
        (,, , uint256 totalVotes, , , ) = QuadraticFundingSplitter(SPLITTER).projects(projectId);
        
        console.log("");
        console.log("Success! Your vote has been recorded.");
        console.log("Project total votes:", totalVotes / 1e18, "pgDAI");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice End the current funding round and calculate scores
     * @dev Applies quadratic funding formula and automatically distributes funds
     */
    function endRound() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: End Funding Round");
        console.log("==========================================");
        console.log("");
        
        uint256 currentRoundId = QuadraticFundingSplitter(SPLITTER).currentRound();
        
        QuadraticFundingSplitter(SPLITTER).endRound();
        
        console.log("Round", currentRoundId, "ended!");
        console.log("");
        console.log("Quadratic funding scores calculated.");
        console.log("Funds automatically distributed to projects.");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Distribute funds to projects based on QF scores
     * @dev Funds are automatically distributed when round ends
     * @notice This function is informational only - distribution happens in endRound()
     */
    function distribute(uint256 roundId) external view {
        console.log("==========================================");
        console.log("ACTION: View Distribution");
        console.log("==========================================");
        console.log("");
        console.log("Round:", roundId);
        console.log("");
        console.log("Note: Funds are automatically distributed when endRound() is called.");
        console.log("This function shows the round information.");
        
        uint256 matchingPool = QuadraticFundingSplitter(SPLITTER).matchingPools(roundId);
        console.log("");
        console.log("Matching pool:", matchingPool / 1e18, "pgDAI");
    }
    
    // ============================================
    // VIEW FUNCTIONS - STATS AND MONITORING
    // ============================================
    
    /**
     * @notice View comprehensive system statistics
     * @dev Shows vault stats, strategy deployment, and project info
     */
    function viewStats() external view {
        console.log("==========================================");
        console.log("System Statistics");
        console.log("==========================================");
        console.log("");
        
        // Vault stats
        uint256 totalSupply = IERC20(VAULT).totalSupply();
        console.log("VAULT STATS");
        console.log("  Total Shares:", totalSupply / 1e18, "pgDAI");
        console.log("");
        
        // Strategy stats
        console.log("STRATEGY DEPLOYMENT");
        uint256 vaultDaiBalance = IERC20(DAI).balanceOf(VAULT);
        console.log("  Idle in Vault:", vaultDaiBalance / 1e18, "DAI");
        console.log("");
        
        // Project stats
        uint256 count = QuadraticFundingSplitter(SPLITTER).projectCount();
        uint256 currentRoundId = QuadraticFundingSplitter(SPLITTER).currentRound();
        uint256 splitterBalance = IERC20(VAULT).balanceOf(SPLITTER);
        console.log("FUNDING STATS");
        console.log("  Projects:", count);
        console.log("  Current Round:", currentRoundId);
        console.log("  Available for Distribution:", splitterBalance / 1e18, "pgDAI");
        console.log("");
    }
    
    /**
     * @notice View detailed round statistics
     * @param roundId Round number to query
     */
    function viewRound(uint256 roundId) external view {
        console.log("==========================================");
        console.log("Round Statistics");
        console.log("==========================================");
        console.log("");
        console.log("Round ID:", roundId);
        
        uint256 count = QuadraticFundingSplitter(SPLITTER).projectCount();
        uint256 matchingPool = QuadraticFundingSplitter(SPLITTER).matchingPools(roundId);
        
        console.log("Matching Pool:", matchingPool / 1e18, "pgDAI");
        
        console.log("");
        console.log("PROJECT SCORES:");
        for (uint256 i = 0; i < count; i++) {
            (address recipient, string memory name, , uint256 totalVotes, uint256 uniqueVoters, bool active, uint256 totalReceived) = 
                QuadraticFundingSplitter(SPLITTER).projects(i);
            
            console.log("");
            console.log("Project:", name);
            console.log("  Address:", recipient);
            console.log("  Votes:", totalVotes / 1e18, "pgDAI");
            console.log("  Unique Voters:", uniqueVoters);
            console.log("  Active:", active);
            console.log("  Total Received:", totalReceived / 1e18, "pgDAI");
        }
        console.log("");
    }
    
    /**
     * @notice View strategy allocation percentages
     */
    function viewAllocation() external view {
        console.log("==========================================");
        console.log("Strategy Allocation");
        console.log("==========================================");
        console.log("");
        
        uint256 aaveAllocation = YieldAggregator(AGGREGATOR).aaveAllocation();
        uint256 sparkAllocation = 10000 - aaveAllocation;
        
        console.log("Aave v3:", aaveAllocation / 100, "%");
        console.log("Spark Protocol:", sparkAllocation / 100, "%");
        console.log("");
    }
    
    // ============================================
    // ADVANCED ACTIONS - ADMIN
    // ============================================
    
    /**
     * @notice Rebalance funds between strategies
     * @dev Adjusts deployment to match target allocation
     */
    function rebalanceStrategies() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Rebalance Strategies");
        console.log("==========================================");
        console.log("");
        
        YieldAggregator(AGGREGATOR).rebalance();
        
        console.log("Success! Strategies rebalanced to target allocation.");
        
        vm.stopBroadcast();
    }
    
    /**
     * @notice Update strategy allocation
     * @param aavePercentage Percentage for Aave (0-10000, where 10000 = 100%)
     * @dev Changes the split between Aave and Spark
     */
    function setAllocation(uint256 aavePercentage) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("ACTION: Set Strategy Allocation");
        console.log("==========================================");
        console.log("");
        console.log("New Aave allocation:", aavePercentage / 100, "%");
        console.log("New Spark allocation:", (10000 - aavePercentage) / 100, "%");
        
        YieldAggregator(AGGREGATOR).setAllocation(aavePercentage);
        
        console.log("");
        console.log("Success! Allocation updated.");
        console.log("Call rebalanceStrategies() to apply changes.");
        
        vm.stopBroadcast();
    }
    
    // ============================================
    // DEMO SCENARIOS - COMPLETE FLOWS
    // ============================================
    
    /**
     * @notice Run a complete demo scenario
     * @dev Executes all major actions in sequence for a full demonstration
     */
    function runFullDemo() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("FULL DEMO SCENARIO");
        console.log("==========================================");
        console.log("");
        
        // 1. Get DAI
        console.log("Step 1: Getting DAI...");
        vm.startPrank(WHALE);
        IERC20(DAI).transfer(user, 12_000 * 1e18);
        vm.stopPrank();
        console.log("  Got 12,000 DAI");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 2. Deposit to vault
        console.log("Step 2: Depositing to vault...");
        IERC20(DAI).approve(VAULT, 10_000 * 1e18);
        PublicGoodsVault(VAULT).deposit(10_000 * 1e18, user);
        console.log("  Deposited 10,000 DAI");
        
        // Initialize harvest baseline after first deposit
        PublicGoodsVault(VAULT).initializeHarvest();
        console.log("  Harvest baseline initialized");
        
        // 3. Deploy to strategies
        console.log("Step 3: Deploying to strategies...");
        PublicGoodsVault(VAULT).depositToStrategies(8_000 * 1e18);
        console.log("  Deployed 8,000 DAI to yield strategies");
        
        // 4. Register projects
        console.log("Step 4: Registering projects...");
        QuadraticFundingSplitter(SPLITTER).registerProject(
            0x1111111111111111111111111111111111111111,
            "Web3 Security Library",
            "Open-source security auditing tools"
        );
        QuadraticFundingSplitter(SPLITTER).registerProject(
            0x2222222222222222222222222222222222222222,
            "Carbon Offset Protocol",
            "Blockchain-based carbon credits"
        );
        QuadraticFundingSplitter(SPLITTER).registerProject(
            0x3333333333333333333333333333333333333333,
            "DeFi Education DAO",
            "Free DeFi education resources"
        );
        console.log("  Registered 3 projects");
        
        // 5. Harvest yield (simulate)
        console.log("Step 5: Harvesting yield...");
        console.log("  Simulating yield accrual...");
        IERC20(DAI).transfer(AGGREGATOR, 1 * 1e18);
        console.log("  Injected 1 DAI into aggregator");
        PublicGoodsVault(VAULT).harvest();
        console.log("  Yield harvested");
        
    // 6. Start round
    console.log("Step 6: Starting funding round...");
    QuadraticFundingSplitter(SPLITTER).startRound(DEMO_ROUND_DURATION);
        console.log("  Round started");
        
    // 7. Add to matching pool
    console.log("Step 7: Adding to matching pool...");
    IERC20(VAULT).approve(SPLITTER, 50 * 1e18);
    QuadraticFundingSplitter(SPLITTER).addToMatchingPool(50 * 1e18);
    console.log("  Added 50 pgDAI to matching pool");

    // 8. Vote
    console.log("Step 8: Voting for projects...");
        IERC20(VAULT).approve(SPLITTER, 100 * 1e18);
        QuadraticFundingSplitter(SPLITTER).vote(0, 50 * 1e18);
        QuadraticFundingSplitter(SPLITTER).vote(1, 30 * 1e18);
        QuadraticFundingSplitter(SPLITTER).vote(2, 20 * 1e18);
        console.log("  Voted for all projects");
        
    // Fast-forward past the round duration so the demo can end the round immediately
    vm.stopBroadcast();
    vm.warp(block.timestamp + DEMO_ROUND_DURATION + 1);
    vm.roll(block.number + 1);
    vm.startBroadcast(deployerPrivateKey);
    console.log("  Advanced chain time beyond round duration");

        // 9. End round and distribute
        console.log("Step 9: Ending round (this also distributes funds)...");
        QuadraticFundingSplitter(SPLITTER).endRound();
        console.log("  Round ended, funds distributed to projects");
        
        console.log("");
        console.log("==========================================");
        console.log("DEMO COMPLETE!");
        console.log("==========================================");
        
        vm.stopBroadcast();
    }
}
