# Test Directory

Lightning invoice testing with regtest.

## Quick Start

```bash
# Run all tests
npm run test:invoices

# Or use the test runner
./test/run-tests.sh
```

## Test Files

- `invoice-persistence.test.js` - Basic invoice tests
- `e2e-invoice.test.js` - End-to-end tests
- `run-tests.sh` - Run all tests
- `setup-regtest-mint.sh` - Setup Cashu mint
- `pay-invoice.sh` - Pay invoices

## CI/CD

Tests run automatically on PRs that modify:
- Lightning/Cashu code
- Invoice hooks
- Store files

See `.github/workflows/test-invoices.yml`

## Manual Setup

```bash
# Get regtest
cd ~ && git clone https://github.com/callebtc/cashu-regtest.git
cd ~/cashu-regtest && ./start.sh

# Start mint
npm run test:setup

# Run tests
npm run test:invoices
```

See [setup guide](./LIGHTNING_TESTING_SETUP.md) for details.