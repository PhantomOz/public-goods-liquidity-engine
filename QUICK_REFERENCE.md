# 🎮 Quick Reference Card - Interactive Demo

**For Hackathon Judges: Test Any Feature in Seconds!**

## 🚀 One-Line Commands

### Complete Demo
```bash
forge script script/Interactive.s.sol --sig "runFullDemo()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**Does everything:** Get DAI → Deposit → Deploy → Register projects → Harvest → Vote → Distribute

---

## 🎯 Most Important Functions

### 1️⃣ Get Started (30 seconds)
```bash
# Get test DAI
forge script script/Interactive.s.sol --sig "getDai()" --rpc-url $TENDERLY_RPC --broadcast --legacy

# Check your balance
forge script script/Interactive.s.sol --sig "checkBalance()" --rpc-url $TENDERLY_RPC
```

### 2️⃣ Core Flow (2 minutes)
```bash
# Deposit 1000 DAI
forge script script/Interactive.s.sol --sig "depositToVault(uint256)" 1000000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# Deploy to yield strategies
forge script script/Interactive.s.sol --sig "deployToStrategies(uint256)" 800000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# Harvest yield
forge script script/Interactive.s.sol --sig "harvestYield()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```

### 3️⃣ Governance (2 minutes)
```bash
# Register a project
forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x1111111111111111111111111111111111111111 "My Project" --rpc-url $TENDERLY_RPC --broadcast --legacy

# Start funding round
forge script script/Interactive.s.sol --sig "startRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy

# Add to matching pool
forge script script/Interactive.s.sol --sig "addToMatchingPool(uint256)" 100000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# Vote for project 0
forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 0 50000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy

# End round and distribute
forge script script/Interactive.s.sol --sig "endRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```

### 4️⃣ View System State (instant)
```bash
# See everything
forge script script/Interactive.s.sol --sig "viewStats()" --rpc-url $TENDERLY_RPC

# See round details
forge script script/Interactive.s.sol --sig "viewRound(uint256)" 1 --rpc-url $TENDERLY_RPC

# List all projects
forge script script/Interactive.s.sol --sig "listProjects()" --rpc-url $TENDERLY_RPC
```

---

## 💡 Pro Tips

**Environment Setup** (run once):
```bash
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
export PRIVATE_KEY="your_private_key"
cd public-goods-liquidity-engine
```

**Amount Conversion:**
- 1 DAI/pgDAI = `1000000000000000000` (add 18 zeros)
- 100 DAI = `100000000000000000000`
- 1000 DAI = `1000000000000000000000`

**View vs Broadcast:**
- View functions: Just `--rpc-url $TENDERLY_RPC`
- State-changing: Add `--broadcast --legacy`

---

## 📚 Full Documentation

- **Complete Guide:** `INTERACTIVE_GUIDE.md` (all 25+ functions explained)
- **Script Code:** `script/Interactive.s.sol` (read the implementation)
- **Main README:** `README.md` (architecture overview)

---

## 🎯 Suggested Testing Paths

### Path A: Speed Run (30 seconds)
```bash
forge script script/Interactive.s.sol --sig "runFullDemo()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```

### Path B: Yield Focus (1 minute)
```bash
forge script script/Interactive.s.sol --sig "getDai()" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "depositToVault(uint256)" 1000000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "deployToStrategies(uint256)" 800000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "harvestYield()" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "viewStats()" --rpc-url $TENDERLY_RPC
```

### Path C: Quadratic Funding Focus (2 minutes)
```bash
# Assumes you have pgDAI (run getDai() + depositToVault() first if needed)
forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x1111111111111111111111111111111111111111 "Security Tools" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "registerProject(address,string)" 0x2222222222222222222222222222222222222222 "Education DAO" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "startRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "addToMatchingPool(uint256)" 50000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 0 30000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "vote(uint256,uint256)" 1 20000000000000000000 --rpc-url $TENDERLY_RPC --broadcast --legacy
forge script script/Interactive.s.sol --sig "viewRound(uint256)" 1 --rpc-url $TENDERLY_RPC
forge script script/Interactive.s.sol --sig "endRound()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```

---

## ⚡ Ultra-Quick Test

**Just want to see it work?**
```bash
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
export PRIVATE_KEY="your_private_key"
cd public-goods-liquidity-engine
forge script script/Interactive.s.sol --sig "runFullDemo()" --rpc-url $TENDERLY_RPC --broadcast --legacy
```
**Done! ✅** Complete demonstration in ~30 seconds.

---

**Built for Octant Hackathon 2024** 🏆
