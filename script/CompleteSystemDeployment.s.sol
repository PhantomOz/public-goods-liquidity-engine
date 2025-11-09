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

contract CompleteSystemDeployment is Script {
    // Mainnet addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDS = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    
    // Aave v3
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    
    // Spark Protocol
    address constant SPARK_SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("==========================================");
        console.log("Complete System Deployment - Fresh Start");
        console.log("==========================================");
        console.log("");
        
        address deployer = vm.addr(deployerPrivateKey);
        address keeper = deployer; // Use deployer as keeper
        address emergencyAdmin = deployer; // Use deployer as emergency admin
        
        // 1. Deploy QuadraticFundingSplitter (will set vault token later)
        console.log("1. Deploying QuadraticFundingSplitter...");
        QuadraticFundingSplitter splitter = new QuadraticFundingSplitter(
            address(1), // temp, will update
            1e18 // 1 token minimum vote
        );
        console.log("   QuadraticFundingSplitter:", address(splitter));
        console.log("");
        
        // 2. Deploy PublicGoodsVault
        console.log("2. Deploying PublicGoodsVault...");
        PublicGoodsVault vault = new PublicGoodsVault(
            IERC20(DAI),
            "Public Goods Vault",
            "pgDAI",
            address(splitter),
            keeper,
            emergencyAdmin
        );
        console.log("   PublicGoodsVault:", address(vault));
        console.log("");
        
        // 3. Deploy AaveStrategy
        console.log("3. Deploying AaveStrategy...");
        address aDAI = 0x018008bfb33d285247A21d44E50697654f754e63; // Mainnet aDAI
        AaveStrategy aaveStrategy = new AaveStrategy(
            AAVE_POOL,
            DAI,
            aDAI,
            address(1) // temp vault, will update
        );
        console.log("   AaveStrategy:", address(aaveStrategy));
        console.log("");
        
        // 4. Deploy SparkStrategy
        console.log("4. Deploying SparkStrategy...");
        SparkStrategy sparkStrategy = new SparkStrategy(
            SPARK_SDAI,
            DAI,
            address(1) // temp vault, will update
        );
        console.log("   SparkStrategy:", address(sparkStrategy));
        console.log("");
        
        // 5. Deploy YieldAggregator
        console.log("5. Deploying YieldAggregator...");
        YieldAggregator aggregator = new YieldAggregator(
            DAI,
            address(aaveStrategy),
            address(sparkStrategy),
            address(vault),
            5000 // 50% allocation to Aave
        );
        console.log("   YieldAggregator:", address(aggregator));
        console.log("");
        
        // 6. Configure strategies to point to aggregator
        console.log("6. Configuring strategies...");
        aaveStrategy.setVault(address(aggregator));
        sparkStrategy.setVault(address(aggregator));
        console.log("   Strategies configured");
        console.log("");
        
        // 7. Configure vault to use aggregator
        console.log("7. Configuring vault...");
        vault.setYieldAggregator(address(aggregator));
        console.log("   Vault configured");
        console.log("");
        
        console.log("==========================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("==========================================");
        console.log("");
        console.log("Deployed Addresses:");
        console.log("  QuadraticFundingSplitter:", address(splitter));
        console.log("  PublicGoodsVault:", address(vault));
        console.log("  AaveStrategy:", address(aaveStrategy));
        console.log("  SparkStrategy:", address(sparkStrategy));
        console.log("  YieldAggregator:", address(aggregator));
        console.log("");
        
        vm.stopBroadcast();
    }
}
