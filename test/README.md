# Test Directory

Lightning invoice testing with regtest.

## Setup

```bash
# Get regtest environment
cd ~ && git clone https://github.com/callebtc/cashu-regtest.git
cd ~/cashu-regtest && ./start.sh

# Start mint
./setup-regtest-mint.sh

# Run app
npm run dev
```

## Files

- `LIGHTNING_TESTING_SETUP.md` - Full documentation
- `setup-regtest-mint.sh` - Starts Cashu mint
- `pay-invoice.sh` - Pay invoices

See [setup guide](./LIGHTNING_TESTING_SETUP.md) for details.