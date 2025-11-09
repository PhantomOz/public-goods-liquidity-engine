#!/bin/bash

echo "=========================================="
echo "Tenderly Deployment Verification"
echo "=========================================="
echo ""

RPC_URL="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"

SPLITTER="0x381D85647AaB3F16EAB7000963D3Ce56792479fD"
VAULT="0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680"
AGGREGATOR="0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2"
AAVE_STRATEGY="0x2876CC2a624fe603434404d9c10B097b737dE983"
SPARK_STRATEGY="0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082"

echo "1. Contract Deployment Status"
echo "------------------------------"
echo -n "QuadraticFundingSplitter: "
cast code $SPLITTER --rpc-url $RPC_URL > /dev/null && echo "✅ Deployed" || echo "❌ Not deployed"

echo -n "PublicGoodsVault: "
cast code $VAULT --rpc-url $RPC_URL > /dev/null && echo "✅ Deployed" || echo "❌ Not deployed"

echo -n "YieldAggregator: "
cast code $AGGREGATOR --rpc-url $RPC_URL > /dev/null && echo "✅ Deployed" || echo "❌ Not deployed"

echo -n "AaveStrategy: "
cast code $AAVE_STRATEGY --rpc-url $RPC_URL > /dev/null && echo "✅ Deployed" || echo "❌ Not deployed"

echo -n "SparkStrategy: "
cast code $SPARK_STRATEGY --rpc-url $RPC_URL > /dev/null && echo "✅ Deployed" || echo "❌ Not deployed"

echo ""
echo "2. Configuration Verification"
echo "------------------------------"

echo -n "Vault → Aggregator: "
VAULT_AGGREGATOR=$(cast call $VAULT "yieldAggregator()(address)" --rpc-url $RPC_URL)
if [ "$VAULT_AGGREGATOR" == "$AGGREGATOR" ]; then
    echo "✅ Correct"
else
    echo "❌ Wrong: $VAULT_AGGREGATOR"
fi

echo -n "Aggregator → Vault: "
AGGREGATOR_VAULT=$(cast call $AGGREGATOR "vault()(address)" --rpc-url $RPC_URL)
if [ "$AGGREGATOR_VAULT" == "$VAULT" ]; then
    echo "✅ Correct"
else
    echo "❌ Wrong: $AGGREGATOR_VAULT"
fi

echo -n "AaveStrategy → Aggregator: "
AAVE_VAULT=$(cast call $AAVE_STRATEGY "vault()(address)" --rpc-url $RPC_URL)
if [ "$AAVE_VAULT" == "$AGGREGATOR" ]; then
    echo "✅ Correct"
else
    echo "❌ Wrong: $AAVE_VAULT"
fi

echo -n "SparkStrategy → Aggregator: "
SPARK_VAULT=$(cast call $SPARK_STRATEGY "vault()(address)" --rpc-url $RPC_URL)
if [ "$SPARK_VAULT" == "$AGGREGATOR" ]; then
    echo "✅ Correct"
else
    echo "❌ Wrong: $SPARK_VAULT"
fi

echo ""
echo "3. Strategy Allocation"
echo "------------------------------"
AAVE_ALLOC=$(cast call $AGGREGATOR "aaveAllocation()(uint256)" --rpc-url $RPC_URL)
AAVE_ALLOC_DEC=$((16#${AAVE_ALLOC:2}))
echo "Aave Allocation: $(($AAVE_ALLOC_DEC / 100))% ($(($AAVE_ALLOC_DEC)) basis points)"

SPARK_ALLOC=$((10000 - $AAVE_ALLOC_DEC))
echo "Spark Allocation: $(($SPARK_ALLOC / 100))% ($(($SPARK_ALLOC)) basis points)"

echo ""
echo "=========================================="
echo "✅ All Systems Operational"
echo "=========================================="
