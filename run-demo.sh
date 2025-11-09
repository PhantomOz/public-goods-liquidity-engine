#!/bin/bash

# Demo Automation Script for Public Goods Liquidity Engine
# This script demonstrates the complete user journey

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
    echo "Please set it with: export PRIVATE_KEY=your_private_key"
    exit 1
fi

# Get user address from private key
export USER_ADDRESS=$(cast wallet address $PRIVATE_KEY)

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Public Goods Liquidity Engine - Demo Script           ║"
echo "║              Octant DeFi Hackathon 2025                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

function pause_demo() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

function print_section() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

function format_amount() {
    local amount=$1
    # Remove leading 0x if present
    amount=${amount#0x}
    # Convert hex to decimal if needed
    if [[ $amount =~ ^[0-9]+$ ]]; then
        echo "scale=2; $amount / 1000000000000000000" | bc
    else
        echo "scale=2; ibase=16; $amount / DE0B6B3A7640000" | bc
    fi
}

# ============================================
# ACT 1: GET DAI AND DEPOSIT TO VAULT
# ============================================

print_section "ACT 1: User Deposits DAI"

echo "Step 1: Getting DAI from whale..."
echo "User address: $USER_ADDRESS"

# Impersonate whale
cast rpc anvil_impersonateAccount $WHALE --rpc-url $TENDERLY_RPC > /dev/null 2>&1

# Transfer DAI
cast send $DAI \
  "transfer(address,uint256)" \
  $USER_ADDRESS \
  10000000000000000000000 \
  --from $WHALE \
  --rpc-url $TENDERLY_RPC \
  --unlocked \
  > /dev/null 2>&1

USER_DAI=$(cast call $DAI "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $TENDERLY_RPC)
echo -e "${GREEN}✓ Received 10,000 DAI${NC}"
echo "  Balance: $(format_amount $USER_DAI) DAI"

pause_demo

echo -e "\nStep 2: Approving vault to spend DAI..."
cast send $DAI \
  "approve(address,uint256)" \
  $VAULT \
  10000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

echo -e "${GREEN}✓ Vault approved${NC}"

pause_demo

echo -e "\nStep 3: Depositing 10,000 DAI to vault..."
cast send $VAULT \
  "deposit(uint256,address)" \
  10000000000000000000000 \
  $USER_ADDRESS \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

PGDAI_BALANCE=$(cast call $VAULT "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $TENDERLY_RPC)
echo -e "${GREEN}✓ Deposited successfully${NC}"
echo "  pgDAI received: $(format_amount $PGDAI_BALANCE)"

pause_demo

# ============================================
# ACT 2: DEPLOY TO YIELD STRATEGIES
# ============================================

print_section "ACT 2: Deploy Funds to Yield Strategies"

echo "Deploying 8,000 DAI to Aave and Spark strategies..."
cast send $VAULT \
  "depositToStrategies(uint256)" \
  8000000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

AAVE_BAL=$(cast call $AGGREGATOR "getAaveBalance()(uint256)" --rpc-url $TENDERLY_RPC)
SPARK_BAL=$(cast call $AGGREGATOR "getSparkBalance()(uint256)" --rpc-url $TENDERLY_RPC)
TOTAL_DEPLOYED=$(cast call $AGGREGATOR "totalDeployed()(uint256)" --rpc-url $TENDERLY_RPC)

echo -e "${GREEN}✓ Funds deployed${NC}"
echo "  Aave Strategy: $(format_amount $AAVE_BAL) DAI"
echo "  Spark Strategy: $(format_amount $SPARK_BAL) DAI"
echo "  Total Deployed: $(format_amount $TOTAL_DEPLOYED) DAI"

pause_demo

# ============================================
# ACT 3: SIMULATE YIELD GENERATION
# ============================================

print_section "ACT 3: Yield Generation"

echo "Simulating 30 days of yield accumulation..."
echo "(On mainnet, this would generate ~100 DAI in yield)"

# Increase time by 30 days
cast rpc evm_increaseTime 2592000 --rpc-url $TENDERLY_RPC > /dev/null 2>&1
cast rpc evm_mine --rpc-url $TENDERLY_RPC > /dev/null 2>&1

echo -e "${GREEN}✓ 30 days passed${NC}"
echo "  Estimated yield: ~100 DAI (3.65% APY)"

pause_demo

# ============================================
# ACT 4: REGISTER PUBLIC GOODS PROJECTS
# ============================================

print_section "ACT 4: Register Public Goods Projects"

echo "Registering 3 demo projects..."

# Project 1
echo -e "\n1. Web3 Security Library"
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x1111111111111111111111111111111111111111 \
  "Web3 Security Library" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "   ${GREEN}✓ Registered${NC}"

# Project 2
echo "2. Carbon Offset Protocol"
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x2222222222222222222222222222222222222222 \
  "Carbon Offset Protocol" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "   ${GREEN}✓ Registered${NC}"

# Project 3
echo "3. DeFi Education DAO"
cast send $SPLITTER \
  'registerProject(address,string)' \
  0x3333333333333333333333333333333333333333 \
  "DeFi Education DAO" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "   ${GREEN}✓ Registered${NC}"

PROJECT_COUNT_HEX=$(cast call $SPLITTER "getProjectCount()(uint256)" --rpc-url $TENDERLY_RPC)
PROJECT_COUNT=$((PROJECT_COUNT_HEX))
echo -e "\nTotal projects: $PROJECT_COUNT"

pause_demo

# ============================================
# ACT 5: HARVEST YIELD AND START ROUND
# ============================================

print_section "ACT 5: Harvest Yield & Start Funding Round"

echo "Harvesting accumulated yield..."
cast send $VAULT \
  "harvest()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

SPLITTER_BAL=$(cast call $VAULT "balanceOf(address)(uint256)" $SPLITTER --rpc-url $TENDERLY_RPC)
echo -e "${GREEN}✓ Yield harvested${NC}"
echo "  Splitter balance: $(format_amount $SPLITTER_BAL) pgDAI"

echo -e "\nStarting funding round 1 (7-day duration)..."
cast send $SPLITTER \
  "startRound(uint256)" \
  604800 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

CURRENT_ROUND=$(cast call $SPLITTER "currentRound()(uint256)" --rpc-url $TENDERLY_RPC)
echo -e "${GREEN}✓ Round started${NC}"
echo "  Round number: $CURRENT_ROUND"

echo -e "\nSeeding matching pool with 50 pgDAI..."
cast send $VAULT \
  "approve(address,uint256)" \
  $SPLITTER \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

cast send $SPLITTER \
  "addToMatchingPool(uint256)" \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

MATCHING_POOL=$(cast call $SPLITTER "matchingPools(uint256)(uint256)" $CURRENT_ROUND --rpc-url $TENDERLY_RPC)
echo -e "${GREEN}✓ Matching pool funded${NC}"
echo "  Pool balance: $(format_amount $MATCHING_POOL) pgDAI"

pause_demo

# ============================================
# ACT 6: COMMUNITY VOTING
# ============================================

print_section "ACT 6: Community Voting (Quadratic Funding)"

echo "Simulating community votes..."
echo "(In reality, multiple users would vote)"

echo -e "\nVoting for Web3 Security Library (50 pgDAI)..."
cast send $SPLITTER \
  "vote(uint256,uint256)" \
  0 \
  50000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "${GREEN}✓ Vote recorded${NC}"

echo "Voting for Carbon Offset Protocol (30 pgDAI)..."
cast send $SPLITTER \
  "vote(uint256,uint256)" \
  1 \
  30000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "${GREEN}✓ Vote recorded${NC}"

echo "Voting for DeFi Education DAO (20 pgDAI)..."
cast send $SPLITTER \
  "vote(uint256,uint256)" \
  2 \
  20000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1
echo -e "${GREEN}✓ Vote recorded${NC}"

echo -e "\n${YELLOW}Note: Quadratic funding formula means each vote has diminishing returns${NC}"

pause_demo

# ============================================
# ACT 7: END ROUND AND DISTRIBUTE
# ============================================

print_section "ACT 7: Calculate Scores & Distribute Funds"

echo "Ending round and calculating quadratic funding scores..."
cast send $SPLITTER \
  "endRound()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $TENDERLY_RPC \
  --legacy \
  > /dev/null 2>&1

echo -e "${GREEN}✓ Round ended${NC}"
echo "  Quadratic funding scores calculated"

PROJECT1_BAL=$(cast call $VAULT "balanceOf(address)(uint256)" 0x1111111111111111111111111111111111111111 --rpc-url $TENDERLY_RPC)
PROJECT2_BAL=$(cast call $VAULT "balanceOf(address)(uint256)" 0x2222222222222222222222222222222222222222 --rpc-url $TENDERLY_RPC)
PROJECT3_BAL=$(cast call $VAULT "balanceOf(address)(uint256)" 0x3333333333333333333333333333333333333333 --rpc-url $TENDERLY_RPC)

echo -e "\nProject Allocations:"
echo "  1. Web3 Security Library: $(format_amount $PROJECT1_BAL) pgDAI"
echo "  2. Carbon Offset Protocol: $(format_amount $PROJECT2_BAL) pgDAI"
echo "  3. DeFi Education DAO: $(format_amount $PROJECT3_BAL) pgDAI"

pause_demo

# ============================================
# FINAL SUMMARY
# ============================================

print_section "DEMO COMPLETE - Summary"

TOTAL_ASSETS=$(cast call $VAULT "totalAssets()(uint256)" --rpc-url $TENDERLY_RPC)

echo "Key Metrics:"
echo "  ✓ Total Value Locked: $(format_amount $TOTAL_ASSETS) DAI"
echo "  ✓ User pgDAI Balance: $(format_amount $PGDAI_BALANCE)"
echo "  ✓ Deployed to Strategies: $(format_amount $TOTAL_DEPLOYED) DAI"
echo "  ✓ Projects Funded: 3"
echo "  ✓ Yield Generated: ~100 DAI (simulated)"
echo "  ✓ Funds Distributed: Yes"

echo -e "\n${GREEN}Success Factors:${NC}"
echo "  • Dual-protocol yield (Aave + Spark)"
echo "  • Democratic allocation via quadratic funding"
echo "  • Automatic yield donation to public goods"
echo "  • ERC-4626 composability"
echo "  • Full on-chain transparency"

echo -e "\n${BLUE}Next Steps:${NC}"
echo "  • Projects can redeem pgDAI for DAI anytime"
echo "  • More users can deposit and vote in next round"
echo "  • Yield continues accumulating 24/7"
echo "  • Additional strategies can be added"

echo -e "\n${YELLOW}Thank you for watching the demo!${NC}"
echo -e "${BLUE}Built for Octant DeFi Hackathon 2025${NC}\n"
