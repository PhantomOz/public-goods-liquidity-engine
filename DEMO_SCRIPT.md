# Demo Script - Public Goods Liquidity Engine

## Complete User Journey for Hackathon Demo

This script demonstrates the full lifecycle of the platform: from user deposits, through yield generation, to democratic allocation via quadratic funding.

---

## Setup: Deployed Contracts

```
QuadraticFundingSplitter: 0x35391ca5F9bEb7f4488671fCbad0Ee709603Fec4
PublicGoodsVault:         0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680
YieldAggregator:          0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2
AaveStrategy:             0x2876CC2a624fe603434404d9c10B097b737dE983
SparkStrategy:            0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082
```

---

## Act 1: User Deposits DAI into Vault

### Scene 1: Get DAI from Mainnet Whale

```bash
# Set environment variables
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
export VAULT="0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680"
export DAI="0x6B175474E89094C44Da98b954EedeAC495271d0F"
export WHALE="0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf"
export USER_ADDRESS="YOUR_ADDRESS_HERE"

# Impersonate DAI whale (Polygon Bridge)
cast rpc anvil_impersonateAccount $WHALE --rpc-url $TENDERLY_RPC

# Transfer 10,000 DAI to user
cast send $DAI \
  "transfer(address,uint256)" \
  $USER_ADDRESS \
  10000000000000000000000 \
  --from $WHALE \
  --rpc-url $TENDERLY_RPC \
  --unlocked

# Verify balance
cast call $DAI "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $TENDERLY_RPC
# Expected: 10000000000000000000000 (10,000 DAI)
```

### Scene 2: Approve Vault to Spend DAI

```bash
# Approve vault to spend 10,000 DAI
cast send $DAI \
  "approve(address,uint256)" \
  $VAULT \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Verify allowance
cast call $DAI "allowance(address,address)(uint256)" $USER_ADDRESS $VAULT --rpc-url $TENDERLY_RPC
# Expected: 10000000000000000000000
```

### Scene 3: Deposit DAI into Vault

```bash
# Deposit 10,000 DAI and receive pgDAI shares
cast send $VAULT \
  "deposit(uint256,address)" \
  10000000000000000000000 \
  $USER_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check pgDAI balance (vault shares)
cast call $VAULT "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $TENDERLY_RPC
# Expected: ~10000000000000000000000 (1:1 initially)

# Check total assets in vault
cast call $VAULT "totalAssets()(uint256)" --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"The user now holds pgDAI shares representing their deposit. These shares will accrue yield automatically."*

---

## Act 2: Deploy Funds to Yield Strategies

### Scene 4: Keeper Deploys Idle Funds

```bash
export AGGREGATOR="0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2"

# Check idle balance before deployment
cast call $VAULT "getIdleBalance()(uint256)" --rpc-url $TENDERLY_RPC

# Deploy 8,000 DAI to strategies (keeping 2,000 for liquidity)
cast send $VAULT \
  "depositToStrategies(uint256)" \
  8000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check deployment across strategies
echo "=== Aave Strategy Balance ==="
cast call $AGGREGATOR "getAaveBalance()(uint256)" --rpc-url $TENDERLY_RPC

echo "=== Spark Strategy Balance ==="
cast call $AGGREGATOR "getSparkBalance()(uint256)" --rpc-url $TENDERLY_RPC

echo "=== Total Deployed ==="
cast call $AGGREGATOR "totalDeployed()(uint256)" --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"Funds are now split between Aave v3 (lending) and Spark Protocol (sDAI), generating yield from both sources."*

---

## Act 3: Yield Generation (Time Pass Simulation)

### Scene 5: Simulate Time Passage and Check Yield

```bash
# On Tenderly fork, we can simulate time passage
# For demo, we'll check current yield immediately

echo "=== Current Yield from Aave ==="
cast call 0x2876CC2a624fe603434404d9c10B097b737dE983 "currentYield()(uint256)" --rpc-url $TENDERLY_RPC

echo "=== Current Yield from Spark ==="
cast call 0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082 "currentYield()(uint256)" --rpc-url $TENDERLY_RPC

# Alternative: Increase time by 30 days (Tenderly supports this)
cast rpc evm_increaseTime 2592000 --rpc-url $TENDERLY_RPC
cast rpc evm_mine --rpc-url $TENDERLY_RPC

# Check yield again
echo "=== Yield After 30 Days ==="
cast call $VAULT "getYield()(uint256)" --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"As time passes, both Aave lending and Spark's sDAI accumulate yield. This yield will be donated to public goods projects."*

---

## Act 4: Register Public Goods Projects

### Scene 6: Register 3 Demo Projects

```bash
export SPLITTER="0x35391ca5F9bEb7f4488671fCbad0Ee709603Fec4"

# Register Project 1: Open Source Library
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x1111111111111111111111111111111111111111 \
  "Web3 Security Library" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Register Project 2: Climate Tech Initiative
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x2222222222222222222222222222222222222222 \
  "Carbon Offset Protocol" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Register Project 3: Educational Platform
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x3333333333333333333333333333333333333333 \
  "DeFi Education DAO" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Verify projects registered
cast call $SPLITTER "getProjectCount()(uint256)" --rpc-url $TENDERLY_RPC
# Expected: 3
```

**Demo Point**: *"Three public goods projects are now registered and ready to receive democratic funding."*

---

## Act 5: Start Funding Round

### Scene 7: Harvest Yield and Start Round

```bash
# Harvest accumulated yield from strategies
cast send $VAULT \
  "harvest()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check vault shares (pgDAI) balance in splitter
cast call $VAULT "balanceOf(address)(uint256)" $SPLITTER --rpc-url $TENDERLY_RPC

# Start new funding round (7 day duration)
cast send $SPLITTER \
  "startRound(uint256)" \
  604800 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check current round
cast call $SPLITTER "currentRound()(uint256)" --rpc-url $TENDERLY_RPC
# Expected: 1

# Top up the matching pool with pgDAI (required before ending the round)
cast send $VAULT \
  "approve(address,uint256)" \
  $SPLITTER \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

cast send $SPLITTER \
  "addToMatchingPool(uint256)" \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy
```

**Demo Point**: *"Yield has been harvested, the round is open, and we’ve seeded the matching pool so community voting can allocate funds."*

---

## Act 6: Community Voting (Quadratic Funding)

### Scene 8: Multiple Users Vote

```bash
# Get some pgDAI for voting (users already have from deposits)
# Or transfer from vault holder

# User 1 votes with 100 pgDAI split across projects
cast send $SPLITTER \
  "vote(uint256,uint256)" \
  0 \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

cast send $SPLITTER \
  "vote(uint256,uint256)" \
  1 \
  30000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

cast send $SPLITTER \
  "vote(uint256,uint256)" \
  2 \
  20000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check vote counts
echo "=== Project 0 Votes ==="
cast call $SPLITTER "getProjectVotes(uint256,uint256)(uint256)" 0 1 --rpc-url $TENDERLY_RPC

echo "=== Project 1 Votes ==="
cast call $SPLITTER "getProjectVotes(uint256,uint256)(uint256)" 1 1 --rpc-url $TENDERLY_RPC

echo "=== Project 2 Votes ==="
cast call $SPLITTER "getProjectVotes(uint256,uint256)(uint256)" 2 1 --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"Community members vote by allocating their pgDAI tokens. Quadratic funding means smaller contributors have disproportionate impact."*

---

## Act 7: End Round and Distribute Funds

### Scene 9: Calculate QF Scores and Distribute

```bash
# End the round, calculate quadratic funding scores, and distribute matching pool
cast send $SPLITTER \
  "endRound()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check quadratic funding scores
echo "=== Project 0 QF Score ==="
cast call $SPLITTER "getProjectScore(uint256,uint256)(uint256)" 0 1 --rpc-url $TENDERLY_RPC

echo "=== Project 1 QF Score ==="
cast call $SPLITTER "getProjectScore(uint256,uint256)(uint256)" 1 1 --rpc-url $TENDERLY_RPC

echo "=== Project 2 QF Score ==="
cast call $SPLITTER "getProjectScore(uint256,uint256)(uint256)" 2 1 --rpc-url $TENDERLY_RPC

# Check project balances
echo "=== Project 0 Received ==="
cast call $VAULT "balanceOf(address)(uint256)" 0x1111111111111111111111111111111111111111 --rpc-url $TENDERLY_RPC

echo "=== Project 1 Received ==="
cast call $VAULT "balanceOf(address)(uint256)" 0x2222222222222222222222222222222222222222 --rpc-url $TENDERLY_RPC

echo "=== Project 2 Received ==="
cast call $VAULT "balanceOf(address)(uint256)" 0x3333333333333333333333333333333333333333 --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"Funds distributed! Projects received pgDAI shares proportional to their quadratic funding scores. They can now redeem for DAI."*

---

## Act 8: Project Redeems Funding

### Scene 10: Project Withdraws DAI

```bash
# Project 1 redeems their pgDAI for DAI
export PROJECT1="0x1111111111111111111111111111111111111111"

# Check pgDAI balance
PROJECT_SHARES=$(cast call $VAULT "balanceOf(address)(uint256)" $PROJECT1 --rpc-url $TENDERLY_RPC)
echo "Project 1 pgDAI shares: $PROJECT_SHARES"

# Redeem for DAI
cast send $VAULT \
  "redeem(uint256,address,address)" \
  $PROJECT_SHARES \
  $PROJECT1 \
  $PROJECT1 \
  --private-key $PRIVATE_KEY_PROJECT1 \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check DAI balance
cast call $DAI "balanceOf(address)(uint256)" $PROJECT1 --rpc-url $TENDERLY_RPC
```

**Demo Point**: *"Projects can redeem their vault shares for DAI anytime, maintaining liquidity while funding public goods."*

---

## Bonus: Advanced Features Demo

### Rebalancing Between Strategies

```bash
# Owner can adjust allocation (e.g., 70% Aave, 30% Spark)
cast send $AGGREGATOR \
  "setAllocation(uint256)" \
  7000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Trigger rebalance
cast send $AGGREGATOR \
  "rebalance()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# Check new balances
cast call $AGGREGATOR "getAaveBalance()(uint256)" --rpc-url $TENDERLY_RPC
cast call $AGGREGATOR "getSparkBalance()(uint256)" --rpc-url $TENDERLY_RPC
```

### Emergency Withdrawal

```bash
# In case of emergency, withdraw all funds from strategies
cast send $VAULT \
  "emergencyWithdrawFromStrategies()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy

# All funds now idle in vault
cast call $VAULT "getIdleBalance()(uint256)" --rpc-url $TENDERLY_RPC
```

---

## Complete Demo Flow Summary

```
1. ✅ User deposits 10,000 DAI → Receives 10,000 pgDAI
2. ✅ Keeper deploys 8,000 DAI → Split between Aave (50%) and Spark (50%)
3. ✅ Yield accumulates → ~2-5% APY from both protocols
4. ✅ 3 Projects register → Web3 Security, Carbon Offset, DeFi Education
5. ✅ Harvest yield → ~100-200 DAI collected
6. ✅ Start funding round → Round 1 begins (7 day window)
7. ✅ Seed matching pool & vote → 50 pgDAI added, community allocates support
8. ✅ End round → Quadratic scores calculated and funds distributed automatically
10. ✅ Projects redeem → Convert pgDAI to DAI for operations
```

---

## Key Metrics to Highlight

```bash
# Total Value Locked
cast call $VAULT "totalAssets()(uint256)" --rpc-url $TENDERLY_RPC

# Total Yield Generated
cast call $VAULT "getYield()(uint256)" --rpc-url $TENDERLY_RPC

# Number of Projects Funded
cast call $SPLITTER "getProjectCount()(uint256)" --rpc-url $TENDERLY_RPC

# Total Distributed
cast call $SPLITTER "getTotalDistributed(uint256)(uint256)" 1 --rpc-url $TENDERLY_RPC

# Strategy Performance
echo "Aave APY: 2.5%"
echo "Spark APY: 4.8%"
echo "Blended APY: 3.65%"
```

---

## Talking Points for Demo

1. **Passive Income for Good**: "Users earn yield while automatically funding public goods"

2. **Dual-Protocol Safety**: "Diversified across Aave and Spark reduces single-protocol risk"

3. **Democratic Allocation**: "Quadratic funding gives voice to smaller contributors"

4. **Full Transparency**: "All transactions on-chain, verifiable by anyone"

5. **Octant v2 Integration**: "Designed to integrate with Octant's ecosystem growth engine"

6. **Liquidity Preserved**: "Projects can redeem instantly, no lock-ups"

7. **Composable Design**: "ERC-4626 standard allows integration with other DeFi protocols"

8. **Scalable Architecture**: "Can add more yield strategies (Compound, Morpho, etc.)"

---

## Quick Demo Script (5 minutes)

```bash
# Set up environment
source setup-demo.sh

# 1. Deposit (30 sec)
deposit_dai 10000

# 2. Deploy to strategies (30 sec)
deploy_to_strategies 8000

# 3. Show yield accumulation (30 sec)
show_yield_stats

# 4. Register projects (1 min)
register_projects

# 5. Voting demo (1 min)
simulate_community_voting

# 6. Distribution (1 min)
end_round_and_distribute

# 7. Show results (1 min)
show_final_stats
```

---

## Testing Checklist

- [ ] User can deposit DAI
- [ ] Vault issues pgDAI shares 1:1
- [ ] Funds deploy to both Aave and Spark
- [ ] Yield accumulates over time
- [ ] Projects can be registered
- [ ] Funding rounds can start
- [ ] Users can vote with pgDAI
- [ ] QF scores calculated correctly
- [ ] Funds distributed proportionally
- [ ] Projects can redeem pgDAI for DAI
- [ ] Rebalancing works between strategies
- [ ] Emergency withdrawal functions
- [ ] All events emitted correctly
- [ ] Gas costs reasonable

---

## Expected Results

| Metric | Value |
|--------|-------|
| Initial Deposit | 10,000 DAI |
| Deployed to Strategies | 8,000 DAI |
| 30-Day Yield | ~100 DAI (3.65% APY) |
| Projects Registered | 3 |
| Votes Cast | ~100 pgDAI |
| Funds Distributed | 100 pgDAI |
| Gas Cost (Total) | ~0.05 ETH |

---

## Troubleshooting

**Issue**: Transaction reverts with "Insufficient allowance"
```bash
# Solution: Increase approval
cast send $DAI "approve(address,uint256)" $VAULT $(cast max-uint) --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC
```

**Issue**: "Insufficient idle balance"
```bash
# Solution: Withdraw from strategies first
cast send $VAULT "withdrawFromStrategies(uint256)" AMOUNT --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC
```

**Issue**: "Round not active"
```bash
# Solution: Start a new round
cast send $SPLITTER "startRound()" --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC
```

---

## Demo Video Script Outline

**[0:00 - 0:30] Hook**
- "What if your DeFi yield could fund public goods automatically?"

**[0:30 - 1:30] Problem**
- Public goods funding is fragmented
- Users want yield but also want to give back
- Current solutions require active management

**[1:30 - 3:00] Solution**
- Show deposit flow
- Demonstrate dual-strategy deployment
- Highlight automatic yield donation

**[3:00 - 4:30] Community Power**
- Project registration
- Quadratic funding voting
- Democratic distribution

**[4:30 - 5:00] Call to Action**
- Built for Octant v2
- Try on Tenderly fork
- Contribute on GitHub

---

## Next Steps After Demo

1. Deploy to mainnet with real Octant integration
2. Add more yield strategies (Compound, Morpho, Yearn)
3. Build web interface for easier interaction
4. Integrate with Octant's project registry
5. Add governance for strategy selection
6. Implement time-weighted voting
7. Create project impact metrics dashboard
