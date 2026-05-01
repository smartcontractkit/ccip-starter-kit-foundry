# Example 03: Programmable Token Transfer (Faster Than Finality)

This example sends a programmable token transfer from an EOA on Avalanche Fuji to a receiver that supports Faster Than Finality on Ethereum Sepolia:

- Data payload: `"Hello, World"`
- Tokens: `CCIP-BnM`

Script path: `script/examples/Example03.s.sol`

## What You Will Do

1. Ensure a destination `BasicMessageReceiverWithCCVs` exists on Sepolia.
2. Mint 1 `CCIP-BnM` on Fuji using `script/Faucet.s.sol`.
3. Send one CCIP message containing both data and tokens.

## Receiver Compatibility Note

This chapter uses Faster Than Finality (`blockConfirmations > 0`), so destination receiver should return a non-zero minimum block depth.

- If your receiver is default-finality-only, this message can fail on destination.
- Deploy `BasicMessageReceiverWithCCVs` before running this chapter.
- For default-finality programmable token transfer (`blockConfirmations = 0`), use Example04.

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

> **If you do not have a receiver deployed yet**
>
> Run:
>
> ```bash
> forge script script/examples/Example02.s.sol:DeployBasicMessageReceiverWithCCVs \
>   --rpc-url ethereumSepolia \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address)" \
>   <DESTINATION_ROUTER>
> ```
>
> Then configure min block depth for your source chain:
>
> ```bash
> forge script script/examples/Example02.s.sol:SetBasicMessageReceiverWithCCVsMinBlockDepth \
>   --rpc-url ethereumSepolia \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address,uint64,uint16)" \
>   <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> \
>   <SOURCE_CHAIN_SELECTOR> \
>   <MIN_BLOCK_DEPTH>
> ```
>
> For this chapter (which sends Faster Than Finality), use `<MIN_BLOCK_DEPTH> > 0`.
>
> The script argument accepts `<MIN_BLOCK_DEPTH>` (a `uint16` passed to `BasicMessageReceiverWithCCVs.setMinBlockDepth`). On-chain, the receiver does not return that integer directly to CCIP: `getCCVsAndFinalityConfig` sets `allowedFinalityConfig` to `FinalityCodec._encodeBlockDepth(minBlockDepth)` — the same `bytes4` finality encoding CCIP 2.0 uses elsewhere for allowed finality (depth `0` means wait for full/default finality).
>
> Save the receiver address from the `[RESULT]` log and use it in Step 2 below.

## Step 1: Get 1 CCIP-BnM Token on Fuji

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <CCIP_BNM_FUJI_ADDRESS>
```

## Step 2: Send Hello World + CCIP-BnM

```bash
forge script script/examples/Example03.s.sol:Example03 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,address,uint256,uint32,uint16,address)" \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> \
  "Hello, World" \
  <CCIP_BNM_FUJI_ADDRESS> \
  <AMOUNT> \
  <GAS_LIMIT> \
  <BLOCK_CONFIRMATIONS_GT_ZERO> \
  <FEE_TOKEN_ADDRESS>
```

Parameter notes:

- `<AMOUNT>` uses token decimals (`1e18` is 1 token for 18-decimal tokens).
- `<GAS_LIMIT>` must be `> 0` because the receiver contract callback handles data.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>` must be `> 0` for Faster Than Finality.
- `<BLOCK_CONFIRMATIONS_GT_ZERO>` should be greater than or equal to `<MIN_BLOCK_DEPTH>` (the depth you stored on the receiver; CCIP compares it against your message’s `requestedFinalityConfig` after both sides use `FinalityCodec` encoding).
- Executor may enforce a minimum block confirmation value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example03` logs a CCIP message ID. Track it in the CCIP Explorer:

- https://ccip.chain.link

Optional receiver checks on Sepolia:

```bash
cast call <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> "latestMessage()(bytes)" --rpc-url ethereumSepolia
cast call <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> "latestSender()(address)" --rpc-url ethereumSepolia
cast call <BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS> "latestSourceChainSelector()(uint64)" --rpc-url ethereumSepolia
```
