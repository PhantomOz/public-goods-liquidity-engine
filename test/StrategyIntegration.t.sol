// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {AaveStrategy} from "../src/AaveStrategy.sol";
import {SparkStrategy} from "../src/SparkStrategy.sol";
import {YieldAggregator} from "../src/YieldAggregator.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockAavePool, MockAToken} from "../src/mocks/MockAavePool.sol";
import {MockSparkSDai} from "../src/mocks/MockSparkSDai.sol";

contract StrategyIntegrationTest is Test {
    AaveStrategy public aaveStrategy;
    SparkStrategy public sparkStrategy;
    YieldAggregator public aggregator;
    
    MockERC20 public dai;
    MockAavePool public aavePool;
    MockAToken public aDAI;
    MockSparkSDai public sDAI;
    
    address public vault = address(0x1);
    address public keeper = address(0x2);
    address public user = address(0x3);
    
    uint256 constant INITIAL_DEPOSIT = 1000e18;
    uint256 constant AAVE_ALLOCATION = 5000; // 50%

    function setUp() public {
        // Deploy tokens
        dai = new MockERC20("DAI", "DAI");
        
        // Deploy Aave mocks
        aavePool = new MockAavePool();
        aDAI = new MockAToken("Aave DAI", "aDAI");
        aavePool.setAToken(address(dai), address(aDAI));
        
        // Deploy Spark mock
        sDAI = new MockSparkSDai(dai);
        
        // Deploy strategies
        aaveStrategy = new AaveStrategy(
            address(aavePool),
            address(dai),
            address(aDAI),
            vault
        );
        
        sparkStrategy = new SparkStrategy(
            address(sDAI),
            address(dai),
            vault
        );
        
        // Deploy aggregator
        aggregator = new YieldAggregator(
            address(dai),
            address(aaveStrategy),
            address(sparkStrategy),
            vault,
            AAVE_ALLOCATION
        );
        
        // Transfer ownership to this test contract for strategy configuration
        aaveStrategy.transferOwnership(address(this));
        sparkStrategy.transferOwnership(address(this));
        
        // Update strategy vault addresses to aggregator
        aaveStrategy.setVault(address(aggregator));
        sparkStrategy.setVault(address(aggregator));
        
        // Setup approvals
        vm.startPrank(vault);
        dai.approve(address(aggregator), type(uint256).max);
        vm.stopPrank();
        
        // Mint DAI to vault
        dai.mint(vault, INITIAL_DEPOSIT * 10);
    }

    function testAaveStrategyDeposit() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(aaveStrategy), depositAmount);
        aaveStrategy.deposit(depositAmount);
        vm.stopPrank();
        
        assertEq(aaveStrategy.totalAssets(), depositAmount);
        assertEq(aaveStrategy.totalDeposited(), depositAmount);
        assertEq(aDAI.balanceOf(address(aaveStrategy)), depositAmount);
    }

    function testAaveStrategyWithdraw() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(aaveStrategy), depositAmount);
        aaveStrategy.deposit(depositAmount);
        
        uint256 withdrawAmount = 50e18;
        uint256 withdrawn = aaveStrategy.withdraw(withdrawAmount, user);
        vm.stopPrank();
        
        assertEq(withdrawn, withdrawAmount);
        assertEq(dai.balanceOf(user), withdrawAmount);
        assertEq(aaveStrategy.totalAssets(), depositAmount - withdrawAmount);
    }

    function testAaveStrategyHarvest() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(aaveStrategy), depositAmount);
        aaveStrategy.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield generation (5% = 5e18)
        uint256 yieldAmount = 5e18;
        dai.mint(address(this), yieldAmount);
        dai.approve(address(aavePool), yieldAmount);
        vm.prank(address(aavePool));
        aDAI.mintPublic(address(aaveStrategy), yieldAmount);
        
        // Harvest
        vm.prank(vault);
        uint256 harvested = aaveStrategy.harvest();
        
        assertEq(harvested, yieldAmount);
        assertEq(dai.balanceOf(vault), INITIAL_DEPOSIT * 10 - depositAmount + yieldAmount);
    }

    function testSparkStrategyDeposit() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(sparkStrategy), depositAmount);
        uint256 shares = sparkStrategy.deposit(depositAmount);
        vm.stopPrank();
        
        assertGt(shares, 0);
        assertEq(sparkStrategy.totalAssets(), depositAmount);
        assertEq(sparkStrategy.totalDeposited(), depositAmount);
    }

    function testSparkStrategyWithdraw() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(sparkStrategy), depositAmount);
        sparkStrategy.deposit(depositAmount);
        
        uint256 withdrawAmount = 50e18;
        uint256 withdrawn = sparkStrategy.withdraw(withdrawAmount, user);
        vm.stopPrank();
        
        assertApproxEqAbs(withdrawn, withdrawAmount, 1e10); // Allow small rounding
        assertApproxEqAbs(dai.balanceOf(user), withdrawAmount, 1e10);
    }

    function testSparkStrategyHarvest() public {
        uint256 depositAmount = 100e18;
        
        vm.startPrank(vault);
        dai.approve(address(sparkStrategy), depositAmount);
        sparkStrategy.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield generation (5% = 5e18)
        uint256 yieldAmount = 5e18;
        dai.mint(address(this), yieldAmount);
        dai.approve(address(sDAI), yieldAmount);
        sDAI.accrueYield(yieldAmount);
        
        // Harvest
        vm.prank(vault);
        uint256 harvested = sparkStrategy.harvest();
        
        assertGt(harvested, 0);
        assertApproxEqAbs(harvested, yieldAmount, 1e16); // Allow small rounding
    }

    function testAggregatorDeposit() public {
        uint256 depositAmount = 1000e18;
        
        vm.startPrank(vault);
        (uint256 aaveAmount, uint256 sparkAmount) = aggregator.deposit(depositAmount);
        vm.stopPrank();
        
        // Check 50/50 allocation
        assertEq(aaveAmount, 500e18);
        assertEq(sparkAmount, 500e18);
        
        // Check strategy balances
        assertEq(aaveStrategy.totalAssets(), 500e18);
        assertEq(sparkStrategy.totalAssets(), 500e18);
        assertEq(aggregator.totalAssets(), 1000e18);
    }

    function testAggregatorWithdraw() public {
        uint256 depositAmount = 1000e18;
        
        vm.startPrank(vault);
        aggregator.deposit(depositAmount);
        
        uint256 withdrawAmount = 500e18;
        uint256 withdrawn = aggregator.withdraw(withdrawAmount, user);
        vm.stopPrank();
        
        assertApproxEqAbs(withdrawn, withdrawAmount, 1e16);
        assertApproxEqAbs(dai.balanceOf(user), withdrawAmount, 1e16);
        assertApproxEqAbs(aggregator.totalAssets(), 500e18, 1e16);
    }

    function testAggregatorHarvest() public {
        uint256 depositAmount = 1000e18;
        
        vm.startPrank(vault);
        aggregator.deposit(depositAmount);
        vm.stopPrank();
        
        // Simulate yield in Aave (5% of 500 = 25e18)
        dai.mint(address(this), 25e18);
        dai.approve(address(aavePool), 25e18);
        aDAI.mintPublic(address(aaveStrategy), 25e18);
        
        // Simulate yield in Spark (5% of 500 = 25e18)
        dai.mint(address(this), 25e18);
        dai.approve(address(sDAI), 25e18);
        sDAI.accrueYield(25e18);
        
        // Harvest
        vm.prank(vault);
        uint256 totalYield = aggregator.harvest();
        
        assertGt(totalYield, 0);
        // Total yield should be ~50e18 (25 from each strategy)
        assertApproxEqAbs(totalYield, 50e18, 1e18);
    }

    function testAggregatorAllocationChange() public {
        // Initial 50/50 allocation
        vm.prank(vault);
        aggregator.deposit(1000e18);
        
        // Change to 70/30 allocation (7000 basis points to Aave)
        aggregator.setAllocation(7000);
        
        // New deposit should respect new allocation
        vm.prank(vault);
        (uint256 aaveAmount, uint256 sparkAmount) = aggregator.deposit(1000e18);
        
        assertEq(aaveAmount, 700e18);
        assertEq(sparkAmount, 300e18);
    }

    function testAggregatorRebalance() public {
        // Deposit with 50/50 allocation
        vm.prank(vault);
        aggregator.deposit(1000e18);
        
        uint256 aaveBalanceBefore = aaveStrategy.totalAssets();
        uint256 sparkBalanceBefore = sparkStrategy.totalAssets();
        
        assertApproxEqAbs(aaveBalanceBefore, 500e18, 1e16);
        assertApproxEqAbs(sparkBalanceBefore, 500e18, 1e16);
        
        // Change allocation to 70/30
        aggregator.setAllocation(7000);
        
        // Rebalance
        aggregator.rebalance();
        
        // Check new balances match 70/30
        uint256 aaveBalanceAfter = aaveStrategy.totalAssets();
        uint256 sparkBalanceAfter = sparkStrategy.totalAssets();
        
        assertApproxEqAbs(aaveBalanceAfter, 700e18, 1e18);
        assertApproxEqAbs(sparkBalanceAfter, 300e18, 1e18);
    }

    function testFullIntegrationFlow() public {
        // 1. Deposit to aggregator
        vm.prank(vault);
        aggregator.deposit(1000e18);
        
        assertEq(aggregator.totalAssets(), 1000e18);
        
        // 2. Generate yield in both strategies
        // Aave yield: 5% of 500 = 25e18
        dai.mint(address(this), 25e18);
        dai.approve(address(aavePool), 25e18);
        aDAI.mintPublic(address(aaveStrategy), 25e18);
        
        // Spark yield: 5% of 500 = 25e18
        dai.mint(address(this), 25e18);
        dai.approve(address(sDAI), 25e18);
        sDAI.accrueYield(25e18);
        
        // 3. Harvest yield
        vm.prank(vault);
        uint256 totalYield = aggregator.harvest();
        
        assertGt(totalYield, 40e18); // Should have ~50e18 yield
        
        // 4. Withdraw some principal
        vm.prank(vault);
        uint256 withdrawn = aggregator.withdraw(500e18, user);
        
        assertApproxEqAbs(withdrawn, 500e18, 1e18);
        
        // 5. Total assets should be ~500e18 remaining
        assertApproxEqAbs(aggregator.totalAssets(), 500e18, 1e18);
    }
}
