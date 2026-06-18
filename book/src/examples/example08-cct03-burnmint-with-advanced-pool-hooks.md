# Example 08: CCT Burn and Mint With AdvancedPoolHooks

This example covers BurnMint CCT on Fuji -> Sepolia with `AdvancedPoolHooks` attached to the pool.

## Token Pool Hooks Development

Token pool hooks are standalone contracts used by token pools for additional checks and behavior.

At a high level:

- pool calls hook `preflightCheck(...)` on source-side lock/burn
- pool calls hook `postflightCheck(...)` on destination-side release/mint
- hook can enforce allowlists and CCV requirements
- hook can optionally call a policy engine

For custom development, the pool-level integration point is `IAdvancedPoolHooks` and the pool constructor receives
the hook address.

## Chainlink ACE Context

`AdvancedPoolHooks` includes optional policy engine integration through `IPolicyEngine`.
In this example, policy engine is intentionally disabled (`address(0)`) to focus on hook attachment and allowlist flow.

When building policy-engine-driven flows, Chainlink ACE provides the policy engine interfaces and implementation model.

This flow still demonstrates the correct hook wiring pattern for ACE-enabled setups.

## What This Example Covers

1. Deploy CrossChainToken + `AdvancedPoolHooks` + BurnMint pool on both chains.
2. Configure pools to trust each other.
3. Send token transfer with the existing ExtraArgsV3 default-finality sender.
4. Verify hook attachment and allowlist settings.

Scripts used:

- `script/examples/Example08.s.sol:DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook`
- `script/examples/Example08.s.sol:Example08`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality`

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

## Script Defaults

`DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook` deploys **CrossChainToken** with the same token defaults as Example 06 (`BaseERC20.ConstructorParams` + `registerAdminViaGetCCIPAdmin`):

- `name`: `TestToken`
- `symbol`: `TEST`
- `decimals`: `18`
- `preMint`: `1_000_000 * 1e18`
- `maxSupply`: `100_000_000 * 1e18`

Hook deployment defaults in this example:

- allowlist enabled and seeded with broadcaster EOA
- `thresholdAmountForAdditionalCCVs` is provided via CLI (use `1` in this tutorial)
- `policyEngine = address(0)` (disabled)
- hook is configured to authorize the deployed pool as caller

> **Important: Optimizer is required for CCT pool deployment**
>
> This repo includes a dedicated CCT profile in `foundry.toml`:
>
> ```toml
> [profile.cct]
> optimizer = true
> optimizer_runs = 200
> ```
>
> For this chapter, use `FOUNDRY_PROFILE=cct` in all commands.

## Step 1: Deploy Token + Hook + Pool on Fuji

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,address,address,uint256)" \
  <FUJI_TOKEN_ADMIN_REGISTRY> \
  <FUJI_REGISTRY_MODULE_OWNER_CUSTOM> \
  <FUJI_ARM_PROXY> \
  <FUJI_ROUTER> \
  1
```

Save from logs:

- `<FUJI_TOKEN_ADDRESS>`
- `<FUJI_ADVANCED_POOL_HOOK_ADDRESS>`
- `<FUJI_POOL_ADDRESS>`

## Step 2: Deploy Token + Hook + Pool on Sepolia

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,address,address,uint256)" \
  <SEPOLIA_TOKEN_ADMIN_REGISTRY> \
  <SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM> \
  <SEPOLIA_ARM_PROXY> \
  <SEPOLIA_ROUTER> \
  1
```

Save from logs:

- `<SEPOLIA_TOKEN_ADDRESS>`
- `<SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS>`
- `<SEPOLIA_POOL_ADDRESS>`

## Step 3: Configure Fuji Pool With Sepolia Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:Example08 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <FUJI_POOL_ADDRESS> \
  <SEPOLIA_CHAIN_SELECTOR> \
  <SEPOLIA_TOKEN_ADDRESS> \
  <SEPOLIA_POOL_ADDRESS>
```

## Step 4: Configure Sepolia Pool With Fuji Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:Example08 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <SEPOLIA_POOL_ADDRESS> \
  <FUJI_CHAIN_SELECTOR> \
  <FUJI_TOKEN_ADDRESS> \
  <FUJI_POOL_ADDRESS>
```

## Step 5: Send Transfer (Reuse Example06 Sender)

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,address)" \
  <FUJI_ROUTER> \
  <SEPOLIA_CHAIN_SELECTOR> \
  <RECEIVER_ON_SEPOLIA> \
  <FUJI_TOKEN_ADDRESS> \
  <AMOUNT> \
  0 \
  <FEE_TOKEN_ADDRESS>
```

## Optional: Update Hook Allowlist

Use this if you want to add or remove senders in the allowlist after deployment.

Add one sender address:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:Example08UpdateAllowlist \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address[],address[])" \
  <FUJI_ADVANCED_POOL_HOOK_ADDRESS> \
  "[]" \
  "[<ADDRESS_TO_ADD>]"
```

Remove one sender address:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example08.s.sol:Example08UpdateAllowlist \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address[],address[])" \
  <FUJI_ADVANCED_POOL_HOOK_ADDRESS> \
  "[<ADDRESS_TO_REMOVE>]" \
  "[]"
```

## Step 6: Verify Hook and Pool State

Verify token->pool registration:

```bash
cast call <FUJI_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <FUJI_TOKEN_ADDRESS> --rpc-url avalancheFuji
cast call <SEPOLIA_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <SEPOLIA_TOKEN_ADDRESS> --rpc-url ethereumSepolia
```

Verify attached hook on each pool:

```bash
cast call <FUJI_POOL_ADDRESS> "getAdvancedPoolHooks()(address)" --rpc-url avalancheFuji
cast call <SEPOLIA_POOL_ADDRESS> "getAdvancedPoolHooks()(address)" --rpc-url ethereumSepolia
```

Verify allowlist status:

```bash
cast call <FUJI_ADVANCED_POOL_HOOK_ADDRESS> "getAllowListEnabled()(bool)" --rpc-url avalancheFuji
cast call <FUJI_ADVANCED_POOL_HOOK_ADDRESS> "getAllowList()(address[])" --rpc-url avalancheFuji
cast call <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS> "getAllowListEnabled()(bool)" --rpc-url ethereumSepolia
cast call <SEPOLIA_ADVANCED_POOL_HOOK_ADDRESS> "getAllowList()(address[])" --rpc-url ethereumSepolia
```

Monitor message status with the message ID on:

- https://ccip.chain.link
