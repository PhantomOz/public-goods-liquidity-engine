// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockAavePool
 * @notice Mock implementation of Aave v3 Pool for testing
 */
contract MockAavePool {
    mapping(address => address) public aTokens;
    uint256 public constant YIELD_RATE = 500; // 5% APY in basis points

    constructor() {}

    function setAToken(address asset, address aToken) external {
        aTokens[asset] = aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        // Transfer asset from sender
        ERC20(asset).transferFrom(msg.sender, address(this), amount);
        
        // Mint aTokens to recipient
        MockAToken(aTokens[asset]).mintPublic(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        address aToken = aTokens[asset];
        
        // Burn aTokens
        MockAToken(aToken).burnPublic(msg.sender, amount);
        
        // Transfer underlying asset
        ERC20(asset).transfer(to, amount);
        
        return amount;
    }

    function getReserveData(address asset) external view returns (
        uint256,
        uint128,
        uint128,
        uint128,
        uint128,
        uint128,
        uint40,
        uint16,
        address,
        address,
        address,
        address,
        uint128,
        uint128,
        uint128
    ) {
        return (0, 0, 0, 0, 0, 0, 0, 0, aTokens[asset], address(0), address(0), address(0), 0, 0, 0);
    }

    // Simulate yield generation
    function accrueYield(address asset, uint256 amount) external {
        ERC20(asset).transferFrom(msg.sender, address(this), amount);
        MockAToken(aTokens[asset]).mintPublic(msg.sender, amount);
    }
}

/**
 * @title MockAToken
 * @notice Mock aToken for testing
 */
contract MockAToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mintPublic(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burnPublic(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
