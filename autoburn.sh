#!/bin/bash

# Set default values
PRIVATE_KEY=${PRIVATE_KEY:-"0x65"}
CUSTOM_RPC=${CUSTOM_RPC:-"https://1rpc.io/sepolia"}

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
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--private-key KEY] [--custom-rpc URL]"
      exit 1
      ;;
  esac
done

echo "Using private key: $PRIVATE_KEY"
echo "Using RPC URL: $CUSTOM_RPC"
echo "================================="

while true; do
    echo "🔥 $(date): Starting burn attempt..."

    worm-miner burn \
        --network sepolia \
        --private-key "$PRIVATE_KEY" \
        --amount 1 \
        --spend 0.999 \
        --fee 0.001 \
        --custom-rpc "$CUSTOM_RPC"

    exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ Burn successful!"
    else
        echo "❌ Burn failed with exit code: $exit_code"
    fi
done