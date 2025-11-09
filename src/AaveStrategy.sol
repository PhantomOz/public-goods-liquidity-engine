// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAavePool} from "./interfaces/IAavePool.sol";

/**
 * @title AaveStrategy
 * @notice Strategy contract that deposits assets into Aave v3 to generate yield
 * @dev Integrates with Aave's Pool contract to supply assets and earn lending yield
 */
contract AaveStrategy is Ownable {
    using SafeERC20 for IERC20;

    /// @notice The Aave v3 Pool contract
    IAavePool public immutable aavePool;

    /// @notice The underlying asset being deposited
    IERC20 public immutable asset;

    /// @notice The aToken received from Aave (interest-bearing token)
    IERC20 public immutable aToken;

    /// @notice The vault that owns this strategy
    address public vault;

    /// @notice Total assets deposited to Aave
    uint256 public totalDeposited;

    // Events
    event Deposited(uint256 amount);
    event Withdrawn(uint256 amount);
    event YieldHarvested(uint256 yieldAmount);
    event VaultUpdated(address indexed oldVault, address indexed newVault);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error InsufficientBalance();

    modifier onlyVault() {
        if (msg.sender != vault && msg.sender != owner()) revert Unauthorized();
        _;
    }

    /**
     * @notice Initialize the Aave strategy
     * @param _aavePool Address of Aave v3 Pool
     * @param _asset Underlying asset to deposit
     * @param _aToken Aave aToken address for the asset
     * @param _vault Vault contract that will use this strategy
     */
    constructor(
        address _aavePool,
        address _asset,
        address _aToken,
        address _vault
    ) Ownable(msg.sender) {
        if (_aavePool == address(0)) revert InvalidAddress();
        if (_asset == address(0)) revert InvalidAddress();
        if (_aToken == address(0)) revert InvalidAddress();
        if (_vault == address(0)) revert InvalidAddress();

        aavePool = IAavePool(_aavePool);
        asset = IERC20(_asset);
        aToken = IERC20(_aToken);
        vault = _vault;

        // Approve Aave pool to spend assets
        asset.approve(_aavePool, type(uint256).max);
    }

    /**
     * @notice Deposit assets into Aave
     * @param amount Amount of assets to deposit
     * @return shares The amount of shares received (same as amount for this strategy)
     */
    function deposit(uint256 amount) external onlyVault returns (uint256) {
        if (amount == 0) return 0;

        // Transfer assets from vault
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Supply to Aave
        aavePool.supply(address(asset), amount, address(this), 0);

        totalDeposited += amount;

        emit Deposited(amount);
        
        return amount; // Return the deposited amount as shares
    }

    /**
     * @notice Withdraw assets from Aave
     * @param amount Amount of assets to withdraw
     * @param recipient Address to receive the withdrawn assets
     */
    function withdraw(uint256 amount, address recipient) external onlyVault returns (uint256) {
        if (amount == 0) return 0;
        if (recipient == address(0)) revert InvalidAddress();

        // Withdraw from Aave
        uint256 withdrawn = aavePool.withdraw(address(asset), amount, recipient);

        if (withdrawn > totalDeposited) {
            totalDeposited = 0;
        } else {
            totalDeposited -= withdrawn;
        }

        emit Withdrawn(withdrawn);
        return withdrawn;
    }

    /**
     * @notice Get total balance including accrued yield
     * @return Total assets in strategy (principal + yield)
     */
    function totalAssets() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    /**
     * @notice Calculate current yield (difference between total assets and deposited)
     * @return Current unrealized yield
     */
    function currentYield() public view returns (uint256) {
        uint256 total = totalAssets();
        if (total <= totalDeposited) return 0;
        return total - totalDeposited;
    }

    /**
     * @notice Harvest yield and send to vault
     * @return yieldAmount Amount of yield harvested
     */
    function harvest() external onlyVault returns (uint256 yieldAmount) {
        yieldAmount = currentYield();
        
        if (yieldAmount == 0) return 0;

        // Withdraw yield from Aave
        aavePool.withdraw(address(asset), yieldAmount, vault);

        emit YieldHarvested(yieldAmount);
    }

    /**
     * @notice Update the vault address
     * @param _newVault New vault address
     */
    function setVault(address _newVault) external onlyOwner {
        if (_newVault == address(0)) revert InvalidAddress();
        address oldVault = vault;
        vault = _newVault;
        emit VaultUpdated(oldVault, _newVault);
    }

    /**
     * @notice Emergency withdraw all assets
     * @param recipient Address to receive assets
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        if (recipient == address(0)) revert InvalidAddress();
        
        uint256 balance = totalAssets();
        if (balance > 0) {
            aavePool.withdraw(address(asset), balance, recipient);
        }
        
        totalDeposited = 0;
    }
}
