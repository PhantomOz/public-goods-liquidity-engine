// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IYieldStrategy
 * @notice Interface for yield-generating strategies
 */
interface IYieldStrategy {
    function deposit(uint256 amount) external returns (uint256);
    function withdraw(uint256 amount, address recipient) external returns (uint256);
    function harvest() external returns (uint256);
    function totalAssets() external view returns (uint256);
    function currentYield() external view returns (uint256);
}

/**
 * @title YieldAggregator
 * @notice Aggregates multiple yield strategies (Aave + Spark) and manages allocations
 * @dev Coordinates deposit/withdraw/harvest operations across multiple strategies
 */
contract YieldAggregator is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The vault that owns this aggregator
    address public vault;

    /// @notice Aave strategy contract
    IYieldStrategy public aaveStrategy;

    /// @notice Spark strategy contract
    IYieldStrategy public sparkStrategy;

    /// @notice Underlying asset (DAI or other stablecoin)
    IERC20 public immutable asset;

    /// @notice Allocation percentage to Aave (basis points, e.g., 5000 = 50%)
    uint256 public aaveAllocation;

    /// @notice Total allocation basis points
    uint256 public constant TOTAL_BASIS_POINTS = 10000;

    // Events
    event Deposited(uint256 totalAmount, uint256 aaveAmount, uint256 sparkAmount);
    event Withdrawn(uint256 totalAmount, uint256 aaveAmount, uint256 sparkAmount);
    event Harvested(uint256 totalYield, uint256 aaveYield, uint256 sparkYield);
    event StrategiesUpdated(address indexed aave, address indexed spark);
    event AllocationUpdated(uint256 oldAllocation, uint256 newAllocation);
    event VaultUpdated(address indexed oldVault, address indexed newVault);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error InvalidAllocation();
    error InsufficientBalance();

    modifier onlyVault() {
        if (msg.sender != vault && msg.sender != owner()) revert Unauthorized();
        _;
    }

    /**
     * @notice Initialize the yield aggregator
     * @param _asset Underlying asset token
     * @param _aaveStrategy Aave strategy address
     * @param _sparkStrategy Spark strategy address
     * @param _vault Vault contract address
     * @param _aaveAllocation Initial allocation to Aave (basis points)
     */
    constructor(
        address _asset,
        address _aaveStrategy,
        address _sparkStrategy,
        address _vault,
        uint256 _aaveAllocation
    ) Ownable(msg.sender) {
        if (_asset == address(0)) revert InvalidAddress();
        if (_aaveStrategy == address(0)) revert InvalidAddress();
        if (_sparkStrategy == address(0)) revert InvalidAddress();
        if (_vault == address(0)) revert InvalidAddress();
        if (_aaveAllocation > TOTAL_BASIS_POINTS) revert InvalidAllocation();

        asset = IERC20(_asset);
        aaveStrategy = IYieldStrategy(_aaveStrategy);
        sparkStrategy = IYieldStrategy(_sparkStrategy);
        vault = _vault;
        aaveAllocation = _aaveAllocation;

        // Approve strategies to spend assets
        asset.approve(_aaveStrategy, type(uint256).max);
        asset.approve(_sparkStrategy, type(uint256).max);
    }

    /**
     * @notice Deposit assets across both strategies based on allocation
     * @param amount Total amount to deposit
     */
    function deposit(uint256 amount) external onlyVault nonReentrant returns (uint256, uint256) {
        if (amount == 0) return (0, 0);

        // Transfer assets from vault
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Calculate allocation
        uint256 aaveAmount = (amount * aaveAllocation) / TOTAL_BASIS_POINTS;
        uint256 sparkAmount = amount - aaveAmount;

        // Deposit to strategies
        if (aaveAmount > 0) {
            aaveStrategy.deposit(aaveAmount);
        }
        if (sparkAmount > 0) {
            sparkStrategy.deposit(sparkAmount);
        }

        emit Deposited(amount, aaveAmount, sparkAmount);
        return (aaveAmount, sparkAmount);
    }

    /**
     * @notice Withdraw assets from strategies
     * @param amount Amount to withdraw
     * @param recipient Address to receive assets
     */
    function withdraw(uint256 amount, address recipient) external onlyVault nonReentrant returns (uint256) {
        if (amount == 0) return 0;
        if (recipient == address(0)) revert InvalidAddress();

        uint256 totalWithdrawn = 0;
        uint256 aaveWithdrawn = 0;
        uint256 sparkWithdrawn = 0;

        // Calculate proportional withdrawal based on current balances
        uint256 aaveBalance = aaveStrategy.totalAssets();
        uint256 sparkBalance = sparkStrategy.totalAssets();
        uint256 totalBalance = aaveBalance + sparkBalance;

        if (totalBalance == 0) revert InsufficientBalance();

        // Withdraw proportionally
        if (aaveBalance > 0) {
            uint256 aaveAmount = (amount * aaveBalance) / totalBalance;
            if (aaveAmount > aaveBalance) aaveAmount = aaveBalance;
            aaveWithdrawn = aaveStrategy.withdraw(aaveAmount, recipient);
            totalWithdrawn += aaveWithdrawn;
        }

        if (sparkBalance > 0 && totalWithdrawn < amount) {
            uint256 sparkAmount = amount - totalWithdrawn;
            if (sparkAmount > sparkBalance) sparkAmount = sparkBalance;
            sparkWithdrawn = sparkStrategy.withdraw(sparkAmount, recipient);
            totalWithdrawn += sparkWithdrawn;
        }

        emit Withdrawn(totalWithdrawn, aaveWithdrawn, sparkWithdrawn);
        return totalWithdrawn;
    }

    /**
     * @notice Harvest yield from all strategies
     * @return totalYield Total yield harvested from all strategies
     */
    function harvest() external onlyVault nonReentrant returns (uint256 totalYield) {
        // Harvest from Aave
        uint256 aaveYield = aaveStrategy.harvest();
        
        // Harvest from Spark
        uint256 sparkYield = sparkStrategy.harvest();

        totalYield = aaveYield + sparkYield;

        // Transfer aggregated yield to vault
        if (totalYield > 0) {
            asset.safeTransfer(vault, totalYield);
        }

        emit Harvested(totalYield, aaveYield, sparkYield);
    }

    /**
     * @notice Get total assets across all strategies
     * @return Total assets in all strategies
     */
    function totalAssets() public view returns (uint256) {
        return aaveStrategy.totalAssets() + sparkStrategy.totalAssets();
    }

    /**
     * @notice Get current yield across all strategies
     * @return Total unrealized yield
     */
    function currentYield() public view returns (uint256) {
        return aaveStrategy.currentYield() + sparkStrategy.currentYield();
    }

    /**
     * @notice Get breakdown of assets in each strategy
     * @return aaveAssets Assets in Aave
     * @return sparkAssets Assets in Spark
     */
    function getStrategyBalances() external view returns (uint256 aaveAssets, uint256 sparkAssets) {
        aaveAssets = aaveStrategy.totalAssets();
        sparkAssets = sparkStrategy.totalAssets();
    }

    /**
     * @notice Update strategy allocation
     * @param _newAaveAllocation New allocation to Aave (basis points)
     */
    function setAllocation(uint256 _newAaveAllocation) external onlyOwner {
        if (_newAaveAllocation > TOTAL_BASIS_POINTS) revert InvalidAllocation();
        uint256 oldAllocation = aaveAllocation;
        aaveAllocation = _newAaveAllocation;
        emit AllocationUpdated(oldAllocation, _newAaveAllocation);
    }

    /**
     * @notice Update strategy contracts
     * @param _aaveStrategy New Aave strategy
     * @param _sparkStrategy New Spark strategy
     */
    function setStrategies(address _aaveStrategy, address _sparkStrategy) external onlyOwner {
        if (_aaveStrategy == address(0)) revert InvalidAddress();
        if (_sparkStrategy == address(0)) revert InvalidAddress();

        aaveStrategy = IYieldStrategy(_aaveStrategy);
        sparkStrategy = IYieldStrategy(_sparkStrategy);

        // Re-approve strategies
        asset.approve(_aaveStrategy, type(uint256).max);
        asset.approve(_sparkStrategy, type(uint256).max);

        emit StrategiesUpdated(_aaveStrategy, _sparkStrategy);
    }

    /**
     * @notice Update vault address
     * @param _newVault New vault address
     */
    function setVault(address _newVault) external onlyOwner {
        if (_newVault == address(0)) revert InvalidAddress();
        address oldVault = vault;
        vault = _newVault;
        emit VaultUpdated(oldVault, _newVault);
    }

    /**
     * @notice Rebalance assets between strategies to match target allocation
     */
    function rebalance() external onlyOwner nonReentrant {
        uint256 totalAssetBalance = totalAssets();
        if (totalAssetBalance == 0) return;

        uint256 targetAave = (totalAssetBalance * aaveAllocation) / TOTAL_BASIS_POINTS;
        uint256 currentAave = aaveStrategy.totalAssets();

        if (currentAave > targetAave) {
            // Withdraw from Aave, deposit to Spark
            uint256 toMove = currentAave - targetAave;
            aaveStrategy.withdraw(toMove, address(this));
            sparkStrategy.deposit(toMove);
        } else if (currentAave < targetAave) {
            // Withdraw from Spark, deposit to Aave
            uint256 toMove = targetAave - currentAave;
            uint256 sparkBalance = sparkStrategy.totalAssets();
            if (toMove > sparkBalance) toMove = sparkBalance;
            sparkStrategy.withdraw(toMove, address(this));
            aaveStrategy.deposit(toMove);
        }
    }
}
