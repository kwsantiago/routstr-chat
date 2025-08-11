#!/bin/bash

# Pay Lightning invoice in regtest
# Usage: ./pay-invoice.sh <invoice>

if [ -z "$1" ]; then
    echo "Usage: $0 <invoice>"
    exit 1
fi

INVOICE=$1

# Check lnd-1 balance
BALANCE=$(docker exec cashu-lnd-1-1 lncli --network=regtest --rpcserver=lnd-1:10009 walletbalance 2>/dev/null | grep confirmed_balance | grep -o '[0-9]*' | head -1)

if [ "$BALANCE" = "0" ] || [ -z "$BALANCE" ]; then
    echo "Funding lnd-1..."
    
    # Fund wallet
    ADDR=$(docker exec cashu-lnd-1-1 lncli --network=regtest --rpcserver=lnd-1:10009 newaddress p2wkh | grep address | cut -d'"' -f4)
    docker exec cashu-bitcoind-1 bitcoin-cli -regtest -rpcuser=cashu -rpcpassword=cashu sendtoaddress $ADDR 1 >/dev/null
    docker exec cashu-bitcoind-1 bitcoin-cli -regtest -rpcuser=cashu -rpcpassword=cashu generatetoaddress 6 $ADDR >/dev/null
    echo "Funded with 1 BTC"
    
    # Open channel
    echo "Opening channel to lnd-2..."
    LND2_PUBKEY=$(docker exec cashu-lnd-2-1 lncli --network=regtest --rpcserver=lnd-2:10009 getinfo | grep identity_pubkey | cut -d'"' -f4)
    docker exec cashu-lnd-1-1 lncli --network=regtest --rpcserver=lnd-1:10009 openchannel --node_key=$LND2_PUBKEY --connect=lnd-2:9735 --local_amt=1000000 >/dev/null
    docker exec cashu-bitcoind-1 bitcoin-cli -regtest -rpcuser=cashu -rpcpassword=cashu generatetoaddress 6 $ADDR >/dev/null
    echo "Channel opened"
fi

# Pay
echo "Paying invoice..."
docker exec cashu-lnd-1-1 lncli --network=regtest --rpcserver=lnd-1:10009 payinvoice --force "$INVOICE"