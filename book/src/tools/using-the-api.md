# Using the CCIP API

> CCIP API is available at: 
> 
> [https://api.ccip.chain.link/](https://api.ccip.chain.link/)
>
> Documentation at:
>
> [https://docs.chain.link/ccip/tools/api/](https://docs.chain.link/ccip/tools/api/)

With the CCIP REST API you can:

- fetch one message by `messageId`
- search your messages by sender, chain selectors, or source tx hash
- paginate through large result sets with `cursor`
- filter messages that are ready for manual execution
- read lane latency (`totalMs`) to estimate route timing

---

## Set your variables once

Paste this once per terminal session, replace with your values, then run the commands below.
Use the same EOA and `messageId` you got from your Foundry examples.

```bash
export MY_EOA="0xYourEoaAddressHere"
export MESSAGE_ID="0xYourMessageIdFromExample01Logs"   # optional
```

---

## Get one message by ID

After [Example 01](../examples/example01-token-transfer-faster-than-finality.md) (or any send), the script logs a message ID. Fetch its status and full details:

```bash
curl -s -X 'GET' \
  "https://api.ccip.chain.link/v2/messages/${MESSAGE_ID}" \
  -H 'accept: application/json' | jq
```

Or open in browser:

```text
https://api.ccip.chain.link/v2/messages/<MESSAGE_ID>
```

You get `status`, source/dest network, `sendTransactionHash`, `receiptTransactionHash`, token amounts, fees. If you didn’t set `MESSAGE_ID`, set it to a real ID from your logs and run again.

---

## List your messages (search, paginate, filter)

After you run a few examples, this is the fastest way to inspect only your own CCIP traffic.

**Last 10 messages:**

```bash
curl -s -X 'GET' \
  "https://api.ccip.chain.link/v2/messages?sender=${MY_EOA}&limit=10" \
  -H 'accept: application/json' | jq
```

The response has `data` (array of message summaries) and `pagination` with `limit`, `hasNextPage`, and `cursor`. Each item has a `messageId`; use the “Get one message” curl above with that ID to see full details and `status`.

**Next page:** copy the `cursor` value from the response, then run:

```bash
export CURSOR="paste_the_cursor_value_here"
```
```bash
curl -s -X 'GET' \
  "https://api.ccip.chain.link/v2/messages?cursor=${CURSOR}&limit=10" \
  -H 'accept: application/json' | jq
```

Don’t mix `cursor` with other query params (sender, chain selectors, etc.).

**Filter by:**

- **Ready for manual execution** (e.g. from [Example 05](../examples/example05-extraargsv3-no-execution-tag-manual-execution.md)): add `&readyForManualExecOnly=true`
- **Source chain** or **destination chain**: add `&sourceChainSelector=...` or `&destChainSelector=...` (values from [CCIP Directory](https://docs.chain.link/ccip/directory))

Examples:

```bash
# Only messages ready for manual execution
curl -s -X 'GET' \
  "https://api.ccip.chain.link/v2/messages?sender=${MY_EOA}&readyForManualExecOnly=true&limit=10" \
  -H 'accept: application/json' | jq

# Only messages from a given source chain (selector from CCIP Directory)
curl -s -X 'GET' \
  "https://api.ccip.chain.link/v2/messages?sender=${MY_EOA}&sourceChainSelector=14767482510784806043&limit=10" \
  -H 'accept: application/json' | jq
```

---

## Lane latency

To show “about X minutes” for a route, call the latency endpoint with source and destination chain selectors ([CCIP Directory](https://docs.chain.link/ccip/directory)). This one needs no variables—paste and run:

```bash
curl -s -X 'GET' \
  'https://api.ccip.chain.link/v2/lanes/latency?sourceChainSelector=14767482510784806043&destChainSelector=16015286601757825753' \
  -H 'accept: application/json' | jq
```

Response includes `totalMs` (p90 in milliseconds). Swap the selectors for the same chains you use in your examples.
