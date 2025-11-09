# Tenderly Mainnet Fork Deployment

This guide covers deploying the Public Goods Liquidity Engine to the **Octant Hackathon Tenderly Mainnet Fork** with real Aave v3 and Spark protocol integrations.

## Network Information

- **Network**: Tenderly Mainnet Fork (octant-hackathon-mainnet-fork)
- **RPC URL**: `https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff`
- **Chain ID**: 1 (Ethereum Mainnet fork)

## Mainnet Protocol Addresses

### Aave v3
- **Aave Pool**: `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2`
- **aDAI Token**: `0x018008bfb33d285247A21d44E50697654f754e63`

### Spark Protocol  
- **Spark sDAI Vault**: `0x83F20F44975D03b1b09e64809B757c47f942BEeA`

### ERC-20 Tokens
- **DAI**: `0x6B175474E89094C44Da98b954EeEdeAC495271d0F`
- **USDC**: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- **USDS**: `0xdC035D45d973E3EC169d2276DDab16f1e407384F`

## Prerequisites

1. **Funded wallet** on Tenderly fork (you'll need ETH for gas)
2. **DAI balance** for testing deposits
3. **Environment configured** (see below)

## Setup

### 1. Configure Environment

Update your `.env` file:

```bash
# Your deployment private key
PRIVATE_KEY=your_private_key_here

# Tenderly Fork RPC
TENDERLY_FORK_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff

# Keeper and admin addresses (can be same as deployer for testing)
KEEPER_ADDRESS=0x1192ebae3138f066c3914e428c0a29a8e39668e7
EMERGENCY_ADMIN=0x1192ebae3138f066c3914e428c0a29a8e39668e7

# Asset configuration
ASSET_TOKEN=0x6B175474E89094C44Da98b954EeEdeAC495271d0F  # DAI
MIN_VOTE_AMOUNT=1000000000000000000  # 1 DAI minimum

# Strategy allocation (50/50 Aave/Spark)
AAVE_ALLOCATION=5000
```

### 2. Verify Foundry Configuration

Ensure `foundry.toml` includes the Tenderly endpoint:

```toml
[rpc_endpoints]
tenderly = "${TENDERLY_FORK_RPC}"
```

## Deployment

### Deploy All Contracts

Run the deployment script:

```bash
forge script script/DeployTenderly.s.sol \
  --rpc-url tenderly \
  --broadcast \
  --legacy
```

**Note**: Use `--legacy` flag for Tenderly compatibility.

### Deployment Order

The script deploys in this sequence:

1. **QuadraticFundingSplitter** - Receives yield shares for QF distribution
2. **PublicGoodsVault** - Main ERC-4626 vault for user deposits
3. **AaveStrategy** - Integrates with Aave v3 Pool
4. **SparkStrategy** - Integrates with Spark sDAI vault
5. **YieldAggregator** - Coordinates both strategies (50/50 allocation)
6. **Configuration** - Links all components together

### Expected Output

```
==========================================
DEPLOYMENT SUMMARY
==========================================
Network: Tenderly Mainnet Fork
Asset: DAI 0x6B175474E89094C44Da98b954EeEdeAC495271d0F

Core Contracts:
  PublicGoodsVault: 0x...
  QuadraticFundingSplitter: 0x...
  YieldAggregator: 0x...

Strategies:
  AaveStrategy: 0x...
  SparkStrategy: 0x...

Protocol Integrations:
  Aave v3 Pool: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
  Spark sDAI: 0x83F20F44975D03b1b09e64809B757c47f942BEeA

Configuration:
  Aave Allocation: 50%
  Spark Allocation: 50%
==========================================
```

This guide explains how to deploy the Public Goods Liquidity Engine to the Tenderly mainnet fork for the Octant DeFi Hackathon 2025.

## Prerequisites

1. **Tenderly Fork RPC**: `https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff`
2. **Private Key**: You'll need a wallet with funds on the Tenderly fork
3. **Foundry**: Ensure you have `forge` installed

## Setup Environment

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Edit `.env` and set your private key:
```bash
PRIVATE_KEY=your_private_key_here
TENDERLY_FORK_RPC=https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff
```

3. Load environment variables:
```bash
source .env
```

## Deploy Contracts

Deploy the full system to the Tenderly fork:

```bash
forge script script/DeployMainnetFork.s.sol \
  --rpc-url $TENDERLY_FORK_RPC \
  --broadcast \
  --legacy
```

This will deploy:
- ✅ QuadraticFundingSplitter
- ✅ PublicGoodsVault (ERC-4626)
- ✅ AaveStrategy (integrates with real Aave v3)
- ✅ SparkStrategy (integrates with real Spark sDAI)
- ✅ YieldAggregator (coordinates both strategies)

## Mainnet Addresses Used

The deployment uses **real mainnet protocol addresses**:

| Protocol | Address |
|----------|---------|
| Aave v3 Pool | `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2` |
| Spark sDAI | `0x83F20F44975D03b1b09e64809B757c47f942BEeA` |
| DAI Token | `0x6B175474E89094C44Da98b954EeEd5ed7B6f45B8` |
| aDAI Token | `0x018008bfb33d285247A21d44E50697654f754e63` |

## Post-Deployment Setup

After deployment, follow these steps to test the system:

### 1. Get DAI (on Tenderly fork)

Use Tenderly's fork features to mint DAI or transfer from a whale address:

```bash
# Example: Transfer DAI from a whale
cast send $DAI_TOKEN \
  "transfer(address,uint256)" \
  $YOUR_ADDRESS \
  1000000000000000000000 \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY \
  --from 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 # Compound DAI whale
```

### 2. Deposit to Vault

```bash
# Approve vault to spend DAI
cast send $DAI_TOKEN \
  "approve(address,uint256)" \
  $VAULT_ADDRESS \
  1000000000000000000000 \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY

# Deposit DAI to vault
cast send $VAULT_ADDRESS \
  "deposit(uint256,address)" \
  100000000000000000000 \
  $YOUR_ADDRESS \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

### 3. Initialize Harvest

```bash
cast send $VAULT_ADDRESS \
  "initializeHarvest()" \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

### 4. Deploy to Strategies

Send funds to Aave and Spark (50/50 split by default):

```bash
cast send $VAULT_ADDRESS \
  "depositToStrategies(uint256)" \
  50000000000000000000 \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

### 5. Simulate Time & Accrue Yield

Use Tenderly's time manipulation to fast-forward and accrue yield:

```bash
# Fast forward 30 days
cast rpc evm_increaseTime 2592000 --rpc-url $TENDERLY_FORK_RPC
cast rpc evm_mine --rpc-url $TENDERLY_FORK_RPC
```

### 6. Harvest Yield

Collect yield from both Aave and Spark:

```bash
cast send $VAULT_ADDRESS \
  "harvest()" \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

### 7. Register Projects & Vote

```bash
# Register a project in the splitter
cast send $SPLITTER_ADDRESS \
  "registerProject(string,string,address)" \
  "Cool Project" \
  "ipfs://QmXxx..." \
  $PROJECT_RECIPIENT \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY

# Vote for projects (requires vault shares)
cast send $SPLITTER_ADDRESS \
  "vote(uint256,uint256)" \
  0 \
  1000000000000000000 \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

### 8. End Funding Round

```bash
cast send $SPLITTER_ADDRESS \
  "endRound()" \
  --rpc-url $TENDERLY_FORK_RPC \
  --private-key $PRIVATE_KEY
```

## Verification

Check deployment addresses in `deployments/tenderly-fork.json`:

```bash
cat deployments/tenderly-fork.json
```

## Testing Integration

Run fork tests against the deployment:

```bash
forge test --fork-url $TENDERLY_FORK_RPC -vv
```

## Key Benefits of Tenderly Fork

✅ **Real protocols**: Test with actual Aave and Spark contracts  
✅ **Time travel**: Fast-forward to simulate yield accrual  
✅ **State inspection**: Debug transactions and view state changes  
✅ **Whale impersonation**: Access liquidity from mainnet whales  
✅ **No gas costs**: Test without spending real ETH  

## Troubleshooting

### "Insufficient allowance" error
Make sure to approve the vault before depositing:
```bash
cast send $DAI_TOKEN "approve(address,uint256)" $VAULT_ADDRESS $(cast max-uint256) --rpc-url $TENDERLY_FORK_RPC --private-key $PRIVATE_KEY
```

### "Unauthorized" error
Ensure you're calling keeper-only functions from the deployer address.

### "No yield generated" error
Wait some time or use `evm_increaseTime` to accrue yield in Aave/Spark.

## Next Steps

1. Deploy to Tenderly fork
2. Create a demo video showing the full flow
3. Document integration points for Aave and Spark
4. Prepare hackathon submission with deployment addresses

## Support

For issues or questions:
- GitHub: [Your repo]
- Discord: [Your handle]
- Email: [Your email]
