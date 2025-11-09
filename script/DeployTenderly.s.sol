// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {QuadraticFundingSplitter} from "../src/QuadraticFundingSplitter.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DeployTenderly
 * @notice Deployment script for Tenderly mainnet fork with real protocol addresses
 * @dev Run with: forge script script/DeployTenderly.s.sol --rpc-url tenderly --broadcast
 */
contract DeployTenderly is Script {
    // Mainnet Protocol Addresses (from .env)
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant SPARK_SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    
    // Mainnet Token Addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EeEdeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address constant ADAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    
    // Configuration
    uint256 constant AAVE_ALLOCATION = 5000; // 50%
    uint256 constant MIN_VOTE_AMOUNT = 1 ether;
    uint256 constant ROUND_DURATION = 30 days;

    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address keeper = vm.envAddress("KEEPER_ADDRESS");
        address emergencyAdmin = vm.envAddress("EMERGENCY_ADMIN");
        
        console.log("==========================================");
        console.log("Deploying to Tenderly Mainnet Fork");
        console.log("==========================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Keeper:", keeper);
        console.log("Emergency Admin:", emergencyAdmin);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy QuadraticFundingSplitter
        console.log("1. Deploying QuadraticFundingSplitter...");
        QuadraticFundingSplitter splitter = new QuadraticFundingSplitter(
            MIN_VOTE_AMOUNT,
            ROUND_DURATION
        );
        console.log("   QuadraticFundingSplitter:", address(splitter));
        console.log("");

        // 2. Deploy PublicGoodsVault
        console.log("2. Deploying PublicGoodsVault...");
        PublicGoodsVault vault = new PublicGoodsVault(
            IERC20(DAI),
            "Public Goods Vault - DAI",
            "pgvDAI",
            address(splitter),
            keeper,
            emergencyAdmin
        );
        console.log("   PublicGoodsVault:", address(vault));
        console.log("");

        // 3. Set vault in splitter
        console.log("3. Configuring QuadraticFundingSplitter...");
        splitter.setVault(address(vault));
        console.log("   Vault set in splitter");
        console.log("");

        // 4. Deploy AaveStrategy
        console.log("4. Deploying AaveStrategy...");
        AaveStrategy aaveStrategy = new AaveStrategy(
            AAVE_POOL,
            DAI,
            ADAI,
            address(vault) // Will update to aggregator later
        );
        console.log("   AaveStrategy:", address(aaveStrategy));
        console.log("");

        // 5. Deploy SparkStrategy
        console.log("5. Deploying SparkStrategy...");
        SparkStrategy sparkStrategy = new SparkStrategy(
            SPARK_SDAI,
            DAI,
            address(vault) // Will update to aggregator later
        );
        console.log("   SparkStrategy:", address(sparkStrategy));
        console.log("");

        // 6. Deploy YieldAggregator
        console.log("6. Deploying YieldAggregator...");
        YieldAggregator aggregator = new YieldAggregator(
            DAI,
            address(aaveStrategy),
            address(sparkStrategy),
            address(vault),
            AAVE_ALLOCATION
        );
        console.log("   YieldAggregator:", address(aggregator));
        console.log("");

        // 7. Update strategies to use aggregator as vault
        console.log("7. Configuring strategies...");
        aaveStrategy.setVault(address(aggregator));
        sparkStrategy.setVault(address(aggregator));
        console.log("   Strategies configured to use aggregator");
        console.log("");

        // 8. Set aggregator in vault
        console.log("8. Configuring vault with aggregator...");
        vault.setYieldAggregator(address(aggregator));
        console.log("   YieldAggregator set in vault");
        console.log("");

        vm.stopBroadcast();

        // Display deployment summary
        console.log("==========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("==========================================");
        console.log("Network: Tenderly Mainnet Fork");
        console.log("Asset: DAI", DAI);
        console.log("");
        console.log("Core Contracts:");
        console.log("  PublicGoodsVault:", address(vault));
        console.log("  QuadraticFundingSplitter:", address(splitter));
        console.log("  YieldAggregator:", address(aggregator));
        console.log("");
        console.log("Strategies:");
        console.log("  AaveStrategy:", address(aaveStrategy));
        console.log("  SparkStrategy:", address(sparkStrategy));
        console.log("");
        console.log("Protocol Integrations:");
        console.log("  Aave v3 Pool:", AAVE_POOL);
        console.log("  Spark sDAI:", SPARK_SDAI);
        console.log("");
        console.log("Configuration:");
        console.log("  Aave Allocation: 50%");
        console.log("  Spark Allocation: 50%");
        console.log("  Min Vote Amount:", MIN_VOTE_AMOUNT);
        console.log("  Round Duration:", ROUND_DURATION, "seconds");
        console.log("==========================================");
        console.log("");
        console.log("Next Steps:");
        console.log("1. Fund the vault with DAI");
        console.log("2. Call vault.depositToStrategies() to deploy funds");
        console.log("3. Register projects in splitter");
        console.log("4. Users can vote with their shares");
        console.log("5. Keeper calls vault.harvest() to collect yield");
        console.log("==========================================");
    }
}
