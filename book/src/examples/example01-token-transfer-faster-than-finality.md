# Example 01: Token Transfer + Fast Transfers (FTF)

This example sends one token transfer message using `ExtraArgsV3` with Fast Transfers (`blockConfirmations > 0`).

Script path: `script/examples/Example01.s.sol`

## What You Will Do

1. Mint 1 CCIP-BnM token to your EOA with `script/Faucet.s.sol`.
2. (Optional) Read the executor allowed finality config (`FinalityCodec` `bytes4`) on the source chain.
3. Send that token from source chain to destination chain with `script/examples/Example01.s.sol`.

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
export RECEIVER=$MY_EOA          # destination EOA
export AMOUNT=1000000000000000000  # 1 token (18 decimals)
export GAS_LIMIT=0               # token-only transfer to an EOA
export BLOCK_CONFIRMATIONS=1     # Fast Transfers depth, must be > 0
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $SEPOLIA_LINK to pay in LINK
```

## Step 1: Get 1 CCIP-BnM Token

Use the faucet script on the source chain:

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $SEPOLIA_CCIP_BNM
```

## Step 2: (Optional) Check Executor Allowed Finality

Before choosing a Fast Transfers depth in `ExtraArgsV3`, you can read what finality modes the **Executor** allows. The on-chain API is **`getAllowedFinalityConfig() → bytes4`**, encoded with **`FinalityCodec`** (same family of values as `requestedFinalityConfig` in your message’s ExtraArgs).

From a shell. The executor address is printed as `[GATE] Executor:` by the finality-gates check further down this step; run that first, then export it:

```bash
export EXECUTOR_ADDRESS=0x...
cast call $EXECUTOR_ADDRESS "getAllowedFinalityConfig()(bytes4)" --rpc-url ethereumSepolia
```

Why this matters:

- Your requested finality (derived from `blockConfirmations` in `EncodeExtraArgsOffchain` / `Example01` via **`FinalityCodec._encodeBlockDepth`**) must be **permitted** by the executor’s dynamic config; otherwise the send can revert.

Check the source pool, executor, and CCV finality settings before sending:

```bash
forge script script/examples/Example06.s.sol:Example06CheckFinalityGates \
  --rpc-url ethereumSepolia \
  --sig "run(address,uint64,address,uint16)" \
  $SEPOLIA_ROUTER $AMOY_CHAIN_SELECTOR $SEPOLIA_CCIP_BNM $BLOCK_CONFIRMATIONS
```

A quote alone does not prove `ccipSend` will succeed with a non-`IPoolV2` pool.

## Step 3: Send Token With Fast Transfers

Run `Example01`:

```bash
forge script script/examples/Example01.s.sol:Example01 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint32,uint16,address)" \
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $RECEIVER \
  $SEPOLIA_CCIP_BNM \
  $AMOUNT \
  $GAS_LIMIT \
  $BLOCK_CONFIRMATIONS \
  $FEE_TOKEN
```

Parameter notes:

- `$AMOUNT`: token amount in token decimals (for 18 decimals, `1e18` is 1 token).
- `$GAS_LIMIT`: set to `0` for token-only transfer to an EOA receiver.
- `$BLOCK_CONFIRMATIONS`: must be `> 0` and meet the source pool and executor minimums from Step 2.
- `$FEE_TOKEN`: native coin by default (`0x0000000000000000000000000000000000000000`). To pay CCIP fees in LINK instead, run `export FEE_TOKEN=$SEPOLIA_LINK`.

## Verify Result

`Example01` logs the message ID.

Use that ID in the CCIP Explorer to monitor status:

- https://ccip.chain.link
