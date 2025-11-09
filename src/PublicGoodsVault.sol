// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title PublicGoodsVault
 * @notice ERC-4626 compliant yield-donating vault for Octant v2
 * @dev All generated yield is minted as shares and transferred to an allocation address
 * Principal deposits are fully preserved and withdrawable at any time
 */
contract PublicGoodsVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Address that receives all generated yield as vault shares
    address public allocationAddress;

    /// @notice Address authorized to trigger harvest operations
    address public keeper;

    /// @notice Emergency admin for crisis situations
    address public emergencyAdmin;

    /// @notice Strategy contract that generates yield
    address public strategy;

    /// @notice Total assets tracked at last harvest
    uint256 public lastHarvestedAssets;

    /// @notice Performance fee percentage (basis points, max 10%)
    uint256 public performanceFee; // e.g., 100 = 1%

    /// @notice Maximum performance fee allowed (10%)
    uint256 public constant MAX_PERFORMANCE_FEE = 1000;

    /// @notice Protocol fee recipient
    address public feeRecipient;

    /// @notice Vault is paused for deposits
    bool public paused;

    // Events
    event AllocationAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event KeeperUpdated(address indexed oldKeeper, address indexed newKeeper);
    event EmergencyAdminUpdated(address indexed oldAdmin, address indexed newAdmin);
    event StrategyUpdated(address indexed oldStrategy, address indexed newStrategy);
    event YieldHarvested(uint256 yieldAmount, uint256 sharesMinted, uint256 feeAmount);
    event PerformanceFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event VaultPausedUpdated(bool isPaused);
    event EmergencyWithdraw(address indexed token, uint256 amount);

    // Errors
    error Unauthorized();
    error InvalidAddress();
    error InvalidFee();
    error VaultPaused();
    error NoYieldGenerated();

    modifier onlyKeeper() {
        if (msg.sender != keeper && msg.sender != owner()) revert Unauthorized();
        _;
    }

    modifier onlyEmergencyAdmin() {
        if (msg.sender != emergencyAdmin && msg.sender != owner()) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert VaultPaused();
        _;
    }

    /**
     * @notice Initializes the vault with base asset and configuration
     * @param _asset The underlying ERC20 asset
     * @param _name Name of the vault share token
     * @param _symbol Symbol of the vault share token
     * @param _allocationAddress Address to receive yield shares
     * @param _keeper Address authorized to trigger harvests
     * @param _emergencyAdmin Address for emergency operations
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _allocationAddress,
        address _keeper,
        address _emergencyAdmin
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {
        if (_allocationAddress == address(0)) revert InvalidAddress();
        if (_keeper == address(0)) revert InvalidAddress();
        if (_emergencyAdmin == address(0)) revert InvalidAddress();

        allocationAddress = _allocationAddress;
        keeper = _keeper;
        emergencyAdmin = _emergencyAdmin;
        feeRecipient = msg.sender;
        performanceFee = 100; // 1% default
    }

    /**
     * @notice Total assets under management including strategy deployment
     */
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        uint256 strategyBalance = strategy != address(0) ? IERC20(asset()).balanceOf(strategy) : 0;
        return vaultBalance + strategyBalance;
    }

    /**
     * @notice Deposit assets and mint shares (override to add pause check)
     */
    function deposit(uint256 assets, address receiver) public override whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /**
     * @notice Mint shares for assets (override to add pause check)
     */
    function mint(uint256 shares, address receiver) public override whenNotPaused returns (uint256) {
        return super.mint(shares, receiver);
    }

    /**
     * @notice Harvest yield and mint shares to allocation address
     * @dev Called by keeper to realize profits and distribute as donations
     */
    function harvest() external onlyKeeper nonReentrant returns (uint256 yieldAmount) {
        // Get current total assets
        uint256 currentAssets = totalAssets();

        // Calculate yield as difference from last harvest
        if (currentAssets <= lastHarvestedAssets) revert NoYieldGenerated();

        yieldAmount = currentAssets - lastHarvestedAssets;

        // Calculate performance fee
        uint256 feeAmount = (yieldAmount * performanceFee) / 10000;
        uint256 netYield = yieldAmount - feeAmount;

        // Convert yield to shares
        uint256 yieldShares = convertToShares(netYield);
        uint256 feeShares = feeAmount > 0 ? convertToShares(feeAmount) : 0;

        // Mint shares to allocation address
        _mint(allocationAddress, yieldShares);

        // Mint fee shares if applicable
        if (feeShares > 0) {
            _mint(feeRecipient, feeShares);
        }

        // Update tracked assets
        lastHarvestedAssets = currentAssets;

        emit YieldHarvested(yieldAmount, yieldShares, feeAmount);
    }

    /**
     * @notice Set the allocation address for yield distribution
     * @param _newAddress New allocation address
     */
    function setAllocationAddress(address _newAddress) external onlyOwner {
        if (_newAddress == address(0)) revert InvalidAddress();
        address oldAddress = allocationAddress;
        allocationAddress = _newAddress;
        emit AllocationAddressUpdated(oldAddress, _newAddress);
    }

    /**
     * @notice Update the keeper address
     * @param _newKeeper New keeper address
     */
    function setKeeper(address _newKeeper) external onlyOwner {
        if (_newKeeper == address(0)) revert InvalidAddress();
        address oldKeeper = keeper;
        keeper = _newKeeper;
        emit KeeperUpdated(oldKeeper, _newKeeper);
    }

    /**
     * @notice Update the emergency admin address
     * @param _newAdmin New emergency admin address
     */
    function setEmergencyAdmin(address _newAdmin) external onlyOwner {
        if (_newAdmin == address(0)) revert InvalidAddress();
        address oldAdmin = emergencyAdmin;
        emergencyAdmin = _newAdmin;
        emit EmergencyAdminUpdated(oldAdmin, _newAdmin);
    }

    /**
     * @notice Set the strategy contract
     * @param _strategy New strategy address
     */
    function setStrategy(address _strategy) external onlyOwner {
        address oldStrategy = strategy;
        strategy = _strategy;
        emit StrategyUpdated(oldStrategy, _strategy);
    }

    /**
     * @notice Update performance fee
     * @param _newFee New fee in basis points (max 1000 = 10%)
     */
    function setPerformanceFee(uint256 _newFee) external onlyOwner {
        if (_newFee > MAX_PERFORMANCE_FEE) revert InvalidFee();
        uint256 oldFee = performanceFee;
        performanceFee = _newFee;
        emit PerformanceFeeUpdated(oldFee, _newFee);
    }

    /**
     * @notice Update fee recipient
     * @param _newRecipient New fee recipient address
     */
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert InvalidAddress();
        address oldRecipient = feeRecipient;
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    /**
     * @notice Pause or unpause the vault
     * @param _paused True to pause, false to unpause
     */
    function setPaused(bool _paused) external onlyEmergencyAdmin {
        paused = _paused;
        emit VaultPausedUpdated(_paused);
    }

    /**
     * @notice Emergency withdraw function
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyEmergencyAdmin {
        IERC20(token).safeTransfer(emergencyAdmin, amount);
        emit EmergencyWithdraw(token, amount);
    }

    /**
     * @notice Initialize vault state after first deposits
     */
    function initializeHarvest() external onlyKeeper {
        if (lastHarvestedAssets == 0) {
            lastHarvestedAssets = totalAssets();
        }
    }
}
