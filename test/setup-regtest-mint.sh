#!/bin/bash

set -e

echo "Starting Cashu mint for regtest"

REGTEST_DIR="$HOME/cashu-regtest"

# Check regtest
if ! docker ps | grep -q "cashu-"; then
    echo "Regtest not running. Start with: cd ~/cashu-regtest && ./start.sh"
    exit 1
fi

# Stop existing mint
docker stop cashu-regtest-mint 2>/dev/null || true
docker rm cashu-regtest-mint 2>/dev/null || true

# Copy LND files
mkdir -p /tmp/cashu-lnd
cp "$REGTEST_DIR/data/lnd-2/tls.cert" /tmp/cashu-lnd/ 2>/dev/null || {
    echo "Could not copy LND files. Check regtest is running."
    exit 1
}
cp "$REGTEST_DIR/data/lnd-2/data/chain/bitcoin/regtest/admin.macaroon" /tmp/cashu-lnd/

# Start mint
docker run -d \
  --name cashu-regtest-mint \
  --network cashu_default \
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