# CCIP SDK: `ccip-track` (Tx Hash, Message ID, Sender)

> **CCIP SDK package**
>
> Install from NPM: `npm install @chainlink/ccip-sdk`
>
> NPM: [https://www.npmjs.com/package/@chainlink/ccip-sdk](https://www.npmjs.com/package/@chainlink/ccip-sdk)
>
> Docs: [https://docs.chain.link/ccip/tools/sdk](https://docs.chain.link/ccip/tools/sdk)

This chapter shows how to track CCIP v2 messages from source-chain activity using the SDK script:

- `sdk-examples/src/ccip-track.ts`

## How This Script Uses the SDK

The tracking script uses the SDK in three paths: fetch messages from a source tx hash, fetch by message ID, and stream sender history from source-chain logs.

```ts
import { EVMChain, getMessagesForSender } from '@chainlink/ccip-sdk'

const source = await EVMChain.fromUrl(sourceRpcUrl)
const byTx = await source.getMessagesInTx(sourceTxHash)
const byId = await source.getMessageById(messageId)

for await (const msg of getMessagesForSender(source, sender, { startBlock })) {
  console.log(msg.message.messageId)
}
```

## Prerequisites

Requires Node.js 24 or later (`@chainlink/ccip-sdk` 1.x uses syntax Node 22 cannot run).

From repo root:

```bash
npm --prefix sdk-examples install
```

## RPC Configuration

`ccip-track` reads source RPC URL from:

- `--source-rpc-url <url>` flag, or
- `.env`:
  - `CCIP_SOURCE_RPC_URL`
  - fallback: `ETHEREUM_SEPOLIA_RPC_URL`

```bash
source .env
```

## 1) Track by Source Transaction Hash

Use a source tx hash from your Foundry run (for example `Example01`-`Example08`):

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --tx-hash <SOURCE_TX_HASH> 
```

## 2) Track by Message ID

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --message-id <MESSAGE_ID>
```

Output prints the same concise SDK summary for that message ID.

## 3) Track by Sender

```bash
npm --prefix sdk-examples run ccip-track -- \
  --source-rpc-url "$ETHEREUM_SEPOLIA_RPC_URL" \
  --limit 10 \
  --sender <SENDER_ADDRESS>
```

Arguments:

- `--limit`: max rows to print (default `10`)
- `--start-block`: first source block to scan (default `0`)
