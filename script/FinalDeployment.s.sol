// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

/**
 * @title FinalDeployment  
 * @notice Deploy fresh strategies and aggregator, then wire to existing vault
 */
contract FinalDeployment is Script {
    // Existing deployed contracts
    address constant VAULT = 0xd1D634F7E763135a46d22316C304A788340362A2;
    address constant SPLITTER = 0xb2FD819e68B58D2509FDC3393fCFd5860dD28c52;
    
    // Protocol addresses
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant SPARK_SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant ADAI = 0x018008bfb33d285247A21d44E50697654f754e63;
    
    // Configuration
    uint256 constant AAVE_ALLOCATION = 5000; // 50%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==========================================");
        console.log("Final Deployment - Fresh Start");
        console.log("==========================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new AaveStrategy (pointing to temp address first)
        console.log("1. Deploying AaveStrategy...");
        AaveStrategy aaveStrategy = new AaveStrategy(
            AAVE_POOL,
            DAI,
            ADAI,
            address(0x1) // Temporary, will update later
        );
        console.log("   AaveStrategy:", address(aaveStrategy));
        console.log("");

        // 2. Deploy new SparkStrategy (pointing to temp address first)
        console.log("2. Deploying SparkStrategy...");
        SparkStrategy sparkStrategy = new SparkStrategy(
            SPARK_SDAI,
            DAI,
            address(0x1) // Temporary, will update later
        );
        console.log("   SparkStrategy:", address(sparkStrategy));
        console.log("");

        // 3. Deploy YieldAggregator
        console.log("3. Deploying YieldAggregator...");
        YieldAggregator aggregator = new YieldAggregator(
            DAI,
            address(aaveStrategy),
            address(sparkStrategy),
            VAULT,
            AAVE_ALLOCATION
        );
        console.log("   YieldAggregator:", address(aggregator));
        console.log("");

        // 4. Update strategies to point to aggregator
        console.log("4. Configuring strategies...");
        aaveStrategy.setVault(address(aggregator));
        sparkStrategy.setVault(address(aggregator));
        console.log("   Strategies configured");
        console.log("");

        // 5. Configure Vault
        console.log("5. Configuring PublicGoodsVault...");
        PublicGoodsVault vault = PublicGoodsVault(VAULT);
        vault.setYieldAggregator(address(aggregator));
        console.log("   Vault configured");
        console.log("");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("==========================================");
        console.log("Network: Tenderly Mainnet Fork");
        console.log("");
        console.log("Core Contracts:");
        console.log("  PublicGoodsVault:", VAULT);
        console.log("  QuadraticFundingSplitter:", SPLITTER);
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
        console.log("==========================================");
        console.log("");
        console.log("SYSTEM READY!");
        console.log("==========================================");
    }
}
