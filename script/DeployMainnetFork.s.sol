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
 * @title DeployMainnetFork
 * @notice Deployment script for Tenderly mainnet fork with real Aave and Spark
 * @dev Run with: forge script script/DeployMainnetFork.s.sol --rpc-url $TENDERLY_FORK_RPC --broadcast
 */
contract DeployMainnetFork is Script {
    // Mainnet addresses
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant SPARK_SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant DAI = 0x6B175474E89094C44Da98b954EeEd5ed7B6f45B8;
    address constant ADAI = 0x018008bfb33d285247A21d44E50697654f754e63;

    // Configuration
    uint256 constant AAVE_ALLOCATION = 5000; // 50% Aave, 50% Spark
    uint256 constant PERFORMANCE_FEE = 100; // 1%
    uint256 constant MIN_VOTE_AMOUNT = 1e18; // 1 DAI
    uint256 constant ROUND_DURATION = 30 days;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Deploying to Tenderly Mainnet Fork ===");
        console.log("Deployer:", deployer);
        console.log("DAI:", DAI);
        console.log("Aave Pool:", AAVE_POOL);
        console.log("Spark sDAI:", SPARK_SDAI);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy QuadraticFundingSplitter
        console.log("Deploying QuadraticFundingSplitter...");
        QuadraticFundingSplitter splitter = new QuadraticFundingSplitter(
            MIN_VOTE_AMOUNT,
            ROUND_DURATION
        );
        console.log("QuadraticFundingSplitter:", address(splitter));

        // 2. Deploy PublicGoodsVault
        console.log("Deploying PublicGoodsVault...");
        PublicGoodsVault vault = new PublicGoodsVault(
            IERC20(DAI),
            "Public Goods Vault Shares",
            "pgDAI",
            address(splitter), // allocationAddress
            deployer,          // keeper
            deployer           // emergencyAdmin
        );
        console.log("PublicGoodsVault:", address(vault));

        // Set vault in splitter
        splitter.setVault(address(vault));
        vault.setPerformanceFee(PERFORMANCE_FEE);

        // 3. Deploy AaveStrategy
        console.log("Deploying AaveStrategy...");
        AaveStrategy aaveStrategy = new AaveStrategy(
            AAVE_POOL,
            DAI,
            ADAI,
            address(vault) // temporary, will update to aggregator
        );
        console.log("AaveStrategy:", address(aaveStrategy));

        // 4. Deploy SparkStrategy
        console.log("Deploying SparkStrategy...");
        SparkStrategy sparkStrategy = new SparkStrategy(
            SPARK_SDAI,
            DAI,
            address(vault) // temporary, will update to aggregator
        );
        console.log("SparkStrategy:", address(sparkStrategy));

        // 5. Deploy YieldAggregator
        console.log("Deploying YieldAggregator...");
        YieldAggregator aggregator = new YieldAggregator(
            DAI,
            address(aaveStrategy),
            address(sparkStrategy),
            address(vault),
            AAVE_ALLOCATION
        );
        console.log("YieldAggregator:", address(aggregator));

        // 6. Update strategy vault addresses
        console.log("Configuring strategies...");
        aaveStrategy.setVault(address(aggregator));
        sparkStrategy.setVault(address(aggregator));

        // 7. Set yield aggregator in vault
        vault.setYieldAggregator(address(aggregator));

        console.log("");
        console.log("=== Deployment Complete ===");
        console.log("QuadraticFundingSplitter:", address(splitter));
        console.log("PublicGoodsVault:", address(vault));
        console.log("YieldAggregator:", address(aggregator));
        console.log("AaveStrategy:", address(aaveStrategy));
        console.log("SparkStrategy:", address(sparkStrategy));
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Fund vault with DAI for testing");
        console.log("2. Call vault.initializeHarvest()");
        console.log("3. Call vault.depositToStrategies(amount)");
        console.log("4. Wait for yield to accrue");
        console.log("5. Call vault.harvest() to distribute to splitter");
        console.log("6. Register projects in splitter");
        console.log("7. Vote and end funding round");

        vm.stopBroadcast();

        // Save deployment addresses
        _saveDeployment(
            address(vault),
            address(splitter),
            address(aggregator),
            address(aaveStrategy),
            address(sparkStrategy)
        );
    }

    function _saveDeployment(
        address vault,
        address splitter,
        address aggregator,
        address aaveStrategy,
        address sparkStrategy
    ) internal {
        string memory json = "deployment";
        vm.serializeAddress(json, "vault", vault);
        vm.serializeAddress(json, "splitter", splitter);
        vm.serializeAddress(json, "aggregator", aggregator);
        vm.serializeAddress(json, "aaveStrategy", aaveStrategy);
        string memory finalJson = vm.serializeAddress(json, "sparkStrategy", sparkStrategy);
        
        vm.writeJson(finalJson, "./deployments/tenderly-fork.json");
    }
}
