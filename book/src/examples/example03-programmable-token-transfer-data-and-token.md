# Example 03: Programmable Token Transfer (Hello World + CCIP-BnM)

This example sends a programmable token transfer from an EOA on Avalanche Fuji to a `BasicMessageReceiver` on Ethereum Sepolia:

- Data payload: `"Hello, World"`
- Tokens: `CCIP-BnM`

Script path: `script/examples/Example03.s.sol`

## What You Will Do

1. Ensure a destination `BasicMessageReceiver` exists on Sepolia.
2. Mint 1 `CCIP-BnM` on Fuji using `script/Faucet.s.sol`.
3. Send one CCIP message containing both data and tokens.

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
  <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> \
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
- Executor may enforce a minimum block confirmation value and revert if too low.
- If requested confirmations exceed chain finality, default finality is used.
- `<FEE_TOKEN_ADDRESS>`: Pass the LINK token address on the source chain here. If you want to pay for CCIP fees in native coin instead, pass `0x0000000000000000000000000000000000000000`

## Verify Result

`Example03` logs a CCIP message ID. Track it in the CCIP Explorer:

- https://ccip.chain.link

Optional receiver checks on Sepolia:

```bash
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestMessage()(bytes)" --rpc-url ethereumSepolia
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestSender()(address)" --rpc-url ethereumSepolia
cast call <DEPLOYED_BASIC_MESSAGE_RECEIVER_ADDRESS> "latestSourceChainSelector()(uint64)" --rpc-url ethereumSepolia
```
