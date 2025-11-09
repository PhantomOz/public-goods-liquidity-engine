# System Flow Diagram

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          USERS & CAPITAL                          │
│                                                                   │
│  Alice: 1000 USDC    Bob: 500 USDC    Charlie: 2000 USDC        │
└────────────────────┬─────────────────────────────────────────────┘
                     │ Deposits
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│                   PUBLIC GOODS VAULT (ERC-4626)                   │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │ Total Assets: 3500 USDC                                │      │
│  │ Total Shares: 3500                                     │      │
│  │                                                        │      │
│  │ Shareholders:                                          │      │
│  │   • Alice: 1000 shares                                 │      │
│  │   • Bob: 500 shares                                    │      │
│  │   • Charlie: 2000 shares                               │      │
│  │                                                        │      │
│  │ [Principal Protected - Withdrawable Anytime]          │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │ Yield Generation (Strategies)                          │      │
│  │   • Aave Lending: 4% APY                              │      │
│  │   • Spark Protocol: 5% APY                            │      │
│  │   • Result: 175 USDC/year (5%)                        │      │
│  └────────────────────────────────────────────────────────┘      │
└────────────────────┬─────────────────────────────────────────────┘
                     │ Harvest (Keeper calls)
                     │ 175 USDC → 175 vault shares
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│              QUADRATIC FUNDING SPLITTER                           │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │ Received: 175 vault shares (from yield)               │      │
│  │ Matching Pool: 100 shares (from ecosystem)            │      │
│  │ Total to Distribute: 275 shares                       │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │ Registered Projects:                                   │      │
│  │                                                        │      │
│  │ Project A: "Open Source Dev Tools"                    │      │
│  │   • Votes: 20 shares from 10 voters                   │      │
│  │   • QF Score: sqrt(20) × 10 = 44.7                   │      │
│  │                                                        │      │
│  │ Project B: "Education Initiative"                     │      │
│  │   • Votes: 20 shares from 2 voters                    │      │
│  │   • QF Score: sqrt(20) × 2 = 8.9                     │      │
│  │                                                        │      │
│  │ Project C: "Research Grant"                           │      │
│  │   • Votes: 10 shares from 5 voters                    │      │
│  │   • QF Score: sqrt(10) × 5 = 15.8                    │      │
│  │                                                        │      │
│  │ Total QF Score: 69.4                                  │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │ Distribution Calculation:                              │      │
│  │                                                        │      │
│  │ Project A:                                             │      │
│  │   Direct: 20 shares                                    │      │
│  │   Matching: (44.7/69.4) × 100 = 64.4 shares          │      │
│  │   Total: 84.4 shares ✅                               │      │
│  │                                                        │      │
│  │ Project B:                                             │      │
│  │   Direct: 20 shares                                    │      │
│  │   Matching: (8.9/69.4) × 100 = 12.8 shares           │      │
│  │   Total: 32.8 shares ✅                               │      │
│  │                                                        │      │
│  │ Project C:                                             │      │
│  │   Direct: 10 shares                                    │      │
│  │   Matching: (15.8/69.4) × 100 = 22.8 shares          │      │
│  │   Total: 32.8 shares ✅                               │      │
│  └────────────────────────────────────────────────────────┘      │
└────────────────────┬─────────────────────────────────────────────┘
                     │ Distribution
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│                      PUBLIC GOODS PROJECTS                        │
│                                                                   │
│  Project A: 84.4 shares → Redeem for 84.4 USDC                   │
│  Project B: 32.8 shares → Redeem for 32.8 USDC                   │
│  Project C: 32.8 shares → Redeem for 32.8 USDC                   │
│                                                                   │
│  🎉 Total Distributed: 150 USDC to public goods!                 │
│  💰 User Principal: Still 3500 USDC (100% preserved)             │
└──────────────────────────────────────────────────────────────────┘
```

## Key Insights from Example

### For Users (Alice, Bob, Charlie)
- **Deposited:** 3500 USDC combined
- **Current Holdings:** 3500 vault shares (worth 3500 USDC)
- **Can Withdraw:** 3500 USDC anytime
- **Public Goods Impact:** 150 USDC funded perpetually
- **Loss:** $0 (Zero! Principal intact)

### For Projects
- **Project A:** Most unique supporters (10 voters) → Highest matching multiplier
  - 20 direct votes → 84.4 total (4.2x multiplier!)
- **Project B:** Fewer supporters (2 voters) → Lower matching multiplier
  - 20 direct votes → 32.8 total (1.6x multiplier)
- **Project C:** Moderate support (5 voters) → Moderate multiplier
  - 10 direct votes → 32.8 total (3.3x multiplier)

### The Quadratic Effect
```
Traditional (1 person 1 vote):
  Project A: 10 votes → 33% of pool
  Project B: 2 votes → 7% of pool
  Project C: 5 votes → 17% of pool

Quadratic (broad support rewarded):
  Project A: 10 voters × sqrt(avg) → 64% of matching pool! 🚀
  Project B: 2 voters × sqrt(avg) → 13% of matching pool
  Project C: 5 voters × sqrt(avg) → 23% of matching pool
```

**Result:** Projects with broad community support get amplified!

## Time-Based Flow

```
Day 0: Deploy & Setup
├── Deploy PublicGoodsVault
├── Deploy QuadraticFundingSplitter
├── Configure allocation address
└── Initialize harvest tracking

Day 1-30: Deposit Phase
├── Users deposit capital
├── Vault issues shares
└── Principal protected

Day 5: Start Funding Round
├── Owner starts 30-day round
├── Projects register
└── Ecosystem adds matching pool

Day 7-30: Community Voting
├── Community reviews projects
├── Votes cast with vault shares
└── Quadratic scores calculated

Day 15, 22, 29: Yield Harvests
├── Keeper triggers harvest
├── Yield converted to shares
├── Shares sent to splitter
└── Available for distribution

Day 30: Round Ends
├── Voting closes
├── Final calculations run
├── Funds distributed to projects
└── Projects redeem shares for assets

Day 31+: Continuous Operation
├── Users can withdraw principal anytime
├── New round starts
├── Cycle repeats
└── Perpetual funding! ♾️
```

## Value Flow

```
$100M Deposited
     ↓
Generates 5% APY
     ↓
$5M Yield/Year
     ↓
Converted to Vault Shares
     ↓
Sent to Splitter
     ↓
Community Votes
     ↓
Quadratic Distribution
     ↓
Projects Receive Funds
     ↓
Build Public Goods
     ↓
Ecosystem Benefits
     ↓
More Users Join
     ↓
Cycle Continues Forever! 🔄
```

## Comparison to Traditional Models

### Traditional Grant Program
```
Treasury: $100M
Year 1: Grant $5M → Treasury: $95M
Year 2: Grant $5M → Treasury: $90M
Year 3: Grant $5M → Treasury: $85M
...
Year 20: Grant $5M → Treasury: $0M ⚠️
Total Funded: $100M (one-time)
```

### Public Goods Liquidity Engine
```
Treasury: $100M
Year 1: Deposit → Earn $5M yield → Fund public goods → Treasury: $100M ✅
Year 2: Earn $5M yield → Fund public goods → Treasury: $100M ✅
Year 3: Earn $5M yield → Fund public goods → Treasury: $100M ✅
...
Year 20: Earn $5M yield → Fund public goods → Treasury: $100M ✅
Total Funded: $100M (perpetual) 🚀
```

**Winner:** Public Goods Liquidity Engine!
- Preserves capital ✅
- Funds forever ✅
- Community-driven ✅
- Transparent ✅

## Security Model

```
┌─────────────────────────────────────────┐
│          Access Control Layer           │
├─────────────────────────────────────────┤
│                                         │
│  Owner (DAO/Multisig)                  │
│    ├── Set keeper                      │
│    ├── Set emergency admin             │
│    ├── Set allocation address          │
│    ├── Set performance fee             │
│    └── Start/end rounds                │
│                                         │
│  Keeper (Bot/Trusted Party)            │
│    ├── Harvest yield                   │
│    └── Initialize vault                │
│                                         │
│  Emergency Admin (Separate Multisig)   │
│    ├── Pause vault                     │
│    └── Emergency withdraw              │
│                                         │
│  Users (Anyone)                         │
│    ├── Deposit                         │
│    ├── Withdraw                        │
│    ├── Register projects               │
│    └── Vote                            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          Security Features              │
├─────────────────────────────────────────┤
│                                         │
│  • ReentrancyGuard on all functions    │
│  • SafeERC20 for token transfers       │
│  • Pause mechanism for emergencies     │
│  • Role separation (no single control) │
│  • OpenZeppelin base contracts         │
│  • Comprehensive test coverage         │
│  • Clear error messages                │
│  • Event logging for transparency      │
└─────────────────────────────────────────┘
```

## Integration Possibilities

```
┌──────────────────────────────────────────────────────┐
│              Yield Strategies (Input)                 │
├──────────────────────────────────────────────────────┤
│                                                       │
│  • Aave V3 Lending                                   │
│  • Spark Protocol                                    │
│  • Morpho Vaults                                     │
│  • Compound Finance                                  │
│  • Yearn V3 Vaults                                   │
│  • Uniswap V4 LP Fees (via hook)                    │
│  • Protocol Revenue Streams                          │
│  • Staking Rewards                                   │
└────────────────┬─────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────┐
│         PUBLIC GOODS VAULT (Core)                     │
└────────────────┬─────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────┐
│          Allocation Mechanisms (Output)               │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Current: Quadratic Funding Splitter                 │
│                                                       │
│  Future Options:                                     │
│  • Retroactive public goods funding                  │
│  • Conviction voting                                 │
│  • Rage-quit grants                                  │
│  • Time-weighted allocation                          │
│  • Impact certificates                               │
│  • Streaming payments                                │
└──────────────────────────────────────────────────────┘
```

---

**This flexible architecture allows:**
- ✅ Multiple yield sources
- ✅ Customizable allocation mechanisms
- ✅ Easy integration with existing protocols
- ✅ Future-proof extensibility
