// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title ISparkSDai
 * @notice Interface for Spark's Savings DAI (sDAI) vault
 * @dev sDAI is an ERC-4626 vault that generates yield from Spark lending
 */
interface ISparkSDai is IERC4626 {
    // sDAI inherits all ERC-4626 functions
    // Additional Spark-specific functions can be added here if needed
}
