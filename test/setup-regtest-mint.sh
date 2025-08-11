#!/bin/bash

set -e

echo "Starting Cashu mint for regtest"

REGTEST_DIR="$HOME/cashu-regtest"

# Wait for cashu containers to be ready
echo "Waiting for cashu containers..."
MAX_WAIT=60
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Check for either cashu-lnd-2 or cashu-lnd-2-1 (docker-compose naming)
    if docker ps | grep -qE "cashu-lnd-2($|-1)"; then
        echo "cashu-lnd-2 container found"
        break
    fi
    echo "Waiting for cashu-lnd-2 container... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo "Timeout waiting for cashu-lnd-2 container"
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Stop existing mint
docker stop cashu-regtest-mint 2>/dev/null || true
docker rm cashu-regtest-mint 2>/dev/null || true

# Wait a bit more for container to fully initialize
echo "Waiting for lnd-2 to fully initialize..."
sleep 5

# Copy LND files - use docker cp for CI compatibility
mkdir -p /tmp/cashu-lnd

# Try direct copy first (for local dev)
if cp "$REGTEST_DIR/data/lnd-2/tls.cert" /tmp/cashu-lnd/ 2>/dev/null; then
    cp "$REGTEST_DIR/data/lnd-2/data/chain/bitcoin/regtest/admin.macaroon" /tmp/cashu-lnd/ 2>/dev/null || {
        # Try docker cp as fallback for macaroon (try both container names)
        docker cp cashu-lnd-2:/root/.lnd/data/chain/bitcoin/regtest/admin.macaroon /tmp/cashu-lnd/ 2>/dev/null || \
        docker cp cashu-lnd-2-1:/root/.lnd/data/chain/bitcoin/regtest/admin.macaroon /tmp/cashu-lnd/ || {
            echo "Could not copy admin.macaroon. Check regtest is running."
            exit 1
        }
    }
else
    # Use docker cp (for CI) - try both container names
    (docker cp cashu-lnd-2:/root/.lnd/tls.cert /tmp/cashu-lnd/ 2>/dev/null || \
     docker cp cashu-lnd-2-1:/root/.lnd/tls.cert /tmp/cashu-lnd/) || {
        echo "Could not copy tls.cert. Check regtest is running."
        exit 1
    }
    (docker cp cashu-lnd-2:/root/.lnd/data/chain/bitcoin/regtest/admin.macaroon /tmp/cashu-lnd/ 2>/dev/null || \
     docker cp cashu-lnd-2-1:/root/.lnd/data/chain/bitcoin/regtest/admin.macaroon /tmp/cashu-lnd/) || {
        echo "Could not copy admin.macaroon. Check regtest is running."
        exit 1
    }
fi

# Determine the correct network name
NETWORK_NAME=$(docker network ls | grep cashu | awk '{print $2}' | head -1)
if [ -z "$NETWORK_NAME" ]; then
    echo "Error: No cashu network found. Ensure regtest is running."
    exit 1
fi
echo "Using network: $NETWORK_NAME"

# Start mint
docker run -d \
  --name cashu-regtest-mint \
  --network "$NETWORK_NAME" \
  -p 3338:3338 \
  -e MINT_LISTEN_HOST=0.0.0.0 \
  -e MINT_LISTEN_PORT=3338 \
  -e MINT_PRIVATE_KEY=REGTEST_PRIVATE_KEY \
  -e MINT_BACKEND_BOLT11_SAT=LndRestWallet \
  -e MINT_LND_REST_ENDPOINT=https://lnd-2:8081 \
  -e MINT_LND_REST_CERT=/lnd/tls.cert \
  -e MINT_LND_REST_MACAROON=/lnd/admin.macaroon \
  -e MINT_DATABASE=/data/regtest-mint.db \
  -e MINT_INFO_NAME="Regtest Mint" \
  -e DEBUG=true \
  -v /tmp/cashu-lnd:/lnd:ro \
  -v cashu-mint-data:/data \
  cashubtc/nutshell:0.16.0 \
  poetry run mint

sleep 5
if curl -s http://localhost:3338/v1/info > /dev/null 2>&1; then
    echo "Mint running at http://localhost:3338"
    echo "Run: npm run dev"
    echo "Set mint URL in browser console to http://localhost:3338"
else
    echo "Mint starting. Check: docker logs -f cashu-regtest-mint"
fi