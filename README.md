<div align="center">
  <h2><code>Wolta Finance</code></h2>
</div>

<br/>

Basic yield optimizer on Polygon.

### Setup instructions

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run an individual test
npm test -- ./test/strategies/polygon/sushiswap/PolygonSushiDoubleFarm_WMATIC_WETH.test.ts

```

We're using mainnet forking for testing. In every individual test file, there should be a comment specifying the exact block number to be used when running that particular test (this is to assure deterministic execution). Put that block number together with the RPC of the corresponding network the test should running on in a `.env` file located in the root directory:

```bash
RPC_URL=
BLOCK_NUMBER=
```
