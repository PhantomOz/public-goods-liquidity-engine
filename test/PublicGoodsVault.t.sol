// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {PublicGoodsVault} from "../src/PublicGoodsVault.sol";
import {QuadraticFundingSplitter} from "../src/QuadraticFundingSplitter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract PublicGoodsVaultTest is Test {
    PublicGoodsVault public vault;
    QuadraticFundingSplitter public splitter;
    MockERC20 public asset;

    address public owner;
    address public keeper;
    address public emergencyAdmin;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        owner = address(this);
        keeper = makeAddr("keeper");
        emergencyAdmin = makeAddr("emergencyAdmin");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Deploy mock asset
        asset = new MockERC20("Test Token", "TEST");

        // Deploy vault first (we'll set allocation address later)
        vault = new PublicGoodsVault(
            asset,
            "Public Goods Vault",
            "pgvTEST",
            address(1), // Temporary allocation address
            keeper,
            emergencyAdmin
        );

        // Deploy splitter with vault token
        splitter = new QuadraticFundingSplitter(address(vault), 1 ether);

        // Update vault allocation address to splitter
        vault.setAllocationAddress(address(splitter));

        // Mint tokens to test users
        asset.mint(alice, 1000 ether);
        asset.mint(bob, 1000 ether);
        asset.mint(charlie, 1000 ether);
    }

    function testDeposit() public {
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        uint256 shares = vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(shares, 100 ether);
        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.totalAssets(), 100 ether);
    }

    function testMultipleDeposits() public {
        // Alice deposits
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        // Bob deposits
        vm.startPrank(bob);
        asset.approve(address(vault), 200 ether);
        vault.deposit(200 ether, bob);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), 100 ether);
        assertEq(vault.balanceOf(bob), 200 ether);
        assertEq(vault.totalAssets(), 300 ether);
    }

    function testWithdraw() public {
        // Deposit
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);

        // Withdraw
        uint256 balanceBefore = asset.balanceOf(alice);
        vault.withdraw(50 ether, alice, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), 50 ether);
        assertEq(asset.balanceOf(alice), balanceBefore + 50 ether);
    }

    function testHarvestWithYield() public {
        // Alice deposits
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        // Initialize harvest
        vm.prank(keeper);
        vault.initializeHarvest();

        // Simulate yield generation (10% yield)
        asset.mint(address(vault), 10 ether);

        // Harvest yield
        vm.prank(keeper);
        vault.harvest();

        // Check that splitter received shares
        uint256 splitterShares = vault.balanceOf(address(splitter));
        assertGt(splitterShares, 0);

        // Alice should still have her original shares
        assertEq(vault.balanceOf(alice), 100 ether);
    }

    function testCannotHarvestWithoutYield() public {
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        vm.prank(keeper);
        vault.initializeHarvest();

        // Try to harvest without yield
        vm.prank(keeper);
        vm.expectRevert(PublicGoodsVault.NoYieldGenerated.selector);
        vault.harvest();
    }

    function testOnlyKeeperCanHarvest() public {
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        asset.mint(address(vault), 10 ether);

        // Alice tries to harvest
        vm.prank(alice);
        vm.expectRevert(PublicGoodsVault.Unauthorized.selector);
        vault.harvest();
    }

    function testPauseUnpause() public {
        // Pause vault
        vm.prank(emergencyAdmin);
        vault.setPaused(true);

        // Try to deposit while paused
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vm.expectRevert(PublicGoodsVault.VaultPaused.selector);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        // Unpause
        vm.prank(emergencyAdmin);
        vault.setPaused(false);

        // Now deposit should work
        vm.startPrank(alice);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), 100 ether);
    }

    function testSetAllocationAddress() public {
        address newAllocation = makeAddr("newAllocation");
        vault.setAllocationAddress(newAllocation);
        assertEq(vault.allocationAddress(), newAllocation);
    }

    function testCannotSetZeroAllocationAddress() public {
        vm.expectRevert(PublicGoodsVault.InvalidAddress.selector);
        vault.setAllocationAddress(address(0));
    }

    function testPerformanceFee() public {
        // Set 5% performance fee
        vault.setPerformanceFee(500);

        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        vm.prank(keeper);
        vault.initializeHarvest();

        // Simulate 10 ether yield
        asset.mint(address(vault), 10 ether);

        uint256 feeRecipientBalanceBefore = vault.balanceOf(vault.feeRecipient());

        vm.prank(keeper);
        vault.harvest();

        // Fee recipient should receive ~5% of 10 ether = 0.5 ether worth of shares
        uint256 feeRecipientBalanceAfter = vault.balanceOf(vault.feeRecipient());
        assertGt(feeRecipientBalanceAfter, feeRecipientBalanceBefore);
    }

    function testCannotSetExcessivePerformanceFee() public {
        vm.expectRevert(PublicGoodsVault.InvalidFee.selector);
        vault.setPerformanceFee(1001); // More than 10%
    }

    function testEmergencyWithdraw() public {
        // Deposit some tokens
        vm.startPrank(alice);
        asset.approve(address(vault), 100 ether);
        vault.deposit(100 ether, alice);
        vm.stopPrank();

        uint256 vaultBalance = asset.balanceOf(address(vault));

        // Emergency admin withdraws
        vm.prank(emergencyAdmin);
        vault.emergencyWithdraw(address(asset), vaultBalance);

        assertEq(asset.balanceOf(emergencyAdmin), vaultBalance);
    }

    function testIntegrationVaultAndSplitter() public {
        // Register some projects
        splitter.registerProject(alice, "Alice Project", "Helping Alice");
        splitter.registerProject(bob, "Bob Project", "Helping Bob");

        // Alice deposits into vault
        vm.startPrank(alice);
        asset.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether, alice);
        vm.stopPrank();

        // Initialize and generate yield
        vm.prank(keeper);
        vault.initializeHarvest();

        asset.mint(address(vault), 100 ether);

        // Harvest - splitter receives shares
        vm.prank(keeper);
        vault.harvest();

        uint256 splitterShares = vault.balanceOf(address(splitter));
        assertGt(splitterShares, 0);

        // Start funding round
        splitter.startRound(30 days);

        // Owner adds to matching pool (not the splitter's shares)
        vm.startPrank(owner);
        // Mint some vault shares for the owner
        asset.approve(address(vault), 1000 ether);
        vault.deposit(1000 ether, owner);
        uint256 ownerShares = vault.balanceOf(owner);
        vault.approve(address(splitter), ownerShares / 2);
        splitter.addToMatchingPool(ownerShares / 2);
        vm.stopPrank();

        // Users vote with vault shares (simulated)
        // In practice, they would need to acquire shares first
    }
}
