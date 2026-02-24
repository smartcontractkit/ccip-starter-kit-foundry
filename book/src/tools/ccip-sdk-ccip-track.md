# CCIP SDK: `ccip-track` (Tx Hash, Message ID, Sender)

This chapter shows how to track CCIP v2 messages from source-chain activity using the SDK script:

- `sdk-examples/src/ccip-track.ts`

## Prerequisites

From repo root:

```bash
npm --prefix sdk-examples install
```

## RPC Configuration

`ccip-track` reads source RPC URL from:

- `--source-rpc-url <url>` flag, or
- `.env`:
  - `CCIP_SOURCE_RPC_URL`
  - fallback: `AVALANCHE_FUJI_RPC_URL`

```bash
source .env
```

## 1) Track by Source Transaction Hash

Use a source tx hash from your Foundry run (for example `Example01`-`Example08`):

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --tx-hash <SOURCE_TX_HASH> 
```

## 2) Track by Message ID

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --message-id <MESSAGE_ID>
```

Output prints the same concise SDK summary for that message ID.

## 3) Track by Sender

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$AVALANCHE_FUJI_RPC_URL" \
  --limit 10 \
  --sender <SENDER_ADDRESS>
```

Arguments:

- `--limit`: max rows to print (default `10`)
- `--start-block`: first source block to scan (default `0`)
