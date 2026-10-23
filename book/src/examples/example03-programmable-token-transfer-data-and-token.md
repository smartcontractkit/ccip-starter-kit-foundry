# Example 03: Programmable Token Transfer with Fast Transfers (FTF)

This example sends a programmable token transfer from an EOA on Ethereum Sepolia to a receiver that supports Fast Transfers on Polygon Amoy:

- Data payload: `"Hello, World"`
- Tokens: `CCIP-BnM`

Script path: `script/examples/Example03.s.sol`

## What You Will Do

1. Ensure a destination `BasicMessageReceiverWithCCVs` exists on Amoy.
2. Mint 1 `CCIP-BnM` on Sepolia using `script/Faucet.s.sol`.
3. Send one CCIP message containing both data and tokens.

## Receiver Compatibility Note

This chapter uses Fast Transfers (`blockConfirmations > 0`), so destination receiver should return a non-zero minimum block depth.

- If your receiver is default-finality-only, this message can fail on destination.
- Deploy `BasicMessageReceiverWithCCVs` before running this chapter.
- For default-finality programmable token transfer (`blockConfirmations = 0`), use Example04.

## Chapter Parameters

Set the parameters for this chapter. The defaults work as they are; change a value only if you want something different.

```bash
export AMOUNT=1000000000000000000  # 1 token (18 decimals)
export GAS_LIMIT=200000          # the receiver callback handles data
export BLOCK_CONFIRMATIONS=1     # Fast Transfers depth, must be > 0
export MIN_BLOCK_DEPTH=1         # receiver minimum, must be <= BLOCK_CONFIRMATIONS
export FEE_TOKEN=0x0000000000000000000000000000000000000000  # native fee; use $SEPOLIA_LINK to pay in LINK
```

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
>   --rpc-url polygonAmoy \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address)" \
>   $AMOY_ROUTER
> ```
>
> Then configure min block depth for your source chain:
>
> ```bash
> forge script script/examples/Example02.s.sol:SetBasicMessageReceiverWithCCVsMinBlockDepth \
>   --rpc-url polygonAmoy \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address,uint64,uint16)" \
>   $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
>   $SEPOLIA_CHAIN_SELECTOR \
>   $MIN_BLOCK_DEPTH
> ```
>
> For this Fast Transfers example, `MIN_BLOCK_DEPTH` must be `> 0` (the default is `1`). Check the source pool minimum too.
>
> The script argument accepts `$MIN_BLOCK_DEPTH` (a `uint16` passed to `BasicMessageReceiverWithCCVs.setMinBlockDepth`). On-chain, the receiver does not return that integer directly to CCIP: `getCCVsAndFinalityConfig` sets `allowedFinalityConfig` to `FinalityCodec._encodeBlockDepth(minBlockDepth)` — the same `bytes4` finality encoding CCIP 2.0 uses elsewhere for allowed finality (depth `0` means wait for full/default finality).
>
> Copy the receiver address from the `[RESULT]` log and export it for Step 2 below:
>
> ```bash
> export BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS=0x...
> ```

## Step 1: Get 1 CCIP-BnM Token on Sepolia

Use the token and finality check from [Example 01](example01-token-transfer-faster-than-finality.md):

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $SEPOLIA_CCIP_BNM
```

## Step 2: Send Hello World + CCIP-BnM

```bash
forge script script/examples/Example03.s.sol:Example03 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,uint64,address,string,address,uint256,uint32,uint16,address)" \
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS \
  "Hello, World" \
  $SEPOLIA_CCIP_BNM \
  $AMOUNT \
  $GAS_LIMIT \
  $BLOCK_CONFIRMATIONS \
  $FEE_TOKEN
```

Parameter notes:

- `$AMOUNT` uses token decimals (`1e18` is 1 token for 18-decimal tokens).
- `$GAS_LIMIT` must be `> 0` because the receiver contract callback handles data.
- `$BLOCK_CONFIRMATIONS` must meet the source pool and receiver minimums.
- Executor may enforce a minimum block confirmation value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `$FEE_TOKEN`: native coin by default (`0x0000000000000000000000000000000000000000`). To pay CCIP fees in LINK instead, run `export FEE_TOKEN=$SEPOLIA_LINK`.

## Verify Result

`Example03` logs a CCIP message ID. Track it in the CCIP Explorer:

- https://ccip.chain.link

Optional receiver checks on Amoy:

```bash
cast call $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS "latestMessage()(bytes)" --rpc-url polygonAmoy
cast call $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS "latestSender()(address)" --rpc-url polygonAmoy
cast call $BASIC_MESSAGE_RECEIVER_WITH_CCVS_ADDRESS "latestSourceChainSelector()(uint64)" --rpc-url polygonAmoy
```
