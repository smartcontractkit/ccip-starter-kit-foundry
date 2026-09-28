# Example 06: CCT Burn and Mint

This example covers the full BurnMint CCT flow on Sepolia -> Amoy:

1. Deploy [`CrossChainToken`](https://github.com/smartcontractkit/chainlink-ccip/blob/develop/chains/evm/contracts/tokens/CrossChainToken.sol) + BurnMint pool on both chains.
2. Configure pools to trust each other.
3. Opt the pools into Fast Transfers (FTF) (this is what makes the token "FTF enabled").
4. Send a token transfer across the lane.
5. Verify BurnMint behavior (burn on source, mint on destination).

Scripts used:

- `script/examples/Example06.s.sol:DeployCCTBurnMintTokenAndPool`
- `script/examples/Example06.s.sol:Example06`
- `script/examples/Example06.s.sol:Example06SetPoolAllowedFinalityConfig`
- `script/examples/Example06.s.sol:Example06GetPoolAllowedFinalityConfig`
- `script/examples/Example06.s.sol:Example06CheckFinalityGates`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3CustomFinality`

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

`DeployCCTBurnMintTokenAndPool` deploys a **CrossChainToken** (via `BaseERC20.ConstructorParams`) with:

- `name`: `TestToken`
- `symbol`: `TEST`
- `decimals`: `18`
- `preMint`: `1_000_000 * 1e18`
- `maxSupply`: `100_000_000 * 1e18`
- `preMintRecipient`, `ccipAdmin`, burn/mint role admin, and AccessControl owner: the broadcasting EOA

Token admin registration uses `RegistryModuleOwnerCustom.registerAdminViaGetCCIPAdmin` (CrossChainToken exposes `getCCIPAdmin()` from `BaseERC20`, not `owner()`).

The deployment also uses:

- BurnMint pool (no advanced pool hook in this example)
- disabled rate limiter config in chain updates

> **Important: Optimizer is required for CCT pool deployment**
>
> `BurnMintTokenPool` can exceed EVM max code size if compiled without optimizer.
> This repo includes a dedicated CCT profile in `foundry.toml`:
>
> ```toml
> [profile.cct]
> optimizer = true
> optimizer_runs = 200
> ```
>
> For this chapter, use `FOUNDRY_PROFILE=cct` in all commands.

## Step 1: Deploy Token + Pool on Sepolia (source)

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:DeployCCTBurnMintTokenAndPool \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,address,address)" \
  <SEPOLIA_TOKEN_ADMIN_REGISTRY> \
  <SEPOLIA_REGISTRY_MODULE_OWNER_CUSTOM> \
  <SEPOLIA_ARM_PROXY> \
  <SEPOLIA_ROUTER>
```

Save from logs:

- `<SEPOLIA_TOKEN_ADDRESS>`
- `<SEPOLIA_POOL_ADDRESS>`

## Step 2: Deploy Token + Pool on Amoy (destination)

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:DeployCCTBurnMintTokenAndPool \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,address,address)" \
  <AMOY_TOKEN_ADMIN_REGISTRY> \
  <AMOY_REGISTRY_MODULE_OWNER_CUSTOM> \
  <AMOY_ARM_PROXY> \
  <AMOY_ROUTER>
```

Save from logs:

- `<AMOY_TOKEN_ADDRESS>`
- `<AMOY_POOL_ADDRESS>`

## Step 3: Configure Sepolia Pool With Amoy Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <SEPOLIA_POOL_ADDRESS> \
  <AMOY_CHAIN_SELECTOR> \
  <AMOY_TOKEN_ADDRESS> \
  <AMOY_POOL_ADDRESS>
```

## Step 4: Configure Amoy Pool With Sepolia Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06 \
  --rpc-url polygonAmoy \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <AMOY_POOL_ADDRESS> \
  <SEPOLIA_CHAIN_SELECTOR> \
  <SEPOLIA_TOKEN_ADDRESS> \
  <SEPOLIA_POOL_ADDRESS>
```

## Step 5: Enable Fast Transfers on Both Pools

New pools allow full finality only (`0x00000000`). FTF is a pool setting; configure both pools:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06SetPoolAllowedFinalityConfig \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,bytes4)" \
  <SEPOLIA_POOL_ADDRESS> \
  <ALLOWED_FINALITY_CONFIG>
```

Repeat on Amoy with `--rpc-url polygonAmoy` and `<AMOY_POOL_ADDRESS>`. Read back each pool:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06GetPoolAllowedFinalityConfig \
  --rpc-url ethereumSepolia \
  --sig "run(address)" \
  <SEPOLIA_POOL_ADDRESS>
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06GetPoolAllowedFinalityConfig \
  --rpc-url polygonAmoy \
  --sig "run(address)" \
  <AMOY_POOL_ADDRESS>
```

`0x00000000` disables FTF; values `0x00000001`–`0x0000ffff` set the minimum block depth. The staged wait-for-safe flag is not usable
on this lane.

## Step 6: Check Finality Gates

The read-only check reports the pool, executor, and CCV settings before an FTF send:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06CheckFinalityGates \
  --rpc-url ethereumSepolia \
  --sig "run(address,uint64,address,uint16)" \
  <SEPOLIA_ROUTER> \
  <AMOY_CHAIN_SELECTOR> \
  <SEPOLIA_TOKEN_ADDRESS> \
  <BLOCK_CONFIRMATIONS_GT_ZERO>
```

A `getFee` quote alone does not prove `ccipSend` will succeed for a non-`IPoolV2` pool.

## Step 7: Send BurnMint Transfer (ExtraArgsV3 + Default Finality)

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
  <AMOUNT> \
  <GAS_LIMIT> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<AMOUNT>` uses token decimals (`1e18` is 1 token for 18-decimal token).
- For token-only transfer to EOA receiver, use `<GAS_LIMIT>` = `0`.
- This sender uses `ExtraArgsV3` with `blockConfirmations = 0` (default finality).
- `<FEE_TOKEN_ADDRESS>`:
  - native fee: `0x0000000000000000000000000000000000000000`
  - LINK fee: LINK token address on Sepolia (the source chain)

For the FTF version, use the existing custom-finality sender after Steps 5 and 6:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3CustomFinality \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,uint16,address)" \
  <SEPOLIA_ROUTER> <AMOY_CHAIN_SELECTOR> <RECEIVER_ON_AMOY> \
  <SEPOLIA_TOKEN_ADDRESS> <AMOUNT> <GAS_LIMIT> <BLOCK_CONFIRMATIONS_GT_ZERO> <FEE_TOKEN_ADDRESS>
```

## Step 8: Verify BurnMint Behavior

Verify token->pool registration:

```bash
cast call <SEPOLIA_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <SEPOLIA_TOKEN_ADDRESS> --rpc-url ethereumSepolia
cast call <AMOY_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <AMOY_TOKEN_ADDRESS> --rpc-url polygonAmoy
```

Verify remote lane mapping:

```bash
cast call <SEPOLIA_POOL_ADDRESS> "getRemoteToken(uint64)(bytes)" <AMOY_CHAIN_SELECTOR> --rpc-url ethereumSepolia
cast call <SEPOLIA_POOL_ADDRESS> "getRemotePools(uint64)(bytes[])" <AMOY_CHAIN_SELECTOR> --rpc-url ethereumSepolia
cast call <AMOY_POOL_ADDRESS> "getRemoteToken(uint64)(bytes)" <SEPOLIA_CHAIN_SELECTOR> --rpc-url polygonAmoy
cast call <AMOY_POOL_ADDRESS> "getRemotePools(uint64)(bytes[])" <SEPOLIA_CHAIN_SELECTOR> --rpc-url polygonAmoy
```

Verify balances and supplies after transfer finalizes:

```bash
cast call <SEPOLIA_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <SOURCE_EOA_ADDRESS> --rpc-url ethereumSepolia
cast call <AMOY_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <RECEIVER_ON_AMOY> --rpc-url polygonAmoy
cast call <SEPOLIA_TOKEN_ADDRESS> "totalSupply()(uint256)" --rpc-url ethereumSepolia
cast call <AMOY_TOKEN_ADDRESS> "totalSupply()(uint256)" --rpc-url polygonAmoy
```

Monitor message status with the message ID on:

- https://ccip.chain.link
