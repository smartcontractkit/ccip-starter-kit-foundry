# Example 05: ExtraArgsV3 No-Execution-Tag (Manual Execution Path)

This example sends a Hello World data message from an EOA, but disables automatic execution by setting `executor` to `NO_EXECUTION_ADDRESS` inside `ExtraArgsV3`.

Script path: `script/examples/Example05.s.sol`

## What You Will Do

1. Ensure destination `BasicMessageReceiver` exists.
2. Send a CCIP data message with `ExtraArgsV3` no-execution-tag.
3. Observe pending execution in CCIP Explorer and execute manually.

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

> **If you do not have a receiver deployed yet**
>
> Run:
>
> ```bash
> forge script script/examples/Example02.s.sol:DeployBasicMessageReceiver \
>   --rpc-url ethereumSepolia \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address)" \
>   <DESTINATION_ROUTER>
> ```
>
> Save the receiver address from the `[RESULT]` log.

## Understanding ExtraArgsV3

The `ExtraArgsV3` is a structured set of delivery/execution options encoded and attached to a CCIP message.

```c++
struct GenericExtraArgsV3 {
    uint32 gasLimit;
    uint16 blockConfirmations;
    address[] ccvs;
    bytes[] ccvArgs;
    address executor;
    bytes executorArgs;
    bytes tokenReceiver;
    bytes tokenArgs;
}
```

- `gasLimit`: gas allocated for callback execution on destination. If `0` and message data is empty, no callback executes.
- `blockConfirmations`: confirmation depth before execution. `0` means default finality for the lane.
- `ccvs`: list of cross-chain verifier addresses. Empty means default verifiers.
- `ccvArgs`: optional arguments for each CCV. Must match `ccvs` length.
- `executor`: executor address on source chain. `address(0)` uses default executor.
- `executorArgs`: chain/executor-specific args (format depends on chain family/executor implementation).
- `tokenReceiver`: encoded destination token receiver. If empty, receiver address is used.
- `tokenArgs`: extra token transfer args (pool-specific format).

Related helpers in `script/EncodeExtraArgsOffchain.s.sol`:

- `encodeV3Basic(gasLimit, blockConfirmations)` for a minimal V3 payload.
- `getNoExecutionAddress()` returns `Client.NO_EXECUTION_ADDRESS` for manual execution path.

## Step 1: Send Message With No-Execution-Tag

```bash
forge script script/examples/Example05.s.sol:Example05 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,uint32,uint16,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> \
  "Hello, World" \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<GAS_LIMIT>` must be `> 0` because the receiver callback needs gas.
- `<BLOCK_CONFIRMATIONS>` can be `0` (default finality) or `> 0`.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`
- This example sets executor to `NO_EXECUTION_ADDRESS`, so execution is not automatic.

## Verify Result

`Example05` logs a CCIP message ID.

Use that ID in CCIP Explorer:

- https://ccip.chain.link

Expected behavior:

- Message is delivered to a pending/manual execution state because automatic execution is disabled.

![ccip-explorer]()
