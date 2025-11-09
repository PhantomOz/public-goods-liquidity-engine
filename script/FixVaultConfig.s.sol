// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";

contract FixVaultConfig is Script {
    // Actual deployed addresses
    address constant VAULT = 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680;
    address constant AAVE_STRATEGY = 0x2876CC2a624fe603434404d9c10B097b737dE983;
    address constant SPARK_STRATEGY = 0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082;
    address constant YIELD_AGGREGATOR = 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("Fixing Vault Configuration");
        console.log("==========================================");
        console.log("");
        
        // 1. Update vault to use correct aggregator
        console.log("1. Setting vault's yield aggregator...");
        PublicGoodsVault(VAULT).setYieldAggregator(YIELD_AGGREGATOR);
        console.log("   Vault now points to:", YIELD_AGGREGATOR);
        console.log("");
        
        // 2. Update strategies to point to aggregator
        console.log("2. Updating strategies...");
        AaveStrategy(AAVE_STRATEGY).setVault(YIELD_AGGREGATOR);
        SparkStrategy(SPARK_STRATEGY).setVault(YIELD_AGGREGATOR);
        console.log("   Strategies now point to aggregator");
        console.log("");
        
        console.log("==========================================");
        console.log("CONFIGURATION FIXED!");
        console.log("==========================================");
        console.log("");
        console.log("Final Configuration:");
        console.log("  Vault:", VAULT);
        console.log("  YieldAggregator:", YIELD_AGGREGATOR);
        console.log("  AaveStrategy:", AAVE_STRATEGY);
        console.log("  SparkStrategy:", SPARK_STRATEGY);
        console.log("");
        
        vm.stopBroadcast();
    }
}
