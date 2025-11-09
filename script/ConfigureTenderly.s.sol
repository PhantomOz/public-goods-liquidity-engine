// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";

/**
 * @title ConfigureTenderly
 * @notice Complete configuration after deployment
 * @dev Run with: forge script script/ConfigureTenderly.s.sol --rpc-url tenderly --broadcast --legacy
 */
contract ConfigureTenderly is Script {
    // Deployed contract addresses (checksummed)
    address constant VAULT = 0xd1D634F7E763135a46d22316C304A788340362A2;
    address constant AAVE_STRATEGY = 0x10cC5C0e98020aE4B011cf72a1449b32c25d39f1;
    address constant SPARK_STRATEGY = 0x208C9f8e8e7d485e008cD23Bbb61E235352C74BA;
    address constant AGGREGATOR = 0x5aE8575cdD14D145857BEF53ec8aaB040d867616;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("==========================================");
        console.log("Configuring Deployed Contracts");
        console.log("==========================================");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Set aggregator as vault for AaveStrategy
        console.log("1. Configuring AaveStrategy...");
        AaveStrategy aaveStrategy = AaveStrategy(AAVE_STRATEGY);
        try aaveStrategy.setVault(AGGREGATOR) {
            console.log("   AaveStrategy vault set to Aggregator");
        } catch {
            console.log("   AaveStrategy already configured or not owner");
        }
        console.log("");

        // 2. Set aggregator as vault for SparkStrategy
        console.log("2. Configuring SparkStrategy...");
        SparkStrategy sparkStrategy = SparkStrategy(SPARK_STRATEGY);
        try sparkStrategy.setVault(AGGREGATOR) {
            console.log("   SparkStrategy vault set to Aggregator");
        } catch {
            console.log("   SparkStrategy already configured or not owner");
        }
        console.log("");

        // 3. Set aggregator in vault
        console.log("3. Configuring PublicGoodsVault...");
        PublicGoodsVault vault = PublicGoodsVault(VAULT);
        try vault.setYieldAggregator(AGGREGATOR) {
            console.log("   YieldAggregator set in Vault");
        } catch {
            console.log("   Vault already configured or not owner");
        }
        console.log("");

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("Configuration Complete!");
        console.log("==========================================");
        console.log("Vault:", VAULT);
        console.log("  -> YieldAggregator:", vault.yieldAggregator());
        console.log("");
        console.log("AaveStrategy:", AAVE_STRATEGY);
        console.log("  -> Vault:", aaveStrategy.vault());
        console.log("");
        console.log("SparkStrategy:", SPARK_STRATEGY);
        console.log("  -> Vault:", sparkStrategy.vault());
        console.log("");
        console.log("YieldAggregator:", AGGREGATOR);
        console.log("  -> Aave Allocation:", aaveStrategy.vault() == AGGREGATOR ? "Configured" : "Not configured");
        console.log("  -> Spark Allocation:", sparkStrategy.vault() == AGGREGATOR ? "Configured" : "Not configured");
        console.log("==========================================");
    }
}
