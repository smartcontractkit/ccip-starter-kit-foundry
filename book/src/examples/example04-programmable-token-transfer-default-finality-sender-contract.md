# Example 04: Programmable Token Transfer (Default Finality + Sender Contract)

This example sends a programmable token transfer from Avalanche Fuji to Ethereum Sepolia using a deployed `BasicMessageSender` contract:

- Data payload: `"Hello, World"`
- Tokens: `CCIP-BnM`
- Finality mode: default finality (`blockConfirmations = 0`)

Scripts used:

- `script/examples/Example04.s.sol:DeployBasicMessageSender`
- `script/examples/Example04.s.sol:Example04`

## What You Will Do

1. Deploy `BasicMessageSender` on source chain (Fuji).
2. Ensure destination `BasicMessageReceiver` exists on Sepolia.
3. Mint 1 `CCIP-BnM` on Fuji.
4. Quote fee, fund sender contract with that exact fee amount, then send data+token.

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
> forge script script/examples/Example02.s.sol:DeployBasicMessageReceiver \
>   --rpc-url ethereumSepolia \
>   --account myAccount \
>   --broadcast \
>   --sig "run(address)" \
>   <DESTINATION_ROUTER>
> ```
>
> Save the receiver address from the `[RESULT]` log and use it in Step 3.

## Step 1: Deploy `BasicMessageSender` on Fuji

```bash
forge script script/examples/Example04.s.sol:DeployBasicMessageSender \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address)" \
  <SOURCE_ROUTER> \
  <LINK_TOKEN_ON_SOURCE_CHAIN>
```

Save the deployed sender address from the `[RESULT]` log.

## Step 2: Get 1 CCIP-BnM Token on Fuji

```bash
forge script script/Faucet.s.sol:Faucet \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address)" \
  <CCIP_BNM_FUJI_ADDRESS>
```

## Step 3: Send Hello World + CCIP-BnM Through Sender Contract

```bash
forge script script/examples/Example04.s.sol:Example04 \
  --rpc-url avalancheFuji \
  --account myAccount \
  --broadcast \
  --sig "run(address,address,uint64,address,string,address,uint256,uint32)" \
  <DEPLOYED_BASIC_MESSAGE_SENDER_ADDRESS> \
  <SOURCE_ROUTER> \
  <DESTINATION_CHAIN_SELECTOR> \
  <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> \
  "Hello, World" \
  <CCIP_BNM_FUJI_ADDRESS> \
  <AMOUNT> \
  <GAS_LIMIT>
```

Parameter notes:

- This example always uses default finality by setting `blockConfirmations = 0` in the script.
- `<AMOUNT>` uses token decimals (`1e18` is 1 token for 18-decimal tokens).
- `<GAS_LIMIT>` must be `> 0` because the receiver contract callback handles data.
- The script first quotes the fee, then funds sender contract with that exact amount before calling `send`.
- If fee conditions change between quote and send, rerun the script to re-quote and retry.

## Verify Result

`Example04` logs a CCIP message ID. Track it in the CCIP Explorer:

- https://ccip.chain.link

Optional receiver checks on Sepolia:

```bash
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestMessage()(bytes)" --rpc-url ethereumSepolia
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestSender()(address)" --rpc-url ethereumSepolia
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestSourceChainSelector()(uint64)" --rpc-url ethereumSepolia
```
