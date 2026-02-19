# Example 07: CCT Lock and Release

This example covers the full LockRelease CCT flow on Fuji -> Sepolia:

1. Deploy token + lock box + LockRelease pool on both chains.
2. Configure pools to trust each other.
3. Fund destination lock box liquidity.
4. Send a token transfer across the lane.
5. Verify lock/release behavior.

Scripts used:

- `script/examples/Example07.s.sol:DeployCCTLockReleaseTokenAndPool`
- `script/examples/Example07.s.sol:Example07`
- `script/examples/Example07.s.sol:FundCCTLockBoxLiquidity`
- `script/examples/Example06.s.sol:SendCCTTokenWithExtraArgsV3DefaultFinality` (reused for the final transfer step)

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

`DeployCCTLockReleaseTokenAndPool` deploys token with:

- `name`: `TestToken`
- `symbol`: `TEST`
- `decimals`: `18`
- `preMint`: `1_000_000 * 1e18`
- `maxSupply`: `100_000_000 * 1e18`

The deployment also uses:

- LockRelease pool
- `ERC20LockBox` bound to the local token
- disabled rate limiter config in chain updates

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

## Step 1: Deploy Token + Lock Box + Pool on Fuji

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example07.s.sol:DeployCCTLockReleaseTokenAndPool \
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
- `<FUJI_LOCKBOX_ADDRESS>`
- `<FUJI_POOL_ADDRESS>`

## Step 2: Deploy Token + Lock Box + Pool on Sepolia

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example07.s.sol:DeployCCTLockReleaseTokenAndPool \
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
- `<SEPOLIA_LOCKBOX_ADDRESS>`
- `<SEPOLIA_POOL_ADDRESS>`

## Step 3: Configure Fuji Pool With Sepolia Remote

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example07.s.sol:Example07 \
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
FOUNDRY_PROFILE=cct forge script script/examples/Example07.s.sol:Example07 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address)" \
  <SEPOLIA_POOL_ADDRESS> \
  <FUJI_CHAIN_SELECTOR> \
  <FUJI_TOKEN_ADDRESS> \
  <FUJI_POOL_ADDRESS>
```

## Step 5: Fund Destination Lock Box Liquidity

For Fuji -> Sepolia transfers, fund the Sepolia lock box first:

```bash
FOUNDRY_PROFILE=cct forge script script/examples/Example07.s.sol:FundCCTLockBoxLiquidity \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,uint256)" \
  <SEPOLIA_TOKEN_ADDRESS> \
  <SEPOLIA_LOCKBOX_ADDRESS> \
  <LIQUIDITY_AMOUNT>
```

If you also want Sepolia -> Fuji transfers, fund Fuji lock box too with the same script.

## Step 6: Send LockRelease Transfer (Reuse Example06 CCT Sender)

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

Parameter notes:

- `<AMOUNT>` uses token decimals (`1e18` is 1 token for 18-decimal token).
- `gasLimit` is set to `0` in this command because this is token-only transfer to an EOA receiver.
- This sender uses `ExtraArgsV3` with `blockConfirmations = 0` (default finality).
- `<FEE_TOKEN_ADDRESS>`:
  - native fee: `0x0000000000000000000000000000000000000000`
  - LINK fee: LINK token address on Fuji

## Step 7: Verify LockRelease Behavior

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

Verify lock box balances and receiver balance after transfer finalizes:

```bash
cast call <FUJI_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <FUJI_LOCKBOX_ADDRESS> --rpc-url avalancheFuji
cast call <SEPOLIA_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <SEPOLIA_LOCKBOX_ADDRESS> --rpc-url ethereumSepolia
cast call <SEPOLIA_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <RECEIVER_ON_SEPOLIA> --rpc-url ethereumSepolia
```

Monitor message status with the message ID on:

- https://ccip.chain.link
