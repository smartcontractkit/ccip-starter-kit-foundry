# Example 02: Hello World to BasicMessageReceiver (Faster Than Finality)

This example deploys a destination receiver contract and sends a Hello World data message to it from an EOA using Faster Than Finality (`blockConfirmations > 0`).

Scripts used:

- `script/examples/Example02.s.sol:DeployBasicMessageReceiver`
- `script/examples/Example02.s.sol:Example02`

## What You Will Do

1. Deploy `BasicMessageReceiver` on the destination chain.
2. Send a Hello World CCIP data message from source chain to the deployed receiver.

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

In v2.0, receivers expose CCV and finality requirements via `getCCVsAndMinBlockDepth`:

```ts
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IAny2EVMMessageReceiverV2 {
  function ccipReceive(
    Client.Any2EVMMessage calldata message
  ) external;

  function getCCVsAndMinBlockDepth(
    uint64 sourceChainSelector,
    bytes calldata sender
  )
    external
    view
    returns (
      address[] memory requiredCCVs,
      address[] memory optionalCCVs,
      uint8 optionalThreshold,
      uint16 minBlockDepth
    );
}
```

`minBlockDepth = 0` means finality is required. Any non-zero value allows Faster Than Finality messages with sufficient block depth.

In this starter kit:

- `src/BasicMessageReceiver.sol` is the baseline receiver flow used in this example.
- `src/BasicMessageReceiverWithCCVs.sol` extends it with configurable `getCCVsAndMinBlockDepth` behavior for Modular Trust Layer examples.

## Step 1: Deploy `BasicMessageReceiver` on Destination Chain

Run:

```bash
forge script script/examples/Example02.s.sol:DeployBasicMessageReceiver \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <DESTINATION_ROUTER>
```

Save the deployed receiver address from the `[RESULT]` log.

## Step 2: Send Hello World Data Message from EOA

Run:

```bash
forge script script/examples/Example02.s.sol:Example02 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,uint32,uint16,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> \
  "Hello, World" \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS_GT_ZERO> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<GAS_LIMIT>` must be `> 0` because the destination receiver contract callback needs gas.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>` must be `> 0` for Faster Than Finality.
- Executor may enforce a minimum block confirmations value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example02` logs a CCIP message ID.

Use that ID in the CCIP Explorer:

- https://ccip.chain.link

You can also inspect receiver state on destination chain:

```bash
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestMessage()(bytes)" --rpc-url ethereumSepolia
```

The stored bytes are the raw `abi.encode(string)` payload sent by this example.
