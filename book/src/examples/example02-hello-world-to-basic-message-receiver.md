# Example 02: Hello World to BasicMessageReceiverWithCCVs with Fast Transfers (FTF)

This example deploys a destination `BasicMessageReceiverWithCCVs` contract and sends a Hello World data message from an EOA using Fast Transfers (`blockConfirmations > 0`).

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

## Chapter Parameters

Set the parameters for this chapter. The defaults work as they are; change a value only if you want something different.

```bash
export GAS_LIMIT=200000          # the receiver callback needs gas
export BLOCK_CONFIRMATIONS=1     # Fast Transfers depth, must be > 0
export MIN_BLOCK_DEPTH=1         # receiver minimum, must be <= BLOCK_CONFIRMATIONS
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $SEPOLIA_LINK to pay in LINK
```

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

You can combine these independently (for example, add verifiers while requiring full finality, or allow Fast Transfers when policy allows).

In this starter kit, `src/BasicMessageReceiverWithCCVs.sol` adds configurable verifier sets and stores a per-chain minimum block depth, which it exposes via `FinalityCodec._encodeBlockDepth` in `getCCVsAndFinalityConfig`.

## Step 1: Deploy `BasicMessageReceiverWithCCVs` on Destination Chain

Run:

```bash
forge script script/examples/Example02.s.sol:DeployBasicMessageReceiverWithCCVs \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $AMOY_ROUTER
```

Copy the deployed address from the `[RESULT]` log and export it:

```bash
export BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS=0x...
```

By default, this receiver starts with `minBlockDepth = 0` (default finality only) for all source chains.

## Step 2: Configure Minimum Block Depth for Your Source Chain

Run:

```bash
forge script script/examples/Example02.s.sol:SetBasicMessageReceiverWithCCVsMinBlockDepth \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,uint16)" \
  $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  $SEPOLIA_CHAIN_SELECTOR \
  $MIN_BLOCK_DEPTH
```

This chapter uses `MIN_BLOCK_DEPTH=1` (set in Chapter Parameters).

- `0` means deafault finality-only behavior.
- `> 0` enables Fast Transfers with that minimum depth.

## Step 3: Send Hello World Data Message from EOA

Run:

```bash
forge script script/examples/Example02.s.sol:Example02 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,uint32,uint16,address)" \
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  "Hello, World" \
  $GAS_LIMIT \
  $BLOCK_CONFIRMATIONS \
  $FEE_TOKEN
```

Parameter notes:

- `$GAS_LIMIT` must be `> 0` because the destination receiver callback needs gas.
- `$BLOCK_CONFIRMATIONS` must be `> 0` for Fast Transfers.
- `$BLOCK_CONFIRMATIONS` should be greater than or equal to `$MIN_BLOCK_DEPTH`.
- Executor may enforce a minimum block confirmations value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `$FEE_TOKEN`: native coin by default (`0x0000000000000000000000000000000000000000`). To pay CCIP fees in LINK instead, run `export FEE_TOKEN=$SEPOLIA_LINK`.

## Verify Result

`Example02` logs a CCIP message ID.

Use that ID in the CCIP Explorer:

- https://ccip.chain.link

You can inspect receiver state on destination chain:

```bash
cast call $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS "latestMessage()(bytes)" --rpc-url polygonAmoy
```
