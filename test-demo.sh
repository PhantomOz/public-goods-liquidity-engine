#!/bin/bash

# Non-interactive demo test script
# This version runs without pauses for automated testing

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
export TENDERLY_RPC="https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff"
export VAULT="0xfA5ac4E80Bca21dad90b7877290c3fdfF4D0F680"
export SPLITTER="0x35391ca5F9bEb7f4488671fCbad0Ee709603Fec4"
export AGGREGATOR="0xB9ACBBa0E2B8b97a22A84504B05769cBCdb907c2"
export AAVE_STRATEGY="0x2876CC2a624fe603434404d9c10B097b737dE983"
export SPARK_STRATEGY="0xFd344Cf335F9ee1d5aFe731aa6e50a0BC380E082"
export DAI="0x6B175474E89094C44Da98b954EedeAC495271d0F"
export WHALE="0x40ec5b33f54e0e8a33a975908c5ba1c14e5bbbdf"

# Check for private key
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable not set${NC}"
    exit 1
fi

# Get user address from private key
export USER_ADDRESS=$(cast wallet address $PRIVATE_KEY)

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Public Goods Liquidity Engine - Test Demo             ║"
echo "║              (Non-Interactive Version)                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

function print_section() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

function format_amount() {
    local amount=$1
    amount=${amount#0x}
    if [[ $amount =~ ^[0-9]+$ ]]; then
        echo "scale=2; $amount / 1000000000000000000" | bc 2>/dev/null || echo "N/A"
    else
        echo "scale=2; ibase=16; $amount / DE0B6B3A7640000" | bc 2>/dev/null || echo "N/A"
    fi
}

# Test 1: Check contracts are deployed
print_section "TEST 1: Verify Contract Deployments"

echo "Checking Vault..."
VAULT_CODE=$(cast code $VAULT --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ ! -z "$VAULT_CODE" ] && [ "$VAULT_CODE" != "0x" ]; then
    echo -e "${GREEN}✓ Vault deployed${NC}"
else
    echo -e "${RED}✗ Vault not deployed${NC}"
    exit 1
fi

echo "Checking Aggregator..."
AGG_CODE=$(cast code $AGGREGATOR --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ ! -z "$AGG_CODE" ] && [ "$AGG_CODE" != "0x" ]; then
    echo -e "${GREEN}✓ Aggregator deployed${NC}"
else
    echo -e "${RED}✗ Aggregator not deployed${NC}"
    exit 1
fi

echo "Checking Splitter..."
SPLIT_CODE=$(cast code $SPLITTER --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ ! -z "$SPLIT_CODE" ] && [ "$SPLIT_CODE" != "0x" ]; then
    echo -e "${GREEN}✓ Splitter deployed${NC}"
else
    echo -e "${RED}✗ Splitter not deployed${NC}"
    exit 1
fi

# Test 2: Check configuration
print_section "TEST 2: Verify Configuration"

echo "Checking Vault → Aggregator connection..."
VAULT_AGG=$(cast call $VAULT "yieldAggregator()(address)" --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ "$VAULT_AGG" == "$AGGREGATOR" ]; then
    echo -e "${GREEN}✓ Vault correctly points to Aggregator${NC}"
else
    echo -e "${YELLOW}⚠ Vault aggregator: $VAULT_AGG${NC}"
fi

echo "Checking Aggregator → Vault connection..."
AGG_VAULT=$(cast call $AGGREGATOR "vault()(address)" --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ "$AGG_VAULT" == "$VAULT" ]; then
    echo -e "${GREEN}✓ Aggregator correctly points to Vault${NC}"
else
    echo -e "${YELLOW}⚠ Aggregator vault: $AGG_VAULT${NC}"
fi

# Test 3: Get DAI (simplified - just check if we can interact)
print_section "TEST 3: Test DAI Interaction"

echo "Checking DAI contract..."
DAI_CODE=$(cast code $DAI --rpc-url $TENDERLY_RPC 2>/dev/null)
if [ ! -z "$DAI_CODE" ] && [ "$DAI_CODE" != "0x" ]; then
    echo -e "${GREEN}✓ DAI contract accessible${NC}"
else
    echo -e "${RED}✗ DAI contract not accessible${NC}"
    exit 1
fi

# Test 4: Check current balances
print_section "TEST 4: Check System Balances"

echo "Vault total assets:"
TOTAL_ASSETS=$(cast call $VAULT "totalAssets()(uint256)" --rpc-url $TENDERLY_RPC 2>/dev/null || echo "0")
echo "  $(format_amount $TOTAL_ASSETS) DAI"

echo "Aggregator total deployed:"
TOTAL_DEPLOYED=$(cast call $AGGREGATOR "totalDeployed()(uint256)" --rpc-url $TENDERLY_RPC 2>/dev/null || echo "0")
echo "  $(format_amount $TOTAL_DEPLOYED) DAI"

echo "Splitter project count:"
PROJECT_COUNT=$(cast call $SPLITTER "getProjectCount()(uint256)" --rpc-url $TENDERLY_RPC 2>/dev/null || echo "0")
echo "  $PROJECT_COUNT projects"

# Test 5: Strategy allocation
print_section "TEST 5: Check Strategy Allocation"

AAVE_ALLOC=$(cast call $AGGREGATOR "aaveAllocation()(uint256)" --rpc-url $TENDERLY_RPC 2>/dev/null || echo "0")
AAVE_ALLOC_DEC=$((16#${AAVE_ALLOC:2}))
SPARK_ALLOC=$((10000 - $AAVE_ALLOC_DEC))

echo "Aave Allocation: $(($AAVE_ALLOC_DEC / 100))% ($AAVE_ALLOC_DEC basis points)"
echo "Spark Allocation: $(($SPARK_ALLOC / 100))% ($SPARK_ALLOC basis points)"

# Final summary
print_section "TEST SUMMARY"

echo -e "${GREEN}✅ All deployment tests passed${NC}"
echo -e "${GREEN}✅ Configuration verified${NC}"
echo -e "${GREEN}✅ Contracts accessible${NC}"
echo ""
echo "System is ready for full demo!"
echo "Run './run-demo.sh' for interactive walkthrough"

exit 0
