# Legacy 02: ExtraArgsV2 Token Transfer (CLI `allowOutOfOrderExecution`)

This example sends a token transfer using `ExtraArgsV2` from an EOA.

Script path: `script/examples/Legacy02.s.sol`

You can toggle `allowOutOfOrderExecution` via CLI arg to cover both scenarios in one script.

## What You Will Do

1. Mint test token(s) to your EOA on the source chain.
2. Send token(s) using `ExtraArgsV2`.
3. Toggle out-of-order execution with a boolean CLI value.
4. Observe the message on CCIP Explorer.

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

You do not need to deploy a receiver contract for this token-only example.
Use a destination EOA as the receiver and pass `GAS_LIMIT = 0`.

## Chapter Parameters

Set the parameters for this chapter. The defaults work as they are; change a value only if you want something different.

```bash
export RECEIVER=$MY_EOA          # destination EOA (Fuji -> Sepolia lane)
export AMOUNT=1000000000000000000  # 1 token (18 decimals)
export GAS_LIMIT=0               # token-only transfer to an EOA
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $FUJI_LINK to pay in LINK
export ALLOW_OUT_OF_ORDER_EXECUTION=true
```

## Step 1: Get 1 CCIP-BnM Token on Source Chain

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $FUJI_CCIP_BNM
```

## Step 2: Send Token With ExtraArgsV2

```bash
forge script script/examples/Legacy02.s.sol:Legacy02 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint256,bool,address)" \
  $FUJI_ROUTER \
  $SEPOLIA_CHAIN_SELECTOR \
  $RECEIVER \
  $FUJI_CCIP_BNM \
  $AMOUNT \
  $GAS_LIMIT \
  $ALLOW_OUT_OF_ORDER_EXECUTION \
  $FEE_TOKEN
```

Parameter notes:

- `$AMOUNT`: token amount in token decimals (for 18 decimals, `1e18` is 1 token).
- `$GAS_LIMIT`: set `0` for token-only transfer to an EOA receiver. Use `> 0` for contract callback.
- `$ALLOW_OUT_OF_ORDER_EXECUTION`: `true` or `false`.
- `$FEE_TOKEN`: native coin by default (`0x0000000000000000000000000000000000000000`). To pay CCIP fees in LINK instead, run `export FEE_TOKEN=$FUJI_LINK`.

## Verify Result

Use the logged message ID in:

- https://ccip.chain.link
