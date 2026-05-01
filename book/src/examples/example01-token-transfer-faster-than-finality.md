# Example 01: Token Transfer + Faster Than Finality

This example sends one token transfer message using `ExtraArgsV3` with Faster Than Finality (`blockConfirmations > 0`).

Script path: `script/examples/Example01.s.sol`

## What You Will Do

1. Mint 1 CCIP-BnM token to your EOA with `script/Faucet.s.sol`.
2. (Optional) Read the executor allowed finality config (`FinalityCodec` `bytes4`) on the source chain.
3. Send that token from source chain to destination chain with `script/examples/Example01.s.sol`.

## Before You Start

> **Important: Keystore first**
>
> Use a local keystore account for script execution:
>
> ```bash
> cast wallet import myAccount --interactive
> Enter private key:
> Enter password:
> `myAccount` keystore was saved successfully. Address: <YOUR_EOA_ADDRESS_SHOULD_APPEAR_HERE>
> ```
>
> This chapter assumes `--account myAccount`.


## Step 1: Get 1 CCIP-BnM Token

Use the faucet script on the source chain:

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <CCIP_BNM_SOURCE_TOKEN_ADDRESS>
```

## Step 2: (Optional) Check Executor Allowed Finality

Before choosing a Faster Than Finality depth in `ExtraArgsV3`, you can read what finality modes the **Executor** allows. The on-chain API is **`getAllowedFinalityConfig() → bytes4`**, encoded with **`FinalityCodec`** (same family of values as `requestedFinalityConfig` in your message’s ExtraArgs).

From a shell (replace RPC and address):

```bash
cast call <EXECUTOR_ADDRESS> "getAllowedFinalityConfig()(bytes4)" --rpc-url <SOURCE_CHAIN_RPC_URL>
```

Why this matters:

- Your requested finality (derived from `blockConfirmations` in `EncodeExtraArgsOffchain` / `Example01` via **`FinalityCodec._encodeBlockDepth`**) must be **permitted** by the executor’s dynamic config; otherwise the send can revert.

## Step 3: Send Token With Faster Than Finality

Run `Example01`:

```bash
forge script script/examples/Example01.s.sol:Example01 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,uint16,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <RECEIVER_ON_DESTINATION_CHAIN> \
  <CCIP_BNM_SOURCE_TOKEN_ADDRESS> \
  <AMOUNT> \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS_GT_ZERO> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<AMOUNT>`: token amount in token decimals (for 18 decimals, `1e18` is 1 token).
- `<GAS_LIMIT>`: set to `0` for token-only transfer to an EOA receiver.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>`: must be `> 0` in this Faster Than Finality example; pick a depth consistent with the executor’s allowed finality from Step 2 and lane policy.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example01` logs the message ID.

Use that ID in the CCIP Explorer to monitor status:

- https://ccip.chain.link
