#!/bin/bash

# Set default values
PRIVATE_KEY=${PRIVATE_KEY:-"0x65"}
CUSTOM_RPC=${CUSTOM_RPC:-"https://1rpc.io/sepolia"}
NETWORK=${NETWORK:-"sepolia"}
NUM_EPOCHS=${NUM_EPOCHS:-1}

# Allow command line arguments to override defaults
while [[ $# -gt 0 ]]; do
  case $1 in
    --private-key)
      PRIVATE_KEY="$2"
      shift 2
      ;;
    --custom-rpc)
      CUSTOM_RPC="$2"
      shift 2
      ;;
    --network)
      NETWORK="$2"
      shift 2
      ;;
    --num-epochs)
      NUM_EPOCHS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--private-key KEY] [--custom-rpc URL] [--network NETWORK] [--num-epochs NUM]"
      exit 1
      ;;
  esac
done

echo "=== Auto Claim Script Started ==="
echo "Using private key: $PRIVATE_KEY"
echo "Using RPC URL: $CUSTOM_RPC"
echo "Using network: $NETWORK"
echo "Number of epochs: $NUM_EPOCHS"
echo "================================="

# Function to get miner info and check claimable rewards
get_miner_info() {
    echo "Getting miner info..."

    # Get the info output
    INFO_OUTPUT=$(worm-miner info --network "$NETWORK" --private-key "$PRIVATE_KEY" --custom-rpc "$CUSTOM_RPC" 2>/dev/null)

    if [ -z "$INFO_OUTPUT" ]; then
        echo "Error: Could not get miner info"
        return 1
    fi

    echo "Miner info retrieved:"
    echo "$INFO_OUTPUT"
    echo "----------------------------------------"

    # Extract current epoch
    CURRENT_EPOCH=$(echo "$INFO_OUTPUT" | grep "Current epoch:" | awk '{print $3}')

    # Extract claimable WORM amount - handle the format "Claimable WORM (10 last epochs): 0.000000000000000000"
    CLAIMABLE_WORM=$(echo "$INFO_OUTPUT" | grep "Claimable WORM" | sed 's/.*: //' | awk '{print $1}')

    echo "Current epoch: $CURRENT_EPOCH"
    echo "Claimable WORM: $CLAIMABLE_WORM"

    # Validate extracted values
    if [ -z "$CURRENT_EPOCH" ] || ! [[ "$CURRENT_EPOCH" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: Could not extract valid current epoch"
        return 1
    fi

    if [ -z "$CLAIMABLE_WORM" ]; then
        echo "❌ Error: Could not extract claimable WORM amount"
        return 1
    fi

    # Check if claimable WORM is greater than 0
    if [ "$CLAIMABLE_WORM" != "0.000000000000000000" ] && [ "$CLAIMABLE_WORM" != "0" ]; then
        echo "✅ Found claimable rewards: $CLAIMABLE_WORM WORM"
        # Set global variable for claim epoch (current epoch - 1)
        CLAIM_EPOCH=$((CURRENT_EPOCH - 1))
        echo "Will claim from epoch: $CLAIM_EPOCH"
        return 0
    else
        echo "❌ No claimable rewards found"
        CLAIM_EPOCH=""
        return 1
    fi
}

# Function to perform claim
perform_claim() {
    local from_epoch=$1
    echo "Attempting to claim from epoch $from_epoch..."
    
    worm-miner claim \
        --from-epoch "$from_epoch" \
        --num-epochs "$NUM_EPOCHS" \
        --private-key "$PRIVATE_KEY" \
        --network "$NETWORK" \
        --custom-rpc "$CUSTOM_RPC"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ Claim successful!"
    else
        echo "❌ Claim failed with exit code: $exit_code"
    fi
    
    sleep 5
    return $exit_code
}

# Main loop - run every hour
while true; do
    echo ""
    echo "🕐 $(date): Starting claim check..."

    get_miner_info
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ] && [ -n "$CLAIM_EPOCH" ]; then
        echo "💰 Found claimable rewards! Proceeding with claim..."
        perform_claim "$CLAIM_EPOCH"
    else
        echo "💤 No claimable rewards at this time, skipping claim..."
    fi

    echo "⏰ Next check in 1 hour..."
    echo "Press Ctrl+C to stop the script"

    sleep 3600
done
