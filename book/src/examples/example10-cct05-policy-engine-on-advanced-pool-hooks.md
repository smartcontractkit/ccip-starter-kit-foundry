# Example 10: Policy Engine on AdvancedPoolHooks

This example covers policy engine integration on `AdvancedPoolHooks`, continuing the setup from Example 08.

## Policy Engine

`AdvancedPoolHooks` optionally calls a policy engine on every transfer:

- on the source chain, the hook's `preflightCheck` calls `policyEngine.run(...)` before the pool locks or burns
- on the destination chain, the hook's `postflightCheck` calls `policyEngine.run(...)` before the pool releases or mints

The hook passes its own `preflightCheck`/`postflightCheck` calldata (minus the selector) as the payload, so the engine can decode the transfer details and enforce policies. If `run` reverts, the transfer is rejected: on the source side the send reverts, on the destination side the message execution fails and can be retried.

The engine is called locally on each chain, so the source and destination engines are independent instances — unlike pool-required CCVs, they do not need to share an address.

For production-grade policy engines, use [Chainlink ACE](https://docs.chain.link/ace). This example attaches an existing engine by address and uses a minimal example engine (`src/ExamplePolicyEngine.sol`) that enforces a simple transfer-amount cap. To use a real ACE policy engine instead of the example engine, see [Use a real ACE policy engine](#use-a-real-ace-policy-engine) below.

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

## Chapter Parameters

Set the parameters for this chapter. The defaults work as they are; change a value only if you want something different.

```bash
export RECEIVER=$MY_EOA          # destination EOA on Amoy
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $SEPOLIA_LINK to pay in LINK
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

## Step 2: Deploy the Example Policy Engine on Sepolia

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10DeployExamplePolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast
```

Copy the engine address from the logs and export it:

```bash
export SEPOLIA_POLICY_ENGINE_ADDRESS=0x...
```

The example engine's default cap is `10 ether`, and only its owner (the deploying account) can change it with `setCap`. To use a real ACE policy engine instead, skip this step and follow [Use a real ACE policy engine](#use-a-real-ace-policy-engine) below, then pass the ACE engine's onchain address to Step 3.

## Step 3: Attach the Engine to the Sepolia Hook

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10AttachPolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address)" \
  $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS \
  $SEPOLIA_POLICY_ENGINE_ADDRESS
```

The hook calls the engine's `attach()`, which records the hook as an attached target.

## Step 4: Send a Transfer Within the Cap

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
  1000000000000000000 \
  0 \
  $FEE_TOKEN
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
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $RECEIVER \
  $SEPOLIA_TOKEN_ADDRESS \
  11000000000000000000 \
  0 \
  $FEE_TOKEN
```

The source-side `preflightCheck` calls the engine, which reverts with `AmountExceedsCap`, and the send reverts.

## Step 6: Detach the Engine

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example10.s.sol:Example10DetachPolicyEngine \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS
```

The hook calls the engine's `detach()`. Transfers are no longer policy-checked.

## Optional: Destination-Side Engine

Attach an engine to the Amoy hook too (deploy a second engine on Amoy, then attach it to `$AMOY_ADVANCED_POOL_HOOK_ADDRESS`). A destination-side rejection does not revert the send — the message is sent, but its execution on Amoy fails; check the message status on https://ccip.chain.link.

## Use a real ACE policy engine

The example engine exists so this chapter runs without any Platform setup. For real policy enforcement, use Chainlink ACE: it provides managed policy engines, a built-in `CCIP-AdvancedPoolHooks` contract type with a pre-built extractor for the hook calldata, and policies you configure in the [Chainlink Platform](https://app.chain.link). You need an ACE-enabled organization on the Platform and a completed [ACE account setup](https://docs.chain.link/ace/getting-started/account-setup) first. The flow below summarizes the [Protect CCIP Token Pools with ACE](https://docs.chain.link/ace/guides/policy-manager/ccip-token-pools) guide, which has the complete Platform walkthrough.

1. **Create a policy engine** in the Platform's Policy Manager, including every EVM chain where you want to enforce policies (see [Create a policy engine](https://docs.chain.link/ace/guides/policy-manager/manage-engines)). Wait until the engine is **Active**, then copy its onchain address for each chain.
2. **Attach the hook to the engine** with Step 3 above, passing the ACE engine's onchain address for that chain. The hook's `attach()` call is detected on-chain by ACE, which automatically adds the hook as a target under the engine. Do not register the hook manually as a second target.
3. **Verify the detected target**: in the Platform, open the engine's **Contracts** tab, find the target matching your hook's address, and assign it the built-in `CCIP-AdvancedPoolHooks` contract type. It ships with `preflightCheck` and `postflightCheck` and their pre-built extractor, so no custom contract type or extractor is needed.
4. **Create a policy instance and protect a hook function**: create the policy under the same engine and chain as the hook function you want to protect, then create a target protection selecting `preflightCheck` (source-side) or `postflightCheck` (destination-side), mapping policy parameters to the extractor's outputs (for example `from`, `to`, `amount_post_fee`).

One mapping gotcha from the ACE guide: the hook sets the payload sender to `msg.sender`, which is the Token Pool, not the user who initiated the transfer. To evaluate the user, map the extracted `from` output to the policy parameter.

## Step 7: Verify Hook and Engine State

Verify the attached engine:

```bash
cast call $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS "getPolicyEngine()(address)" --rpc-url ethereumSepolia
```

Verify the engine records the hook as attached:

```bash
cast call $SEPOLIA_POLICY_ENGINE_ADDRESS "isAttached(address)(bool)" $SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS --rpc-url ethereumSepolia
```

Verify the cap:

```bash
cast call $SEPOLIA_POLICY_ENGINE_ADDRESS "getCap()(uint256)" --rpc-url ethereumSepolia
```

Monitor message status with the message ID on:

- https://ccip.chain.link
