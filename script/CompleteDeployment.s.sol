// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

/**
 * @title CompleteDeployment
 * @notice Deploy missing components and wire everything together
 */
contract CompleteDeployment is Script {
    // Existing deployed contracts
    address constant VAULT = 0xd1D634F7E763135a46d22316C304A788340362A2;
    address constant SPLITTER = 0xb2FD819e68B58D2509FDC3393fCFd5860dD28c52;
    address constant AAVE_STRATEGY = 0x10cC5C0e98020aE4B011cf72a1449b32c25d39f1;
    address constant SPARK_STRATEGY = 0x84B3e3d994C1e928C017B03913cf27C70b25DE7D;
    
    // Configuration
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint256 constant AAVE_ALLOCATION = 5000; // 50%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==========================================");
        console.log("Completing Deployment");
        console.log("==========================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy YieldAggregator
        console.log("1. Deploying YieldAggregator...");
        YieldAggregator aggregator = new YieldAggregator(
            DAI,
            AAVE_STRATEGY,
            SPARK_STRATEGY,
            VAULT,
            AAVE_ALLOCATION
        );
        console.log("   YieldAggregator:", address(aggregator));
        console.log("");

        // 2. Configure AaveStrategy
        console.log("2. Configuring AaveStrategy...");
        AaveStrategy aaveStrategy = AaveStrategy(AAVE_STRATEGY);
        aaveStrategy.setVault(address(aggregator));
        console.log("   AaveStrategy vault -> Aggregator");
        console.log("");

        // 3. Configure SparkStrategy
        console.log("3. Configuring SparkStrategy...");
        SparkStrategy sparkStrategy = SparkStrategy(SPARK_STRATEGY);
        sparkStrategy.setVault(address(aggregator));
        console.log("   SparkStrategy vault -> Aggregator");
        console.log("");

        // 4. Configure Vault
        console.log("4. Configuring PublicGoodsVault...");
        PublicGoodsVault vault = PublicGoodsVault(VAULT);
        vault.setYieldAggregator(address(aggregator));
        console.log("   Vault yieldAggregator -> Aggregator");
        console.log("");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("==========================================");
        console.log("Network: Tenderly Mainnet Fork");
        console.log("Asset: DAI", DAI);
        console.log("");
        console.log("Core Contracts:");
        console.log("  PublicGoodsVault:", VAULT);
        console.log("  QuadraticFundingSplitter:", SPLITTER);
        console.log("  YieldAggregator:", address(aggregator));
        console.log("");
        console.log("Strategies:");
        console.log("  AaveStrategy:", AAVE_STRATEGY);
        console.log("  SparkStrategy:", SPARK_STRATEGY);
        console.log("");
        console.log("Configuration Verified:");
        console.log("  Vault -> Aggregator:", vault.yieldAggregator() == address(aggregator) ? "OK" : "FAILED");
        console.log("  AaveStrategy -> Aggregator:", aaveStrategy.vault() == address(aggregator) ? "OK" : "FAILED");
        console.log("  SparkStrategy -> Aggregator:", sparkStrategy.vault() == address(aggregator) ? "OK" : "FAILED");
        console.log("");
        console.log("Aave Allocation: 50%");
        console.log("Spark Allocation: 50%");
        console.log("==========================================");
        console.log("");
        console.log("Ready to use! Next steps:");
        console.log("1. Get DAI from mainnet whale");
        console.log("2. Approve vault to spend DAI");
        console.log("3. vault.deposit(amount, receiver)");
        console.log("4. vault.depositToStrategies(amount)");
        console.log("5. Wait for yield accrual");
        console.log("6. vault.harvest()");
        console.log("==========================================");
    }
}
