# Example 01: Token Transfer + Faster Than Finality

This example sends one token transfer message using `ExtraArgsV3` with Faster Than Finality (`blockConfirmations > 0`).

Script path: `script/examples/Example01.s.sol`

## What You Will Do

1. Mint 1 CCIP-BnM token to your EOA with `script/Faucet.s.sol`.
2. Send that token from source chain to destination chain with `script/examples/Example01.s.sol`.

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

## Step 2: (Optional) Check Executor Minimum Block Confirmations

Before picking a block depth for Faster Than Finality, you can verify the executor minimum:

```ts
import {Executor} from "@chainlink/contracts-ccip/contracts/executor/Executor.sol";
Executor executor = Executor(EXECUTOR_ADDRESS);
console2.log("Min block confirmations", executor.getMinBlockConfirmations());
```

Why this matters:

- If your requested `blockConfirmations` is below executor minimum, the send can revert.
- If your requested `blockConfirmations` is greater than chain finality, default finality is used.

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
- `<BLOCK_CONFIRMATIONS_GT_ZERO>`: must be `> 0` in this Faster Than Finality example.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example01` logs the message ID.

Use that ID in the CCIP Explorer to monitor status:

- https://ccip.chain.link
