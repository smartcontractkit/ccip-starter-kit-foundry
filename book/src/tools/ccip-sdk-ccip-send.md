# CCIP SDK: `ccip-send` (Data, Token, Token+Data)

This chapter shows how to run the SDK script for the three message shapes used in CCIP v2 examples:

1. data-only
2. token-only
3. token+data

The script lives in `sdk-examples/src/ccip-send.ts`.

## Prerequisites

From repo root:

```bash
npm --prefix sdk-examples install
```

For actual sends (non-`--dry-run`), set a funded sender key in `.env`:

```bash
USER_KEY=0x...
```

```bash
source .env
```

## RPC Configuration

`ccip-send` accepts RPC URLs either:

- directly via flags (`--source-rpc-url`, `--dest-rpc-url`)
- or from `.env`:
  - `CCIP_SOURCE_RPC_URL`, `CCIP_DEST_RPC_URL`
  - fallback: `AVALANCHE_FUJI_RPC_URL`, `ETHEREUM_SEPOLIA_RPC_URL`


## 1) Data-Only

Faster Than Finality (`blockConfirmations=1`):

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode data \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --dest-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --router <SOURCE_ROUTER> \
  --receiver <RECEIVER> \
  --block-confirmations 1
```

Default finality (`blockConfirmations=0`):

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode data \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --dest-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --router <SOURCE_ROUTER> \
  --receiver <RECEIVER> \
  --block-confirmations 0
```

## 2) Token-Only

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode token \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --dest-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --router <SOURCE_ROUTER> \
  --receiver <RECEIVER> \
  --token <TOKEN_ADDRESS> \
  --amount 1 \
  --block-confirmations 1
```

## 3) Token + Data

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode token-data \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --dest-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --router <SOURCE_ROUTER> \
  --receiver <RECEIVER> \
  --token <TOKEN_ADDRESS> \
  --amount 1 \
  --data "hello + token" \
  --block-confirmations 1
```

## If You Need Testnet Tokens

You can mint one CCIP-BnM token to your sender with the existing Foundry faucet script:

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <CCIP_BNM_TOKEN_ADDRESS_ON_SOURCE_CHAIN>
```

Repeat as needed to accumulate test tokens.
