# Legacy 01: ExtraArgsV1 Token Transfer

This example sends a token transfer using `ExtraArgsV1` from an EOA.

Script path: `script/examples/Legacy01.s.sol`

## What You Will Do

1. Mint test token(s) to your EOA on the source chain.
2. Send token(s) using `ExtraArgsV1`.
3. Observe the message on CCIP Explorer.

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

## Step 1: Get 1 CCIP-BnM Token on Source Chain

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <CCIP_BNM_SOURCE_TOKEN_ADDRESS>
```

## Step 2: Send Token With ExtraArgsV1

```bash
forge script script/examples/Legacy01.s.sol:Legacy01 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,address,uint256,uint256,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <DESTINATION_EOA_ADDRESS> \
  <CCIP_BNM_SOURCE_TOKEN_ADDRESS> \
  <AMOUNT> \
  <GAS_LIMIT> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<AMOUNT>`: token amount in token decimals (for 18 decimals, `1e18` is 1 token).
- `<GAS_LIMIT>`: set `0` for token-only transfer to an EOA receiver. Use `> 0` for contract callback.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

Use the logged message ID in:

- https://ccip.chain.link
