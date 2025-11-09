# Tenderly Mainnet Fork Deployment

## Deployment Summary

Successfully deployed complete Public Goods Liquidity Engine system to Tenderly mainnet fork.

**Deployment Date:** January 2025  
**Network:** Tenderly Mainnet Fork (Chain ID: 8)  
**RPC:** https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff

## Deployed Contracts

| Contract | Address | Size (bytes) | Status |
|----------|---------|--------------|--------|
| **QuadraticFundingSplitter** | `0x35391ca5F9bEb7f4488671fCbad0Ee709603Fec4` | 10,397 | ✅ Deployed |
| **PublicGoodsVault** | `0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680` | 14,659 | ✅ Configured |
| **YieldAggregator** | `0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2` | 10,499 | ✅ Configured |
| **AaveStrategy** | `0x2876CC2a624fe603434404d9c10B097b737dE983` | 6,953 | ✅ Configured |
| **SparkStrategy** | `0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082` | 5,915 | ✅ Configured |

## System Architecture

```
PublicGoodsVault (0xfA5a...)
    ↓ (yieldAggregator)
YieldAggregator (0xB9AC...)
    ├─→ (aaveStrategy) AaveStrategy (0x2876...)
    │       ↓ (deposits to)
    │   Aave v3 Pool (0x8787...)
    │
    └─→ (sparkStrategy) SparkStrategy (0xFd34...)
            ↓ (deposits to)
        Spark sDAI (0x83F2...)

QuadraticFundingSplitter (0x3539...)
    ↑ (receives yield shares)
PublicGoodsVault (0xfA5a...)
```

## Configuration Verification

### Vault → Aggregator
```bash
cast call 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680 "yieldAggregator()(address)"
# Returns: 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 ✅
```

### Aggregator → Vault
```bash
cast call 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 "vault()(address)"
# Returns: 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680 ✅
```

### AaveStrategy → Aggregator
```bash
cast call 0x2876CC2a624fe603434404d9c10B097b737dE983 "vault()(address)"
# Returns: 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 ✅
```

### SparkStrategy → Aggregator
```bash
cast call 0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082 "vault()(address)"
# Returns: 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 ✅
```

## Mainnet Protocol Addresses Used

- **DAI:** `0x6B175474E89094C44Da98b954EedeAC495271d0F`
- **Aave v3 Pool:** `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2`
- **Aave aDAI:** `0x018008bfb33d285247A21d44E50697654f754e63`
- **Spark sDAI:** `0x83F20F44975D03b1b09e64809B757c47f942BEeA`

## Deployment Scripts

1. **CompleteSystemDeployment.s.sol** - Initial deployment of all contracts
2. **FixVaultConfig.s.sol** - Configuration fix to wire contracts correctly

## Key Features Deployed

### 1. ERC-4626 Vault
- Asset: DAI
- Name: Public Goods Vault
- Symbol: pgDAI
- Yield auto-donated to public goods projects

### 2. Dual-Strategy Yield
- **Aave v3**: 50% allocation - Deposits DAI to Aave lending pool
- **Spark Protocol**: 50% allocation - Deposits DAI to Spark's sDAI vault

### 3. Quadratic Funding
- Democratic allocation of yield to registered projects
- On-chain square root calculation (Babylonian method)
- Minimum vote: 1 token

## Transaction Hashes

### Initial Deployment
- Splitter: `0x905ad9370d527d951450e28cc83bd4af3c1dd1f232bfd4a35316840f10fa4d1c`
- Vault: `0xc3a50e0db616e834f90f6670facd3f9fe6679ff36234a5612dc2ffba93f196ae`
- AaveStrategy: (deployed to 0x2876CC2a...)
- SparkStrategy: `0x9dcd52b6b3de2702d2b0fc241d7989ee91eb9e683d8f9221b43bd87b8f5c7c24`
- YieldAggregator: (deployed to 0xB9ACBBa0...)

### Configuration Fix
- Set Vault Aggregator: `0x630837809461288cd78972a6d1f3566172ce68d4a77a092239895be1270f139f`
- Set AaveStrategy Vault: `0x80f1283bd19dd0abb6cb09eb941b501e9c6168a5ddde390c483c953ee0534cf3`
- Set SparkStrategy Vault: `0x1a8d77ad2106ddb6fd98a035b4668fb745729076056fcb80c29d9e1ddc9246d8`

## Testing on Fork

### 1. Get DAI from whale
```bash
# Impersonate DAI whale
cast rpc anvil_impersonateAccount 0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf --rpc-url tenderly

# Transfer DAI to your address
cast send 0x6B175474E89094C44Da98b954EedeAC495271d0F "transfer(address,uint256)" YOUR_ADDRESS 1000000000000000000000 --from 0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf --rpc-url tenderly --unlocked
```

### 2. Deposit to Vault
```bash
# Approve vault
cast send 0x6B175474E89094C44Da98b954EedeAC495271d0F "approve(address,uint256)" 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680 1000000000000000000000 --private-key YOUR_KEY --rpc-url tenderly

# Deposit
cast send 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680 "deposit(uint256,address)" 1000000000000000000000 YOUR_ADDRESS --private-key YOUR_KEY --rpc-url tenderly
```

### 3. Deploy to Strategies
```bash
cast send 0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680 "depositToStrategies(uint256)" 1000000000000000000000 --private-key YOUR_KEY --rpc-url tenderly
```

### 4. Check Balances
```bash
# Total deployed
cast call 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 "totalDeployed()(uint256)" --rpc-url tenderly

# Aave balance
cast call 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 "getAaveBalance()(uint256)" --rpc-url tenderly

# Spark balance
cast call 0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2 "getSparkBalance()(uint256)" --rpc-url tenderly
```

## Deployment Status

✅ **All contracts successfully deployed**  
✅ **All contracts properly configured**  
✅ **System architecture fully wired**  
✅ **Ready for testing and demonstration**

## Next Steps

1. Test deposit flow with DAI whale
2. Verify yield generation from both protocols
3. Test harvest and allocation to public goods projects
4. Register test projects for quadratic funding
5. Conduct voting and distribution rounds

## Notes

- All contracts use Solidity 0.8.26 with via_ir optimization
- EVM version: Cancun
- Gas optimization: Legacy transactions used for compatibility
- Owner address: `0x1192ebAE3138F066c3914E428c0a29A8e39668E7`
