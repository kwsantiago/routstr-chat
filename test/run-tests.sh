#!/bin/bash

# Run all invoice tests
# This script can be used locally or in CI

set -e

echo "Starting Invoice Test Suite"
echo "==========================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if regtest is running
if ! docker ps | grep -q "cashu-"; then
    echo "Starting regtest environment..."
    cd ~/cashu-regtest
    ./start.sh
    cd - > /dev/null
    echo "Waiting for services..."
    sleep 30
fi

# Check if mint is running
if ! curl -s http://localhost:3338/v1/info > /dev/null 2>&1; then
    echo "Starting Cashu mint..."
    "$SCRIPT_DIR/setup-regtest-mint.sh"
    sleep 10
fi

# Run basic tests
echo ""
echo "Running basic invoice tests..."
node "$SCRIPT_DIR/invoice-persistence.test.js"

# Run E2E tests
echo ""
echo "Running E2E tests..."
node "$SCRIPT_DIR/e2e-invoice.test.js"

echo ""
echo "==========================="
echo "All tests completed"