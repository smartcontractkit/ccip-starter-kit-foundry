# Example 02: Hello World to BasicMessageReceiverWithCCVs (Faster Than Finality)

This example deploys a destination `BasicMessageReceiverWithCCVs` contract and sends a Hello World data message from an EOA using Faster Than Finality (`blockConfirmations > 0`).

Scripts used:

- `script/examples/Example02.s.sol:DeployBasicMessageReceiverWithCCVs`
- `script/examples/Example02.s.sol:SetBasicMessageReceiverWithCCVsMinBlockDepth`
- `script/examples/Example02.s.sol:Example02`

## What You Will Do

1. Deploy `BasicMessageReceiverWithCCVs` on destination chain.
2. Configure minimum block depth for the source chain.
3. Send a Hello World CCIP data message from source chain to `BasicMessageReceiverWithCCVs`.

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

## Receiver Contract Context

### Pre-v2.0

To receive CCIP messages (data or data+tokens), contracts implemented `IAny2EVMMessageReceiver`:

```ts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IAny2EVMMessageReceiver {
  function ccipReceive(
    Client.Any2EVMMessage calldata message
  ) external;
}
```

As a convenience, applications generally inherited `CCIPReceiver.sol` and implemented `_ccipReceive`.

### CCIP v2.0

In v2.0, receivers expose Cross Chain Verifiers and finality requirements via `getCCVsAndFinalityConfig` (encoded with `FinalityCodec` as `bytes4 allowedFinalityConfig`):

```ts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IAny2EVMMessageReceiverV2 {
  function ccipReceive(
    Client.Any2EVMMessage calldata message
  ) external;

  function getCCVsAndFinalityConfig(
    uint64 sourceChainSelector,
    bytes calldata sender
  )
    external
    view
    returns (
      address[] memory requiredCCVs,
      address[] memory optionalCCVs,
      uint8 optionalThreshold,
      bytes4 allowedFinalityConfig
    );
}
```

The receiver controls two independent dimensions:

- `requiredCCVs` and `optionalCCVs` define additional verifiers required for acceptance.
- `allowedFinalityConfig` defines which requested finality modes are accepted (see `FinalityCodec` in chainlink-ccip). A zero value (`WAIT_FOR_FINALITY_FLAG`) means only fully finalized messages are accepted.

You can combine these independently (for example, add verifiers while requiring full finality, or allow faster-than-finality modes when policy allows).

In this starter kit, `src/BasicMessageReceiverWithCCVs.sol` adds configurable verifier sets and stores a per-chain minimum block depth, which it exposes via `FinalityCodec._encodeBlockDepth` in `getCCVsAndFinalityConfig`.

## Step 1: Deploy `BasicMessageReceiverWithCCVs` on Destination Chain

Run:

```bash
forge script script/examples/Example02.s.sol:DeployBasicMessageReceiverWithCCVs \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <DESTINATION_ROUTER>
```

Save the deployed address as `<BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS>`.

By default, this receiver starts with `minBlockDepth = 0` (default finality only) for all source chains.

## Step 2: Configure Minimum Block Depth for Your Source Chain

Run:

```bash
forge script script/examples/Example02.s.sol:SetBasicMessageReceiverWithCCVsMinBlockDepth \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,uint16)" \
  <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> \
  <SOURCE_CHAIN_SELECTOR> \
  <MIN_BLOCK_DEPTH>
```

For this chapter, use `<MIN_BLOCK_DEPTH> = 1`.

- `0` means deafault finality-only behavior.
- `> 0` enables Faster Than Finality with that minimum depth.

## Step 3: Send Hello World Data Message from EOA

Run:

```bash
forge script script/examples/Example02.s.sol:Example02 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,uint32,uint16,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> \
  "Hello, World" \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS_GT_ZERO> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<GAS_LIMIT>` must be `> 0` because the destination receiver callback needs gas.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>` must be `> 0` for Faster Than Finality.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>` should be greater than or equal to `<MIN_BLOCK_DEPTH>`.
- Executor may enforce a minimum block confirmations value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example02` logs a CCIP message ID.

Use that ID in the CCIP Explorer:

- https://ccip.chain.link

You can inspect receiver state on destination chain:

```bash
cast call <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> "latestMessage()(bytes)" --rpc-url ethereumSepolia
```
