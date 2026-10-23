# Example 09: Pool-Based CCV Requirements on AdvancedPoolHooks

This example covers pool-based CCV (Cross-Chain Verifier) requirements on `AdvancedPoolHooks`, continuing the setup from Example 08.

## Pool-Based CCVs

A token pool can require specific CCVs for its transfers. When a pool requires CCVs:

- the source OnRamp consults the pool's `getRequiredCCVs(...)` outbound and calls each CCV's `getOutboundImplementation` and `forwardToVerifier` on the source chain
- the destination OffRamp resolves the same CCV addresses on the destination chain and calls `getInboundImplementation` and `verifyMessage` before releasing or minting tokens

Because the destination OffRamp resolves the same address, **a pool-required CCV must exist at the same address on both chains**. Real CCVs are CREATE2-deployed to matching addresses on each chain.

`AdvancedPoolHooks` exposes this through per-remote-chain CCV configs:

- `outboundCCVs` / `inboundCCVs`: base CCVs, always required for transfers to/from that chain
- `thresholdOutboundCCVs` / `thresholdInboundCCVs`: additional CCVs, required only when the transfer amount is at or above `thresholdAmountForAdditionalCCVs`
- `address(0)` in a base list means "use the lane defaults alongside the other listed CCVs"

Threshold CCV lists require non-empty base lists (use `address(0)` in the base list if you want defaults below the threshold). Duplicates within and across lists are rejected.

## What This Example Covers

1. Deploy CrossChainToken + `AdvancedPoolHooks` + BurnMint pool on both chains (Example 08 steps 1-4).
2. Set pool CCV configs on both hooks.
3. Send a token transfer and observe the CCV being consulted on both sides.
4. Adjust the threshold amount and observe threshold CCVs becoming required.
5. Clear the CCV config.

Scripts used:

- `script/examples/Example08.s.sol:DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook` and `Example08` (setup, from Example 08)
- `script/examples/Example09.s.sol:Example09SetPoolCCVConfig`
- `script/examples/Example09.s.sol:Example09SetThresholdAmount`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality` (send)

> **Note on real CCVs**
>
> This starter kit does not deploy a real CCV. To try pool-based CCVs end to end on the live testnets, deploy your own CCV with the [CCV starter kit](https://docs.chain.link/ccip/ccv-starter-kit) and use its resolver address as `$CCV_ADDRESS` below. The short version:
>
> 1. **On-chain contracts, on both chains** — use the [on-chain contracts kit](https://github.com/smartcontractkit/chainlink-ccv-starter-kit-contracts) to deploy the CREATE2 factory, the `VersionedVerifierResolver`, and the committee verifier, then apply the lane and signature config. The kit's [full flow](https://github.com/smartcontractkit/chainlink-ccv-starter-kit-contracts/blob/main/docs/src/full-flow.md) walks the exact `make` commands; the resolver lands at the same address on both chains by construction (`make deployments-check` asserts the parity).
> 2. **Off-chain cell** — use the [off-chain kit](https://github.com/smartcontractkit/chainlink-ccv-starter-kit) to run the verifier and aggregator that actually attest messages (a Helm chart in Kubernetes, or the [local docker-compose stack](https://github.com/smartcontractkit/chainlink-ccv-starter-kit/tree/main/local) for testing). Without a running cell, the CCV exists on-chain but never attests, so messages requiring it will not execute.
>
> Use the **resolver** address (not the committee verifier implementation) as `$CCV_ADDRESS`: a pool that lists the implementation address reverts during the fee quote.

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

Set the parameters for this chapter. Everything except `CCV_ADDRESS` has a working default.

```bash
export RECEIVER=$MY_EOA          # destination EOA on Amoy
export AMOUNT=1000000000000000000  # 1 token (18 decimals)
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $SEPOLIA_LINK to pay in LINK
export CCV_ADDRESS=0x...            # your CCV resolver address, the same on both chains (see the note above)
```

## Step 1: Deploy Token + Hook + Pool on Both Chains

Follow Example 08 steps 1-4 to deploy the token, hook and pool on both chains and link the lanes. If you ran them in this terminal, these variables are already exported. Otherwise copy them from the logs:

```bash
export SEPOLIA_TOKEN_ADDRESS=0x...
export SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS=0x...
export SEPOLIA_POOL_ADDRESS=0x...
export AMOY_TOKEN_ADDRESS=0x...
export AMOY_ADVANCED_POOL_HOOK_ADDRESS=0x...
export AMOY_POOL_ADDRESS=0x...
```

## Step 2: Set Pool CCV Config on Sepolia

Require `$CCV_ADDRESS` for both outbound and inbound traffic to Amoy:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example09.s.sol:Example09SetPoolCCVConfig \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address[],address[],address[],address[])" \
  $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS \
  $AMOY_CHAIN_SELECTOR \
  "[$CCV_ADDRESS]" \
  "[]" \
  "[$CCV_ADDRESS]" \
  "[]"
```

## Step 3: Set Pool CCV Config on Amoy

Require the same `$CCV_ADDRESS` for traffic to Sepolia:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example09.s.sol:Example09SetPoolCCVConfig \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address[],address[],address[],address[])" \
  $AMOY_ADVANCED_POOL_HOOK_ADDRESS \
  $SEPOLIA_CHAIN_SELECTOR \
  "[$CCV_ADDRESS]" \
  "[]" \
  "[$CCV_ADDRESS]" \
  "[]"
```

## Step 4: Send Transfer (Reuse Example06 Sender)

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,address)" \
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $RECEIVER \
  $SEPOLIA_TOKEN_ADDRESS \
  $AMOUNT \
  0 \
  $FEE_TOKEN
```

The source OnRamp now consults `$CCV_ADDRESS` outbound, and the destination OffRamp verifies the message with the same address before minting.

> **Note on execution with a self-run CCV**
>
> Until your CCV is onboarded into the CCIP indexer, the default executor cannot fetch its attestation, so the message sits at `UNTOUCHED` after it is sent. Execute it yourself with the [CCIP CLI](https://docs.chain.link/ccip/tools/cli/) (1.14.0 or later), reading the attestation directly from your own aggregator:
>
> ```bash
> export SOURCE_TX_HASH=0x...   # transaction hash of your send
> ccip-cli manual-exec $SOURCE_TX_HASH --verifiers grpcs://<YOUR_AGGREGATOR_HOST>:443
> ```
>
> See [Test your setup](https://docs.chain.link/ccip/ccv-starter-kit/evm/test-your-setup) in the CCV starter kit docs for the full walkthrough.

## Step 5: Adjust the Threshold Amount

Threshold CCVs are required only for transfers at or above `thresholdAmountForAdditionalCCVs`. Example 08 deployed the hook with threshold `1`, so threshold CCVs are effectively always required. Raise the threshold so they apply only to large transfers:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example09.s.sol:Example09SetThresholdAmount \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint256)" \
  $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS \
  10000000000000000000000
```

Repeat on Amoy for the inbound side:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example09.s.sol:Example09SetThresholdAmount \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint256)" \
  $AMOY_ADVANCED_POOL_HOOK_ADDRESS \
  10000000000000000000000
```

To use threshold CCVs, set a config with non-empty threshold lists, for example base `[$CCV_ADDRESS]` and threshold `[$SECOND_CCV_ADDRESS]` (`export SECOND_CCV_ADDRESS=0x...` first) (duplicates across lists are rejected).

## Step 6: Clear the CCV Config

Re-run `Example09SetPoolCCVConfig` with empty lists to remove the config for that lane:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example09.s.sol:Example09SetPoolCCVConfig \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address[],address[],address[],address[])" \
  $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS \
  $AMOY_CHAIN_SELECTOR \
  "[]" \
  "[]" \
  "[]" \
  "[]"
```

## Step 7: Verify Hook State

Verify the stored CCV config:

```bash
cast call $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS "getCCVConfig(uint64)((address[],address[],address[],address[]))" $AMOY_CHAIN_SELECTOR --rpc-url ethereumSepolia
cast call $AMOY_ADVANCED_POOL_HOOK_ADDRESS "getCCVConfig(uint64)((address[],address[],address[],address[]))" $SEPOLIA_CHAIN_SELECTOR --rpc-url polygonAmoy
```

Verify the threshold amount:

```bash
cast call $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS "getThresholdAmount()(uint256)" --rpc-url ethereumSepolia
cast call $AMOY_ADVANCED_POOL_HOOK_ADDRESS "getThresholdAmount()(uint256)" --rpc-url polygonAmoy
```

Monitor message status with the message ID on:

- https://ccip.chain.link
