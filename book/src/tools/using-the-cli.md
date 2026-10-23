# Using the CCIP CLI

> **CCIP CLI package**
>
> Install globally from NPM: `npm install -g @chainlink/ccip-cli`
>
> NPM: [https://www.npmjs.com/package/@chainlink/ccip-cli](https://www.npmjs.com/package/@chainlink/ccip-cli)
>
> Docs: [https://docs.chain.link/ccip/tools/cli](https://docs.chain.link/ccip/tools/cli)

This chapter covers:

1. CLI install
2. observability commands after Foundry/SDK sends
3. send parity commands for data-only, token-only, and token+data

## Install and Verify

```bash
npm install -g @chainlink/ccip-cli
```

```bash
ccip-cli --version
ccip-cli --help
```

## Variables

The commands below use the variables from your `.env` (see [Environment Variables](../index.md#environment-variables)); load them with `set -a; source .env; set +a`. `send` also needs a signing key and a receiver, and the `show` commands need a transaction hash or message ID:

```bash
export USER_KEY=0x...            # private key of a funded test account (never commit it)
export RECEIVER=$MY_EOA          # destination address (a deployed receiver for data messages)
export SOURCE_TX_HASH=0x...      # from your send logs
export MESSAGE_ID=0x...          # from your send logs
```

## Observability

### 1) Inspect by source transaction hash

```bash
ccip-cli show $SOURCE_TX_HASH \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL"
```

`$SOURCE_TX_HASH` is the source-chain transaction hash.  
`$ETHEREUM_SEPOLIA_RPC_URL` and `$POLYGON_AMOY_RPC_URL` are the RPC endpoints for the source and destination chains.

Wait for delivery from the same command:

```bash
ccip-cli show $SOURCE_TX_HASH \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL" \
  --wait
```

`--wait` keeps polling until destination execution status is available.

### 2) Inspect by `messageId`

`tx-hash` positional becomes `messageId` when `--id-from-source` is used:

```bash
ccip-cli show $MESSAGE_ID \
  --id-from-source $SEPOLIA_CHAIN_SELECTOR \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL"
```

`$MESSAGE_ID` is the CCIP message ID.  
`$SEPOLIA_CHAIN_SELECTOR` is the source CCIP chain selector.

## Send Parity (CLI)

### TO DO: Adapt these examples to use ExtraArgsV3

### 1) Data-only

```bash
ccip-cli send -s $SEPOLIA_CHAIN_SELECTOR -d $AMOY_CHAIN_SELECTOR -r $SEPOLIA_ROUTER \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL" \
  --wallet "$USER_KEY" \
  --receiver $RECEIVER \
  --data "hello from ccip-cli" \
  --gas-limit 200000 \
  --wait
```

`$SEPOLIA_CHAIN_SELECTOR` and `$AMOY_CHAIN_SELECTOR` can be chain ID, chain selector, or chain name.  
Chain ID examples: Ethereum Sepolia `11155111`, Polygon Amoy `80002`.  
`$SEPOLIA_ROUTER` is the source-chain router for the selected lane.

### 2) Token-only

```bash
ccip-cli send -s $SEPOLIA_CHAIN_SELECTOR -d $AMOY_CHAIN_SELECTOR -r $SEPOLIA_ROUTER \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL" \
  --wallet "$USER_KEY" \
  --receiver $RECEIVER \
  --transfer-tokens $SEPOLIA_CCIP_BNM=1 \
  --gas-limit 0 \
  --wait
```

`$SEPOLIA_CCIP_BNM=1` uses `token=amount` format.  
`1` is human-readable; CLI converts it using token decimals.

### 3) Token + data

```bash
ccip-cli send -s $SEPOLIA_CHAIN_SELECTOR -d $AMOY_CHAIN_SELECTOR -r $SEPOLIA_ROUTER \
  --rpcs "$ETHEREUM_SEPOLIA_RPC_URL" \
  --rpcs "$POLYGON_AMOY_RPC_URL" \
  --wallet "$USER_KEY" \
  --receiver $RECEIVER \
  --data "hello + token" \
  --transfer-tokens $SEPOLIA_CCIP_BNM=1 \
  --gas-limit 200000 \
  --wait
```

Same chain/router placeholders as above; `--transfer-tokens` uses the same `token=amount` format.

## Token Amount Format

`--transfer-tokens` currently uses `token=amount` format.  
Amount is human-readable and CLI converts it using token decimals.

Examples:

- `--transfer-tokens $SEPOLIA_CCIP_BNM=1` means 1 whole token.
- `--transfer-tokens $SEPOLIA_CCIP_BNM=1.5` means 1.5 tokens.
