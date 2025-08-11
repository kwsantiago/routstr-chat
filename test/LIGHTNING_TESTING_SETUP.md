# Lightning Testing Setup

Test Lightning invoice persistence locally with Docker and regtest.

## Prerequisites

- Docker
- Node.js 18+
- 2GB free disk space
- Port 3338 available

## Setup

### 1. Start regtest

```bash
# Clone the official Cashu regtest environment
cd ~
git clone https://github.com/callebtc/cashu-regtest.git
cd cashu-regtest

# Start the regtest network (Bitcoin + Lightning nodes)
./start.sh
```

Provides Bitcoin regtest, 3 LND nodes, 2 CLN nodes.

### 2. Start Cashu mint

```bash
# From the project directory
./test/setup-regtest-mint.sh
```

Runs mint on http://localhost:3338, connects to LND, creates regtest invoices.

### 3. Configure app

```bash
# Set test mode in .env.local
echo "NEXT_PUBLIC_TEST_MODE=true" > .env.local
echo "NEXT_PUBLIC_LOCAL_MINT_URL=http://localhost:3338" >> .env.local

# Start the app
npm run dev
```

### 4. Set mint URL

In browser console at http://localhost:3000:

```javascript
// Set mint URL
localStorage.clear();
localStorage.setItem('mint_url', 'http://localhost:3338');
location.reload();
```

## Test Invoice Persistence

1. Create invoice in Settings > Wallet
2. Copy the lnbcrt invoice
3. Close browser tab

4. Pay invoice:
   ```bash
   ./test/pay-invoice.sh <invoice>
   ```

5. Reopen app - invoice should be marked paid, balance updated

Check stored invoices:
```javascript
JSON.parse(localStorage.getItem('lightning_invoices') || '[]')
```

## Commands

### Start
```bash
cd ~/cashu-regtest && ./start.sh    # Start regtest
./test/setup-regtest-mint.sh        # Start mint
npm run dev                          # Start app
```

### Stop
```bash
cd ~/cashu-regtest && ./stop.sh     # Stop regtest
docker stop cashu-regtest-mint      # Stop mint
```

### Status
```bash
docker ps | grep cashu               # View running containers
docker logs -f cashu-regtest-mint   # View mint logs
```

## Project Structure

```
test/
├── setup-regtest-mint.sh    # Main setup script
├── pay-invoice.sh           # Helper to pay invoices
└── LIGHTNING_TESTING_SETUP.md  # This file
```

## What This Tests

- Invoice creation (regtest format)
- Persistence across browser sessions
- Payment detection
- Balance updates
- Invoice history

## Troubleshooting

### Port 8081 in use
- The regtest uses port 8082 for lnd-2 instead

### Invoice not detected
- Check mint is running: `curl http://localhost:3338/v1/info`
- Verify invoice in localStorage
- Check 5-second interval is active (test mode)

### Payment fails
- Ensure lnd-1 has balance: `./test/fund-lnd.sh`
- Check channel exists: `./test/check-channels.sh`

## Clean Up

```bash
# Stop all containers
cd ~/cashu-regtest && ./stop.sh
docker stop cashu-regtest-mint
docker rm cashu-regtest-mint

# Remove test data
docker volume rm cashu-mint-data
rm -rf ~/cashu-regtest  # Optional: remove regtest environment
```

## Notes

- Invoice check interval: 60 seconds
- Invoices use regtest format (lnbcrt)
- No real Bitcoin involved
