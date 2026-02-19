# Example 06: CCT Burn and Mint

This example covers the full BurnMint CCT flow on Fuji -> Sepolia:

1. Deploy BurnMint token + BurnMint pool on both chains.
2. Configure pools to trust each other.
3. Send a token transfer across the lane.
4. Verify BurnMint behavior (burn on source, mint on destination).

Scripts used:

- `script/examples/Example06.s.sol:DeployCCTBurnMintTokenAndPool`
- `script/examples/Example06.s.sol:Example06`
- `script/examples/Example01.s.sol:Example01` (reused for the final transfer step)

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

`DeployCCTBurnMintTokenAndPool` deploys token with:

- `name`: `TestToken`
- `symbol`: `TEST`
- `decimals`: `18`
- `preMint`: `1_000_000 * 1e18`
- `maxSupply`: `100_000_000 * 1e18`

The deployment also uses:

- BurnMint pool (no advanced pool hook in this example)
- disabled rate limiter config in chain updates

> **Important: Optimizer is required for CCT pool deployment**
>
> `BurnMintTokenPool` can exceed EVM max code size if compiled without optimizer.
> This repo includes a dedicated CCT profile in `foundry.toml`:
>
> - `[profile.cct]`
> - `optimizer = true`
> - `optimizer_runs = 200`
>
> For this chapter, use `FOUNDRY_PROFILE=cct` in all commands.

## Step 1: Deploy Token + Pool on Fuji

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:DeployCCTBurnMintTokenAndPool \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,address,address)" \
  <FUJI_TOKEN_ADMIN_REGISTRY> \
  <FUJI_REGISTRY_MODULE_OWNER_CUSTOM> \
  <FUJI_ARM_PROXY> \
  <FUJI_ROUTER>
```

Save from logs:

- `<FUJI_TOKEN_ADDRESS>`
- `<FUJI_POOL_ADDRESS>`

## Step 2: Deploy Token + Pool on Sepolia

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

## Step 3: Configure Fuji Pool With Sepolia Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06 \
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
FOUNDRY_PROFILE=cct forge script script/examples/Example06.s.sol:Example06 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <SEPOLIA_POOL_ADDRESS> \
  <FUJI_CHAIN_SELECTOR> \
  <FUJI_TOKEN_ADDRESS> \
  <FUJI_POOL_ADDRESS>
```

## Step 5: Send BurnMint Transfer (Reuse Example01)

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example01.s.sol:Example01 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,uint16,address)" \
  <FUJI_ROUTER> \
  <SEPOLIA_CHAIN_SELECTOR> \
  <RECEIVER_ON_SEPOLIA> \
  <FUJI_TOKEN_ADDRESS> \
  <AMOUNT> \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS_GT_ZERO> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<AMOUNT>` uses token decimals (`1e18` is 1 token for 18-decimal token).
- For token-only transfer to EOA receiver, use `<GAS_LIMIT>` = `0`.
- `Example01` is the Faster Than Finality sender script, so `<BLOCK_CONFIRMATIONS_GT_ZERO>` must be `> 0`.
- `<FEE_TOKEN_ADDRESS>`:
  - native fee: `0x0000000000000000000000000000000000000000`
  - LINK fee: LINK token address on Fuji

## Step 6: Verify BurnMint Behavior

Verify token->pool registration:

```bash
cast call <FUJI_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <FUJI_TOKEN_ADDRESS> --rpc-url avalancheFuji
cast call <SEPOLIA_TOKEN_ADMIN_REGISTRY> "getPool(address)(address)" <SEPOLIA_TOKEN_ADDRESS> --rpc-url ethereumSepolia
```

Verify remote lane mapping:

```bash
cast call <FUJI_POOL_ADDRESS> "getRemoteToken(uint64)(bytes)" <SEPOLIA_CHAIN_SELECTOR> --rpc-url avalancheFuji
cast call <FUJI_POOL_ADDRESS> "getRemotePools(uint64)(bytes[])" <SEPOLIA_CHAIN_SELECTOR> --rpc-url avalancheFuji
cast call <SEPOLIA_POOL_ADDRESS> "getRemoteToken(uint64)(bytes)" <FUJI_CHAIN_SELECTOR> --rpc-url ethereumSepolia
cast call <SEPOLIA_POOL_ADDRESS> "getRemotePools(uint64)(bytes[])" <FUJI_CHAIN_SELECTOR> --rpc-url ethereumSepolia
```

Verify balances and supplies after transfer finalizes:

```bash
cast call <FUJI_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <SOURCE_EOA_ADDRESS> --rpc-url avalancheFuji
cast call <SEPOLIA_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <RECEIVER_ON_SEPOLIA> --rpc-url ethereumSepolia
cast call <FUJI_TOKEN_ADDRESS> "totalSupply()(uint256)" --rpc-url avalancheFuji
cast call <SEPOLIA_TOKEN_ADDRESS> "totalSupply()(uint256)" --rpc-url ethereumSepolia
```

Monitor message status with the message ID on:

- https://ccip.chain.link
