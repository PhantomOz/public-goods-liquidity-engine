// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockSparkSDai
 * @notice Mock implementation of Spark's sDAI for testing
 */
contract MockSparkSDai is ERC4626 {
    uint256 public yieldAccrued;

    constructor(IERC20 dai) 
        ERC4626(dai) 
        ERC20("Spark Savings DAI", "sDAI") 
    {}

    /**
     * @notice Simulate yield accrual
     * @param amount Amount of yield to add
     */
    function accrueYield(uint256 amount) external {
        // Transfer DAI to this contract to simulate yield
        IERC20(asset()).transferFrom(msg.sender, address(this), amount);
        yieldAccrued += amount;
    }

    /**
     * @notice Override totalAssets to include accrued yield
     */
    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}
