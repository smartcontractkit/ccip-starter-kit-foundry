# Example 04: Programmable Token Transfer (Default Finality + Sender Contract)

This example sends a programmable token transfer from Ethereum Sepolia to Polygon Amoy using a deployed `BasicMessageSender` contract:

- Data payload: `"Hello, World"`
- Tokens: `CCIP-BnM`
- Finality mode: default finality (`blockConfirmations = 0`)

Because this chapter uses default finality, the baseline `BasicMessageReceiver` is sufficient on destination.
If you want the Fast Transfers (FTF) variant (`blockConfirmations > 0`), use Example03 with `BasicMessageReceiverWithCCVs`.

Scripts used:

- `script/examples/Example04.s.sol:DeployBasicMessageSender`
- `script/examples/Example04.s.sol:Example04`

## What You Will Do

1. Deploy `BasicMessageSender` on source chain (Sepolia).
2. Ensure destination `BasicMessageReceiver` exists on Amoy.
3. Mint 1 `CCIP-BnM` on Sepolia.
4. Quote fee, fund sender contract with that exact fee amount, then send data+token.

## Chapter Parameters

Set the parameters for this chapter. The defaults work as they are; change a value only if you want something different.

```bash
export AMOUNT=1000000000000000000  # 1 token (18 decimals)
export GAS_LIMIT=200000          # the receiver callback handles data
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
> forge script script/examples/Example04.s.sol:DeployBasicMessageReceiver \
>   --rpc-url polygonAmoy \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address)" \
>   $AMOY_ROUTER
> ```
>
> Copy the receiver address from the `[RESULT]` log and export it for Step 3:
>
> ```bash
> export BASIC_MESSAGE_RECEIVER_ADDRESS=0x...
> ```

## Step 1: Deploy `BasicMessageSender` on Sepolia

```bash
forge script script/examples/Example04.s.sol:DeployBasicMessageSender \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address)" \
  $SEPOLIA_ROUTER \
  $SEPOLIA_LINK
```

Copy the deployed sender address from the `[RESULT]` log and export it:

```bash
export BASIC_MESSAGE_SENDER_ADDRESS=0x...
```

## Step 2: Get 1 CCIP-BnM Token on Sepolia

Use the registered Sepolia token from [Example 01](example01-token-transfer-faster-than-finality.md):

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  $SEPOLIA_CCIP_BNM
```

## Step 3: Send Hello World + CCIP-BnM Through Sender Contract

```bash
forge script script/examples/Example04.s.sol:Example04 \
  --rpc-url ethereumSepolia \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,uint64,address,string,address,uint256,uint32)" \
  $BASIC_MESSAGE_SENDER_ADDRESS \
  $SEPOLIA_ROUTER \
  $AMOY_CHAIN_SELECTOR \
  $BASIC_MESSAGE_RECEIVER_ADDRESS \
  "Hello, World" \
  $SEPOLIA_CCIP_BNM \
  $AMOUNT \
  $GAS_LIMIT
```

Parameter notes:

- This example always uses default finality by setting `blockConfirmations = 0` in the script.
- `$AMOUNT` uses token decimals (`1e18` is 1 token for 18-decimal tokens).
- `$GAS_LIMIT` must be `> 0` because the receiver contract callback handles data.
- The script first quotes the fee, then funds sender contract with that exact amount before calling `send`.
- If fee conditions change between quote and send, rerun the script to re-quote and retry.

## Verify Result

`Example04` logs a CCIP message ID. Track it in the CCIP Explorer:

- https://ccip.chain.link

Optional receiver checks on Amoy:

```bash
cast call $BASIC_MESSAGE_RECEIVER_ADDRESS "latestMessage()(bytes)" --rpc-url polygonAmoy
cast call $BASIC_MESSAGE_RECEIVER_ADDRESS "latestSender()(address)" --rpc-url polygonAmoy
cast call $BASIC_MESSAGE_RECEIVER_ADDRESS "latestSourceChainSelector()(uint64)" --rpc-url polygonAmoy
```
