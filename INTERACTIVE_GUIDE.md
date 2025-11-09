# Interactive Demo Script Guide for Judges

Welcome! This guide explains how to use the **Interactive.s.sol** script to explore the Public Goods Liquidity Engine platform at your own pace.

## Quick Start

```bash
# Set your environment (already configured if you followed README)
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
export PRIVATE_KEY="your_private_key"

# Now run any function from the script!
```

## Overview

The **Interactive.s.sol** script provides 25+ individual functions that judges can call to:
- ✅ Test specific features in isolation
- ✅ Skip parts of the demo to focus on what matters
- ✅ Experiment with different scenarios
- ✅ Verify system behavior with custom inputs

Unlike the linear `run-demo.sh` bash script, this gives you **full control** over the demonstration flow.

---

## Function Categories

### 1️⃣ Getting Started

#### Get Test DAI
```bash
forge script script/Interactive.s.sol --sig "getDai()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Transfers 10,000 DAI from a whale to your address for testing.

#### Check Your Balance
```bash
forge script script/Interactive.s.sol --sig "checkBalance()" \
  --rpc-url $TENDERLY_RPC
```
**What it does:** Shows your DAI and pgDAI balances.

---

### 2️⃣ Vault Interactions

#### Deposit DAI
```bash
# Deposit 1000 DAI (amount in wei: 1000 * 10^18)
forge script script/Interactive.s.sol \
  --sig "depositToVault(uint256)" 1000000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** 
- Approves vault to spend your DAI
- Deposits DAI and receives pgDAI shares
- Shows exchange rate

**Try different amounts:**
- 100 DAI: `100000000000000000000`
- 5000 DAI: `5000000000000000000000`

#### Withdraw from Vault
```bash
# Withdraw 500 pgDAI shares
forge script script/Interactive.s.sol \
  --sig "withdrawFromVault(uint256)" 500000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Redeems pgDAI shares back to DAI.

---

### 3️⃣ Yield Strategy Management

#### Deploy Funds to Strategies
```bash
# Deploy 800 DAI to Aave/Spark strategies
forge script script/Interactive.s.sol \
  --sig "deployToStrategies(uint256)" 800000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Moves idle DAI from vault to yield-generating protocols.

**Current Allocation:** 0% Aave, 100% Spark (configurable)

#### Harvest Yield
```bash
forge script script/Interactive.s.sol --sig "harvestYield()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** 
- Collects accumulated yield from Aave & Spark
- Converts yield to pgDAI shares
- Sends shares to QuadraticFundingSplitter for distribution

**This is the core mechanism!** Yield → Public Goods

#### Withdraw from Strategies
```bash
# Withdraw 200 DAI back to vault
forge script script/Interactive.s.sol \
  --sig "withdrawFromStrategies(uint256)" 200000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Pulls funds back from strategies (for rebalancing or user withdrawals).

---

### 4️⃣ Project Registration

#### Register a Project
```bash
forge script script/Interactive.s.sol \
  --sig "registerProject(address,string)" \
  0xYourProjectAddress "Your Project Name" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Registers a public goods project to receive funding.

**Example:**
```bash
forge script script/Interactive.s.sol \
  --sig "registerProject(address,string)" \
  0x1111111111111111111111111111111111111111 "Web3 Security Library" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```

#### List All Projects
```bash
forge script script/Interactive.s.sol --sig "listProjects()" \
  --rpc-url $TENDERLY_RPC
```
**What it does:** Shows all registered projects with IDs and addresses.

---

### 5️⃣ Funding Rounds

#### Start a Funding Round
```bash
forge script script/Interactive.s.sol --sig "startRound()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** 
- Starts a new funding round (7 days duration)
- Enables community voting
- Increments round ID

#### Add to Matching Pool
```bash
# Add 100 pgDAI to the matching pool
forge script script/Interactive.s.sol \
  --sig "addToMatchingPool(uint256)" 100000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Increases the matching funds for quadratic funding distribution.

**This is harvested yield!** The more yield harvested, the bigger the matching pool.

---

### 6️⃣ Voting

#### Vote for a Project
```bash
# Vote with 50 pgDAI for project ID 0
forge script script/Interactive.s.sol \
  --sig "vote(uint256,uint256)" 0 50000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:**
- Casts vote for specified project
- Transfers pgDAI to splitter contract
- Updates project's total votes

**Try voting for multiple projects:**
```bash
# Vote for project 1
forge script script/Interactive.s.sol \
  --sig "vote(uint256,uint256)" 1 30000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy

# Vote for project 2
forge script script/Interactive.s.sol \
  --sig "vote(uint256,uint256)" 2 20000000000000000000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```

---

### 7️⃣ Distribution

#### End Round and Distribute
```bash
forge script script/Interactive.s.sol --sig "endRound()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:**
1. Ends the current funding round
2. Calculates quadratic funding scores
3. **Automatically distributes funds** to projects
4. Projects receive: direct contributions + matching funds

**Quadratic Funding Formula:**
- Score = sqrt(totalVotes) × uniqueVoters
- Matching distribution = (projectScore / totalScore) × matchingPool
- Final amount = directVotes + matchingAmount

---

### 8️⃣ System Monitoring

#### View All Stats
```bash
forge script script/Interactive.s.sol --sig "viewStats()" \
  --rpc-url $TENDERLY_RPC
```
**Shows:**
- Total vault assets & shares
- Idle vs deployed DAI
- Number of projects
- Current round
- Available matching pool

#### View Round Details
```bash
# View round 1 details
forge script script/Interactive.s.sol \
  --sig "viewRound(uint256)" 1 \
  --rpc-url $TENDERLY_RPC
```
**Shows:**
- Matching pool size
- All projects with votes
- Unique voters per project
- Total funds received

#### View Strategy Allocation
```bash
forge script script/Interactive.s.sol --sig "viewAllocation()" \
  --rpc-url $TENDERLY_RPC
```
**Shows:** Current split between Aave (0%) and Spark (100%).

#### View Distribution Info
```bash
forge script script/Interactive.s.sol \
  --sig "distribute(uint256)" 1 \
  --rpc-url $TENDERLY_RPC
```
**Shows:** Matching pool details for a specific round.

---

### 9️⃣ Advanced Admin Functions

#### Rebalance Strategies
```bash
forge script script/Interactive.s.sol --sig "rebalanceStrategies()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Adjusts deployment to match target allocation percentages.

#### Set New Allocation
```bash
# Set 30% Aave, 70% Spark (3000 = 30%)
forge script script/Interactive.s.sol \
  --sig "setAllocation(uint256)" 3000 \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Updates strategy allocation percentages (0-10000 = 0-100%).

---

### 🔟 Complete Demo Scenario

#### Run Full Automated Demo
```bash
forge script script/Interactive.s.sol --sig "runFullDemo()" \
  --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**What it does:** Executes a complete end-to-end scenario:
1. Get 10,000 DAI
2. Deposit to vault
3. Deploy to strategies
4. Register 3 projects
5. Harvest yield
6. Add to matching pool
7. Start funding round
8. Vote for all projects
9. End round and distribute

**Perfect for a quick complete demonstration!**

---

## Example Usage Scenarios

### Scenario 1: Basic User Journey
```bash
# 1. Get DAI
forge script script/Interactive.s.sol --sig "getDai()" --rpc-url $TENDERLY_RPC --broadcast --legacy

# 2. Check balance
forge script script/Interactive.s.sol --sig "checkBalance()" --rpc-url $TENDERLY_RPC

# 3. Deposit 1000 DAI
forge script script/Interactive.s.sol --sig "depositToVault(uint256)" 1000000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# 4. View stats
forge script script/Interactive.s.sol --sig "viewStats()" --rpc-url $TENDERLY_RPC
```

### Scenario 2: Yield Generation
```bash
# 1. Deploy 800 DAI to strategies
forge script script/Interactive.s.sol --sig "deployToStrategies(uint256)" 800000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# 2. Check allocation
forge script script/Interactive.s.sol --sig "viewAllocation()" --rpc-url $TENDERLY_RPC

# 3. Wait a bit, then harvest (in real demo, yield accrues over time)
forge script script/Interactive.s.sol --sig "harvestYield()" --rpc-url $TENDERLY_RPC --broadcast --legacy

# 4. View stats to see splitter balance
forge script script/Interactive.s.sol --sig "viewStats()" --rpc-url $TENDERLY_RPC
```

### Scenario 3: Governance & Distribution
```bash
# 1. Register projects
forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x1111111111111111111111111111111111111111 "Project A" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x2222222222222222222222222222222222222222 "Project B" --rpc-url $TENDERLY_RPC --broadcast --legacy

# 2. List projects
forge script script/Interactive.s.sol --sig "listProjects()" --rpc-url $TENDERLY_RPC

# 3. Start round
forge script script/Interactive.s.sol --sig "startRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy

# 4. Add to matching pool
forge script script/Interactive.s.sol --sig "addToMatchingPool(uint256)" 100000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# 5. Vote for projects
forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 0 50000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 1 30000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# 6. View round details
forge script script/Interactive.s.sol --sig "viewRound(uint256)" 1 --rpc-url $TENDERLY_RPC

# 7. End round (also distributes)
forge script script/Interactive.s.sol --sig "endRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```

---

## Tips for Judges

### 🎯 Want to test a specific feature?
Jump directly to the relevant function! No need to run the entire flow.

### 🔍 Want to see the code?
Open `script/Interactive.s.sol` - every function is documented with:
- Clear descriptions
- Parameter explanations
- Console output for transparency

### 📊 Want to verify state?
Use the view functions (`viewStats`, `viewRound`, `checkBalance`) between actions.

### 🧪 Want to experiment?
Try different:
- Deposit amounts
- Vote distributions
- Strategy allocations
- Number of projects

### ⚡ Want the quick version?
Run `runFullDemo()` for a complete scenario in one command.

---

## Function Reference

| Category | Function | Parameters | Broadcast? |
|----------|----------|------------|------------|
| **Setup** | getDai | none | ✅ |
| | checkBalance | none | ❌ |
| **Vault** | depositToVault | uint256 amount | ✅ |
| | withdrawFromVault | uint256 shares | ✅ |
| **Strategies** | deployToStrategies | uint256 amount | ✅ |
| | harvestYield | none | ✅ |
| | withdrawFromStrategies | uint256 amount | ✅ |
| | rebalanceStrategies | none | ✅ |
| | setAllocation | uint256 aavePercent | ✅ |
| **Projects** | registerProject | address, string | ✅ |
| | listProjects | none | ❌ |
| **Rounds** | startRound | none | ✅ |
| | addToMatchingPool | uint256 amount | ✅ |
| | vote | uint256 id, uint256 amount | ✅ |
| | endRound | none | ✅ |
| **Views** | viewStats | none | ❌ |
| | viewRound | uint256 roundId | ❌ |
| | viewAllocation | none | ❌ |
| | distribute | uint256 roundId | ❌ |
| **Demo** | runFullDemo | none | ✅ |

**Broadcast = ✅:** Function modifies state (requires `--broadcast --legacy`)  
**Broadcast = ❌:** View-only function (no `--broadcast` needed)

---

## Amount Formatting

All amounts use **wei** (18 decimals):

| DAI/pgDAI | Wei (parameter value) |
|-----------|----------------------|
| 1 | 1000000000000000000 |
| 10 | 10000000000000000000 |
| 100 | 100000000000000000000 |
| 1000 | 1000000000000000000000 |
| 10000 | 10000000000000000000000 |

**Quick conversion:** Add 18 zeros after your desired amount.

---

## Contract Addresses (Pre-Deployed)

All contracts are **live** on Tenderly Mainnet Fork:

- **Vault:** `0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680`
- **Splitter:** `0x381D85647AaB3F16EAB7000963D3Ce56792479fD`
- **Aggregator:** `0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2`
- **DAI:** `0x6B175474E89094C44Da98b954EedeAC495271d0F`

---

## Troubleshooting

### Issue: "Insufficient DAI balance"
**Solution:** Run `getDai()` first to get test DAI.

### Issue: "Round not active"
**Solution:** Call `startRound()` before voting.

### Issue: "Invalid project"
**Solution:** Use `listProjects()` to see valid project IDs (starts at 0).

### Issue: Command not found
**Solution:** Make sure you're in the `public-goods-liquidity-engine/` directory.

### Issue: RPC errors
**Solution:** The Tenderly fork is live and working. Check your `TENDERLY_RPC` export.

---

## Why This Matters for the Hackathon

### ✅ Innovation
Interactive script allows judges to explore **any part** of the platform independently.

### ✅ Transparency
Every function has console output showing exactly what's happening.

### ✅ Flexibility
Choose between:
- **Quick demo:** `runFullDemo()`
- **Guided tour:** `run-demo.sh` bash script
- **Custom exploration:** This interactive script
- **Documentation:** Comprehensive markdown guides

### ✅ Testability
All 25+ functions can be tested in isolation with custom inputs.

---

## Next Steps

1. **Try the quick demo:**
   ```bash
   forge script script/Interactive.s.sol --sig "runFullDemo()" \
     --rpc-url $TENDERLY_RPC --broadcast --legacy
   ```

2. **Or explore step-by-step:**
   Start with `getDai()` and `depositToVault()` then experiment!

3. **Need the big picture?**
   See `README.md`, `DEMO_SCRIPT.md`, or `DEMO_SUMMARY.md`

---

**Built for Octant Hackathon 2024**  
*Where yield meets public goods through quadratic funding*

