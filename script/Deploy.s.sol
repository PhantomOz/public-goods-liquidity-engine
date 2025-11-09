// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {QuadraticFundingSplitter} from "../src/QuadraticFundingSplitter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployPublicGoodsEngine
 * @notice Deployment script for the Public Goods Liquidity Engine
 * @dev Deploys vault and splitter, sets up initial configuration
 */
contract DeployPublicGoodsEngine is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying with address:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy or use existing asset token
        address assetAddress = vm.envOr("ASSET_TOKEN", address(0));
        MockERC20 asset;

        if (assetAddress == address(0)) {
            console.log("Deploying mock asset token...");
            asset = new MockERC20("USD Stablecoin", "USDS");
            console.log("Mock Asset deployed at:", address(asset));
        } else {
            console.log("Using existing asset at:", assetAddress);
            asset = MockERC20(assetAddress);
        }

        // Get configuration from environment or use defaults
        address keeper = vm.envOr("KEEPER_ADDRESS", deployer);
        address emergencyAdmin = vm.envOr("EMERGENCY_ADMIN", deployer);

        console.log("Keeper address:", keeper);
        console.log("Emergency admin:", emergencyAdmin);

        // Deploy vault with temporary allocation address
        console.log("\nDeploying PublicGoodsVault...");
        PublicGoodsVault vault = new PublicGoodsVault(
            asset,
            "Public Goods Vault Shares",
            "pgvUSD",
            address(1), // Temporary - will update after splitter deployment
            keeper,
            emergencyAdmin
        );
        console.log("Vault deployed at:", address(vault));

        // Deploy splitter
        console.log("\nDeploying QuadraticFundingSplitter...");
        uint256 minVoteAmount = vm.envOr("MIN_VOTE_AMOUNT", uint256(1 ether));
        QuadraticFundingSplitter splitter = new QuadraticFundingSplitter(
            address(vault),
            minVoteAmount
        );
        console.log("Splitter deployed at:", address(splitter));

        // Update vault allocation address to splitter
        console.log("\nConfiguring vault allocation address...");
        vault.setAllocationAddress(address(splitter));
        console.log("Vault allocation address set to splitter");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Asset Token:", address(asset));
        console.log("Vault:", address(vault));
        console.log("Splitter:", address(splitter));
        console.log("Keeper:", keeper);
        console.log("Emergency Admin:", emergencyAdmin);
        console.log("Min Vote Amount:", minVoteAmount);
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Initialize vault: call initializeHarvest() as keeper");
        console.log("2. Register projects in splitter");
        console.log("3. Start funding round in splitter");
        console.log("4. Users can deposit into vault");
        console.log("5. Keeper harvests yield periodically");
        console.log("6. Community votes on projects");
        console.log("7. End round to distribute funds");
    }
}
