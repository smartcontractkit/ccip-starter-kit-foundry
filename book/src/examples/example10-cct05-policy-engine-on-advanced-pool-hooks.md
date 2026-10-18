# Example 10: Policy Engine on AdvancedPoolHooks

This example covers policy engine integration on `AdvancedPoolHooks`, continuing the setup from Example 08.

## Policy Engine

`AdvancedPoolHooks` optionally calls a policy engine on every transfer:

- on the source chain, the hook's `preflightCheck` calls `policyEngine.run(...)` before the pool locks or burns
- on the destination chain, the hook's `postflightCheck` calls `policyEngine.run(...)` before the pool releases or mints

The hook passes its own `preflightCheck`/`postflightCheck` calldata (minus the selector) as the payload, so the engine can decode the transfer details and enforce policies. If `run` reverts, the transfer is rejected: on the source side the send reverts, on the destination side the message execution fails and can be retried.

The engine is called locally on each chain, so the source and destination engines are independent instances — unlike pool-required CCVs, they do not need to share an address.

For production-grade policy engines, use Chainlink ACE (https://chainlink.tech/ace). This example attaches an existing engine by address and uses a minimal example engine (`src/ExamplePolicyEngine.sol`) that enforces a simple transfer-amount cap.

## What This Example Covers

1. Deploy CrossChainToken + `AdvancedPoolHooks` + BurnMint pool on both chains (Example 08 steps 1-4).
2. Deploy the minimal example policy engine.
3. Attach the engine to the hook.
4. Send a transfer within the cap (allowed) and above the cap (rejected).
5. Detach the engine.

Scripts used:

- `script/examples/Example08.s.sol:DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook` and `Example08` (setup, from Example 08)
- `script/examples/Example10.s.sol:Example10DeployExamplePolicyEngine`
- `script/examples/Example10.s.sol:Example10AttachPolicyEngine`
- `script/examples/Example10.s.sol:Example10DetachPolicyEngine`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality` (send)

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

## Step 1: Deploy Token + Hook + Pool on Both Chains

Follow Example 08 steps 1-4 to deploy the token, hook and pool on both chains and link the lanes. Save from the logs:

- `<SEPOLIA_TOKEN_ADDRESS>`, `<SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS>`, `<SEPOLIA_POOL_ADDRESS>`
- `<AMOY_TOKEN_ADDRESS>`, `<AMOY_ADVANCED_POOL_HOOK_ADDRESS>`, `<AMOY_POOL_ADDRESS>`

## Step 2: Deploy the Example Policy Engine on Sepolia

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10DeployExamplePolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast
```

Save from the logs:

- `<SEPOLIA_POLICY_ENGINE_ADDRESS>`

The example engine's default cap is `10 ether`. To use an existing ACE policy engine instead, skip this step and pass its address to Step 3.

## Step 3: Attach the Engine to the Sepolia Hook

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10AttachPolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address)" \
  <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS> \
  <SEPOLIA_POLICY_ENGINE_ADDRESS>
```

The hook calls the engine's `attach()`, which records the hook as an attached target.

## Step 4: Send a Transfer Within the Cap

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,address)" \
  <SEPOLIA_ROUTER> \
  <AMOY_CHAIN_SELECTOR> \
  <RECEIVER_ON_AMOY> \
  <SEPOLIA_TOKEN_ADDRESS> \
  1000000000000000000 \
  0 \
  <FEE_TOKEN_ADDRESS>
```

`1 ether` is within the `10 ether` cap, so the engine allows the transfer.

## Step 5: Send a Transfer Above the Cap

Send more than the cap (for example `11 ether`):

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,address)" \
  <SEPOLIA_ROUTER> \
  <AMOY_CHAIN_SELECTOR> \
  <RECEIVER_ON_AMOY> \
  <SEPOLIA_TOKEN_ADDRESS> \
  11000000000000000000 \
  0 \
  <FEE_TOKEN_ADDRESS>
```

The source-side `preflightCheck` calls the engine, which reverts with `AmountExceedsCap`, and the send reverts.

## Step 6: Detach the Engine

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10DetachPolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS>
```

The hook calls the engine's `detach()`. Transfers are no longer policy-checked.

## Optional: Destination-Side Engine

Attach an engine to the Amoy hook too (deploy a second engine on Amoy, then attach it to `<AMOY_ADVANCED_POOL_HOOK_ADDRESS>`). A destination-side rejection does not revert the send — the message is sent, but its execution on Amoy fails; check the message status on https://ccip.chain.link.

## Step 7: Verify Hook and Engine State

Verify the attached engine:

```bash
cast call <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS> "getPolicyEngine()(address)" --rpc-url ethereumSepolia
```

Verify the engine records the hook as attached:

```bash
cast call <SEPOLIA_POLICY_ENGINE_ADDRESS> "isAttached(address)(bool)" <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS> --rpc-url ethereumSepolia
```

Verify the cap:

```bash
cast call <SEPOLIA_POLICY_ENGINE_ADDRESS> "getCap()(uint256)" --rpc-url ethereumSepolia
```

Monitor message status with the message ID on:

- https://ccip.chain.link
