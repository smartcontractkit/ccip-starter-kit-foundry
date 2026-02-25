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

## Observability

### 1) Inspect by source transaction hash

```bash
ccip-cli show <SOURCE_TX_HASH> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL>
```

`<SOURCE_TX_HASH>` is the source-chain transaction hash.  
`<SOURCE_RPC_URL>` and `<DEST_RPC_URL>` are RPC endpoints for the source and destination chains.

Wait for delivery from the same command:

```bash
ccip-cli show <SOURCE_TX_HASH> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL> \
  --wait
```

`--wait` keeps polling until destination execution status is available.

### 2) Inspect by `messageId`

`tx-hash` positional becomes `messageId` when `--id-from-source` is used:

```bash
ccip-cli show <MESSAGE_ID> \
  --id-from-source <SOURCE_CHAIN_SELECTOR> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL>
```

`<MESSAGE_ID>` is the CCIP message ID.  
`<SOURCE_CHAIN_SELECTOR>` is the source CCIP chain selector (example: Avalanche Fuji `14767482510784806043`).

## Send Parity (CLI)

### TO DO: Adapt these examples to use ExtraArgsV3

### 1) Data-only

```bash
ccip-cli send -s <SOURCE_CHAIN> -d <DEST_CHAIN> -r <SOURCE_ROUTER> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL> \
  --wallet <PRIVATE_KEY> \
  --receiver <RECEIVER_ADDRESS> \
  --data "hello from ccip-cli" \
  --gas-limit 200000 \
  --wait
```

`<SOURCE_CHAIN>` and `<DEST_CHAIN>` can be chain ID, chain selector, or chain name.  
Chain ID examples: Avalanche Fuji `43113`, Ethereum Sepolia `11155111`.  
`<SOURCE_ROUTER>` is the source-chain router for the selected lane.

### 2) Token-only

```bash
ccip-cli send -s <SOURCE_CHAIN> -d <DEST_CHAIN> -r <SOURCE_ROUTER> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL> \
  --wallet <PRIVATE_KEY> \
  --receiver <RECEIVER_ADDRESS> \
  --transfer-tokens <TOKEN_ADDRESS>=<TOKEN_AMOUNT> \
  --gas-limit 0 \
  --wait
```

`<TOKEN_ADDRESS>=<TOKEN_AMOUNT>` uses `token=amount` format.  
`<TOKEN_AMOUNT>` is human-readable; CLI converts it using token decimals.

### 3) Token + data

```bash
ccip-cli send -s <SOURCE_CHAIN> -d <DEST_CHAIN> -r <SOURCE_ROUTER> \
  --rpcs <SOURCE_RPC_URL> \
  --rpcs <DEST_RPC_URL> \
  --wallet <PRIVATE_KEY> \
  --receiver <RECEIVER_ADDRESS> \
  --data "hello + token" \
  --transfer-tokens <TOKEN_ADDRESS>=<TOKEN_AMOUNT> \
  --gas-limit 200000 \
  --wait
```

Same chain/router placeholders as above; `--transfer-tokens` uses the same `token=amount` format.

## Token Amount Format

`--transfer-tokens` currently uses `token=amount` format.  
Amount is human-readable and CLI converts it using token decimals.

Examples:

- `--transfer-tokens <TOKEN_ADDRESS>=1` means 1 whole token.
- `--transfer-tokens <TOKEN_ADDRESS>=1.5` means 1.5 tokens.
