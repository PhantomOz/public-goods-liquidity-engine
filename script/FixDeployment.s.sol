// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

/**
 * @title FixDeployment
 * @notice Redeploy SparkStrategy and complete configuration
 */
contract FixDeployment is Script {
    // Existing deployed contracts
    address constant VAULT = 0xd1D634F7E763135a46d22316C304A788340362A2;
    address constant AAVE_STRATEGY = 0x10cC5C0e98020aE4B011cf72a1449b32c25d39f1;
    address constant AGGREGATOR = 0x5aE8575cdD14D145857BEF53ec8aaB040d867616;
    
    // Protocol addresses
    address constant SPARK_SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==========================================");
        console.log("Fixing Deployment");
        console.log("==========================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy SparkStrategy
        console.log("1. Deploying SparkStrategy...");
        SparkStrategy sparkStrategy = new SparkStrategy(
            SPARK_SDAI,
            DAI,
            AGGREGATOR  // Point directly to aggregator
        );
        console.log("   SparkStrategy:", address(sparkStrategy));
        console.log("");

        // 2. Update YieldAggregator with new SparkStrategy
        console.log("2. Updating YieldAggregator...");
        YieldAggregator aggregator = YieldAggregator(AGGREGATOR);
        
        // First get current aave strategy address
        (uint256 aaveBalance, ) = aggregator.getStrategyBalances();
        
        aggregator.setStrategies(AAVE_STRATEGY, address(sparkStrategy));
        console.log("   Strategies updated in YieldAggregator");
        console.log("");

        // 3. Configure AaveStrategy
        console.log("3. Configuring AaveStrategy...");
        AaveStrategy aaveStrategy = AaveStrategy(AAVE_STRATEGY);
        aaveStrategy.setVault(AGGREGATOR);
        console.log("   AaveStrategy vault set to Aggregator");
        console.log("");

        // 4. Configure Vault
        console.log("4. Configuring PublicGoodsVault...");
        PublicGoodsVault vault = PublicGoodsVault(VAULT);
        vault.setYieldAggregator(AGGREGATOR);
        console.log("   YieldAggregator set in Vault");
        console.log("");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("DEPLOYMENT FIXED!");
        console.log("==========================================");
        console.log("Core Contracts:");
        console.log("  PublicGoodsVault:", VAULT);
        console.log("  YieldAggregator:", AGGREGATOR);
        console.log("");
        console.log("Strategies:");
        console.log("  AaveStrategy:", AAVE_STRATEGY);
        console.log("  SparkStrategy:", address(sparkStrategy));
        console.log("");
        console.log("Configuration:");
        console.log("  Vault -> Aggregator:", vault.yieldAggregator());
        console.log("  AaveStrategy -> Aggregator:", aaveStrategy.vault());
        console.log("  SparkStrategy -> Aggregator:", sparkStrategy.vault());
        console.log("==========================================");
        console.log("");
        console.log("System is ready! Next steps:");
        console.log("1. Get DAI from whale or faucet");
        console.log("2. Deposit DAI to vault");
        console.log("3. Call vault.depositToStrategies()");
        console.log("4. Wait for yield to accrue");
        console.log("5. Call vault.harvest()");
        console.log("==========================================");
    }
}
