# Quick Start Guide - Demo Interaction

## 5-Minute Demo Setup

### Prerequisites

```bash
# Install foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
git clone <your-repo>
cd public-goods-liquidity-engine
```

### Set Environment Variables

```bash
export PRIVATE_KEY="your_private_key_here"
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
```

### Option 1: Automated Demo (Recommended)

```bash
# Run the complete demo script
./run-demo.sh
```

This will walk you through:
1. Getting DAI from a whale
2. Depositing to vault
3. Deploying to strategies
4. Registering projects
5. Voting with quadratic funding
6. Distributing yield

### Option 2: Manual Step-by-Step

#### 1. Get DAI (30 seconds)

```bash
# Set addresses
VAULT="0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680"
DAI="0x6B175474E89094C44Da98b954EedeAC495271d0F"
WHALE="0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf"
USER=$(cast wallet address $PRIVATE_KEY)

# Get DAI from whale
cast rpc anvil_impersonateAccount $WHALE --rpc-url $TENDERLY_RPC
cast send $DAI "transfer(address,uint256)" $USER 10000000000000000000000 \
  --from $WHALE --rpc-url $TENDERLY_RPC --unlocked
```

#### 2. Deposit to Vault (30 seconds)

```bash
# Approve and deposit
cast send $DAI "approve(address,uint256)" $VAULT 10000000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $VAULT "deposit(uint256,address)" 10000000000000000000000 $USER \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

# Check balance
cast call $VAULT "balanceOf(address)(uint256)" $USER --rpc-url $TENDERLY_RPC
```

#### 3. Deploy to Strategies (30 seconds)

```bash
# Deploy 8,000 DAI to yield strategies
cast send $VAULT "depositToStrategies(uint256)" 8000000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

# Check deployment
AGGREGATOR="0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2"
cast call $AGGREGATOR "totalDeployed()(uint256)" --rpc-url $TENDERLY_RPC
```

#### 4. Register Projects (1 minute)

```bash
SPLITTER="0x381D85647AaB3F16EAB7000963D3Ce56792479fD"

# Register 3 projects
cast send $SPLITTER 'registerProject(address,string)' \
  0x1111111111111111111111111111111111111111 "Project 1" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $SPLITTER 'registerProject(address,string)' \
  0x2222222222222222222222222222222222222222 "Project 2" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $SPLITTER 'registerProject(address,string)' \
  0x3333333333333333333333333333333333333333 "Project 3" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy
```

#### 5. Harvest and Start Round (30 seconds)

```bash
# Harvest yield
cast send $VAULT "harvest()" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

# Start funding round
cast send $SPLITTER "startRound()" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy
```

#### 6. Vote (1 minute)

```bash
# Vote for projects with pgDAI
cast send $SPLITTER "vote(uint256,uint256)" 0 50000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $SPLITTER "vote(uint256,uint256)" 1 30000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $SPLITTER "vote(uint256,uint256)" 2 20000000000000000000 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy
```

#### 7. End Round and Distribute (30 seconds)

```bash
# Calculate QF scores and distribute
cast send $SPLITTER "endRound()" \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy

cast send $SPLITTER "distribute(uint256)" 1 \
  --private-key $PRIVATE_KEY --rpc-url $TENDERLY_RPC --legacy
```

#### 8. Check Results (30 seconds)

```bash
# Check project balances
cast call $VAULT "balanceOf(address)(uint256)" \
  0x1111111111111111111111111111111111111111 --rpc-url $TENDERLY_RPC

cast call $VAULT "balanceOf(address)(uint256)" \
  0x2222222222222222222222222222222222222222 --rpc-url $TENDERLY_RPC

cast call $VAULT "balanceOf(address)(uint256)" \
  0x3333333333333333333333333333333333333333 --rpc-url $TENDERLY_RPC
```

---

## Key Concepts to Explain During Demo

### 1. **Dual-Strategy Yield**
"Funds are automatically split between Aave v3 and Spark Protocol, diversifying risk while maximizing yield."

### 2. **Quadratic Funding**
"Smaller contributors have more impact. If you donate $1 and 99 others do too, the project gets more than if one person donates $100."

### 3. **ERC-4626 Standard**
"Vault shares (pgDAI) are composable - they work with any DeFi protocol that supports the standard."

### 4. **Automatic Yield Donation**
"Users don't have to do anything. Yield automatically goes to public goods. They keep their principal."

### 5. **On-Chain Transparency**
"Every vote, every allocation, every distribution is recorded on-chain. Fully auditable."

---

## Common Demo Questions & Answers

**Q: "What if a strategy fails?"**
A: Emergency withdrawal function pulls all funds back to vault. Plus, diversification across two protocols reduces risk.

**Q: "How much yield can we expect?"**
A: Currently ~3-4% APY from Aave and Spark combined. Adjusts based on market conditions.

**Q: "Can projects withdraw immediately?"**
A: Yes! They receive pgDAI shares that can be redeemed for DAI anytime. No lock-ups.

**Q: "How is this different from Gitcoin?"**
A: We generate the funding pool from DeFi yield, not donations. Sustainable, recurring revenue for public goods.

**Q: "What prevents voting manipulation?"**
A: Quadratic funding formula. Also, minimum vote amount and on-chain identity verification can be added.

**Q: "Can we add more yield strategies?"**
A: Absolutely! The architecture is modular. Can add Compound, Morpho, Yearn, etc.

---

## Demo Tips

1. **Start with the Why**: Explain the problem of sustainable public goods funding
2. **Show, Don't Tell**: Run actual transactions on Tenderly fork
3. **Highlight Innovation**: Dual-strategy + quadratic funding + auto-donation
4. **Address Risks**: Explain smart contract audits, strategy diversification
5. **End with Vision**: Integration with Octant v2, scaling to more protocols

---

## Verification Commands

```bash
# Check all deployments
./verify-deployment.sh

# Check specific balances
cast call $VAULT "totalAssets()(uint256)" --rpc-url $TENDERLY_RPC
cast call $AGGREGATOR "totalDeployed()(uint256)" --rpc-url $TENDERLY_RPC
cast call $SPLITTER "getProjectCount()(uint256)" --rpc-url $TENDERLY_RPC

# Check strategy performance
cast call $AGGREGATOR "getAaveBalance()(uint256)" --rpc-url $TENDERLY_RPC
cast call $AGGREGATOR "getSparkBalance()(uint256)" --rpc-url $TENDERLY_RPC
```

---

## Troubleshooting

**Issue**: "Transaction reverted"
- Solution: Make sure you have enough test ETH on Tenderly fork
- Solution: Check that contracts are deployed with `./verify-deployment.sh`

**Issue**: "Insufficient balance"
- Solution: Run step 1 again to get more DAI from whale

**Issue**: "Round not active"
- Solution: Start a new round with `cast send $SPLITTER "startRound()"`

---

## Next Steps After Demo

1. Share Tenderly fork link for others to try
2. Deploy to testnet (Sepolia/Goerli)
3. Get audit for mainnet deployment
4. Build web interface
5. Integrate with Octant's project registry
6. Add more yield strategies
7. Implement governance for strategy selection

---

## Resources

- **Full Demo Script**: `DEMO_SCRIPT.md`
- **Automated Demo**: `./run-demo.sh`
- **Deployment Info**: `TENDERLY_DEPLOYMENT.md`
- **Verification**: `./verify-deployment.sh`
- **Tests**: `forge test`
- **Codebase**: `src/` directory

---

## Contact & Support

- GitHub Issues: For bugs and feature requests
- Documentation: See README.md
- Octant Discord: For hackathon-specific questions

**Built with ❤️ for Octant DeFi Hackathon 2025**
