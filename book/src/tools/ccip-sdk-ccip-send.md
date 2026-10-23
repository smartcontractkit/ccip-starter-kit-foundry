# CCIP SDK: `ccip-send` (Data, Token, Token+Data)

> **CCIP SDK package**
>
> Install from NPM: `npm install @chainlink/ccip-sdk`
>
> NPM: [https://www.npmjs.com/package/@chainlink/ccip-sdk](https://www.npmjs.com/package/@chainlink/ccip-sdk)
>
> Docs: [https://docs.chain.link/ccip/tools/sdk](https://docs.chain.link/ccip/tools/sdk)

This chapter shows how to run the SDK script for the three message shapes used in CCIP v2 examples:

1. data-only
2. token-only
3. token+data

The script lives in `sdk-examples/src/ccip-send.ts`.

## Receiver Compatibility for Fast Transfers (FTF)

When using `--block-confirmations > 0` (Fast Transfers), receiver compatibility matters for message modes that execute receiver callbacks.

| Mode | `--block-confirmations 0` | `--block-confirmations > 0` |
|---|---|---|
| `data` | baseline receiver works | destination receiver must allow the requested finality (see `getCCVsAndFinalityConfig` / `allowedFinalityConfig`) |
| `token-data` | baseline receiver works | destination receiver must allow the requested finality (see `getCCVsAndFinalityConfig` / `allowedFinalityConfig`) |
| `token` with `--gas-limit 0` | callback not executed (EOA-style token receive path) | callback not executed (EOA-style token receive path) |

Terminology note:

- Sender side (`ExtraArgsV3`): requested finality (e.g. `FinalityCodec` / block depth in `requestedFinalityConfig`)
- Receiver side (`getCCVsAndFinalityConfig`): `allowedFinalityConfig` (`bytes4`, `FinalityCodec`)

## How This Script Uses the SDK

At a high level, the script builds `EVMChain` instances for source and destination, asks the SDK for a fee quote, then submits the message via the SDK send call.

```ts
import { EVMChain } from '@chainlink/ccip-sdk'

const source = await EVMChain.fromUrl(sourceRpcUrl)
const dest = await EVMChain.fromUrl(destRpcUrl)

const fee = await source.getFee({ router, destChainSelector: dest.network.chainSelector, message })
await source.sendMessage({ router, destChainSelector: dest.network.chainSelector, message: { ...message, fee }, wallet })
```

## Prerequisites

Requires Node.js 24 or later (`@chainlink/ccip-sdk` 1.x uses syntax Node 22 cannot run).

From repo root:

```bash
npm --prefix sdk-examples install
```

For actual sends (non-`--dry-run`), set `USER_KEY` (or `PRIVATE_KEY`) in the root `.env`.

## RPC Configuration

`ccip-send` accepts RPC URLs either:

- directly via flags (`--source-rpc-url`, `--dest-rpc-url`)
- or from `.env`:
  - `CCIP_SOURCE_RPC_URL`, `CCIP_DEST_RPC_URL`
  - fallback: `ETHEREUM_SEPOLIA_RPC_URL`, `POLYGON_AMOY_RPC_URL`


## Variables

The commands below use the variables from your `.env` (see [Environment Variables](../index.md#environment-variables)); load them with `set -a; source .env; set +a`. Set the message parameters once:

```bash
export RECEIVER=$MY_EOA          # token-only: destination EOA on Amoy
export BLOCK_CONFIRMATIONS=1     # token modes: > 0 for Fast Transfers
export BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS=0x...  # data modes: the Amoy receiver from Example 02 / 03
```

## 1) Data-Only

Fast Transfers (`blockConfirmations=1`):

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode data \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --dest-rpc-url "$POLYGON_AMOY_RPC_URL" \
  --router $SEPOLIA_ROUTER \
  --receiver $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  --block-confirmations 1
```

Default finality (`blockConfirmations=0`):

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode data \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --dest-rpc-url "$POLYGON_AMOY_RPC_URL" \
  --router $SEPOLIA_ROUTER \
  --receiver $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  --block-confirmations 0
```

## 2) Token-Only

Use Sepolia CCIP-BnM and the finality check from [Example 01](../examples/example01-token-transfer-faster-than-finality.md).

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode token \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --dest-rpc-url "$POLYGON_AMOY_RPC_URL" \
  --router $SEPOLIA_ROUTER \
  --receiver $RECEIVER \
  --token $SEPOLIA_CCIP_BNM \
  --amount 1 \
  --block-confirmations $BLOCK_CONFIRMATIONS
```

## 3) Token + Data

Configure the Amoy receiver as in [Example 03](../examples/example03-programmable-token-transfer-data-and-token.md).

```bash
npm --prefix sdk-examples run ccip-send -- \
  --mode token-data \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --dest-rpc-url "$POLYGON_AMOY_RPC_URL" \
  --router $SEPOLIA_ROUTER \
  --receiver $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  --token $SEPOLIA_CCIP_BNM \
  --amount 1 \
  --data "hello + token" \
  --block-confirmations $BLOCK_CONFIRMATIONS
```

## If You Need Testnet Tokens

Use the Foundry faucet script on Sepolia:

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $SEPOLIA_CCIP_BNM
```
