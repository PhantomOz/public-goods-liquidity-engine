// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISparkSDai} from "./interfaces/ISparkSDai.sol";

/**
 * @title SparkStrategy
 * @notice Strategy contract that deposits DAI into Spark's sDAI vault to generate yield
 * @dev Integrates with Spark's ERC-4626 compliant sDAI (Savings DAI) vault
 */
contract SparkStrategy is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Spark's sDAI vault (ERC-4626)
    ISparkSDai public immutable sDAI;

    /// @notice DAI token
    IERC20 public immutable dai;

    /// @notice The vault that owns this strategy
    address public vault;

    /// @notice Total DAI deposited (tracked for yield calculation)
    uint256 public totalDeposited;

    // Events
    event Deposited(uint256 daiAmount, uint256 sharesReceived);
    event Withdrawn(uint256 sharesRedeemed, uint256 daiAmount);
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
     * @notice Initialize the Spark strategy
     * @param _sDAI Address of Spark's sDAI vault
     * @param _dai Address of DAI token
     * @param _vault Vault contract that will use this strategy
     */
    constructor(
        address _sDAI,
        address _dai,
        address _vault
    ) Ownable(msg.sender) {
        if (_sDAI == address(0)) revert InvalidAddress();
        if (_dai == address(0)) revert InvalidAddress();
        if (_vault == address(0)) revert InvalidAddress();

        sDAI = ISparkSDai(_sDAI);
        dai = IERC20(_dai);
        vault = _vault;

        // Approve sDAI vault to spend DAI
        dai.approve(_sDAI, type(uint256).max);
    }

    /**
     * @notice Deposit DAI into Spark sDAI vault
     * @param amount Amount of DAI to deposit
     */
    function deposit(uint256 amount) external onlyVault returns (uint256 shares) {
        if (amount == 0) return 0;

        // Transfer DAI from vault
        dai.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit into sDAI vault (ERC-4626)
        shares = sDAI.deposit(amount, address(this));

        totalDeposited += amount;

        emit Deposited(amount, shares);
    }

    /**
     * @notice Withdraw DAI from Spark sDAI vault
     * @param amount Amount of DAI to withdraw
     * @param recipient Address to receive the withdrawn DAI
     */
    function withdraw(uint256 amount, address recipient) external onlyVault returns (uint256) {
        if (amount == 0) return 0;
        if (recipient == address(0)) revert InvalidAddress();

        // Calculate shares needed for the amount
        uint256 shares = sDAI.convertToShares(amount);
        
        // Ensure we don't try to withdraw more than we have
        uint256 ourShares = sDAI.balanceOf(address(this));
        if (shares > ourShares) {
            shares = ourShares;
        }

        // Redeem from sDAI vault
        uint256 withdrawn = sDAI.redeem(shares, recipient, address(this));

        if (withdrawn > totalDeposited) {
            totalDeposited = 0;
        } else {
            totalDeposited -= withdrawn;
        }

        emit Withdrawn(shares, withdrawn);
        return withdrawn;
    }

    /**
     * @notice Get total DAI value of our sDAI shares
     * @return Total assets in strategy (principal + yield)
     */
    function totalAssets() public view returns (uint256) {
        uint256 shares = sDAI.balanceOf(address(this));
        if (shares == 0) return 0;
        return sDAI.convertToAssets(shares);
    }

    /**
     * @notice Calculate current yield from Spark
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

        // Calculate shares to redeem for yield amount
        uint256 sharesToRedeem = sDAI.convertToShares(yieldAmount);

        // Redeem yield and send to vault
        uint256 actualYield = sDAI.redeem(sharesToRedeem, vault, address(this));

        emit YieldHarvested(actualYield);
        return actualYield;
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
     * @notice Emergency withdraw all sDAI shares
     * @param recipient Address to receive DAI
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        if (recipient == address(0)) revert InvalidAddress();
        
        uint256 shares = sDAI.balanceOf(address(this));
        if (shares > 0) {
            sDAI.redeem(shares, recipient, address(this));
        }
        
        totalDeposited = 0;
    }

    /**
     * @notice Get our current sDAI share balance
     * @return Number of sDAI shares held
     */
    function sharesBalance() external view returns (uint256) {
        return sDAI.balanceOf(address(this));
    }
}
