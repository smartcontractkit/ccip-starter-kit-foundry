## Chainlink CCIP Starter Kit

> **Note**
>
> _This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

This project demonstrates a couple of basic Chainlink CCIP use cases.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Getting Started

1. Install packages

```
forge install
```

and

```
npm install
```

2. Compile contracts

```
forge build
```

## What is Chainlink CCIP?

**Chainlink Cross-Chain Interoperability Protocol (CCIP)** provides a single, simple, and elegant interface through which dApps and web3 entrepreneurs can securely meet all their cross-chain needs, including token transfers and arbitrary messaging.

![basic-architecture](./img/basic-architecture.png)

With Chainlink CCIP, one can:

- Transfer supported tokens
- Send messages (any data)
- Send messages and tokens

CCIP receiver can be:

- Smart contract that implements `CCIPReceiver.sol`
- EOA

**Note**: If you send a message and token(s) to EOA, only tokens will arrive

To use this project, you can consider CCIP as a "black-box" component and be aware of the Router contract only. If you want to dive deep into it, check the [Official Chainlink Documentation](https://docs.chain.link/ccip).

## Usage

In the next section you can see a couple of basic Chainlink CCIP use case examples. But before that, you need to set up some environment variables.

Create a new file by copying the `.env.example` file, and name it `.env`. Fill in your wallet's PRIVATE_KEY, and RPC URLs for at least two blockchains

```shell
PRIVATE_KEY=""
ETHEREUM_SEPOLIA_RPC_URL=""
OPTIMISM_GOERLI_RPC_URL=""
AVALANCHE_FUJI_RPC_URL=""
ARBITRUM_TESTNET_RPC_URL=""
POLYGON_MUMBAI_RPC_URL=""
```

Once that is done, to load the variables in the `.env` file, run the following command:

```shell
source .env
```

Make yourself familiar with the [`Helper.sol`](./script/Helper.sol) smart contract. It contains all the necessary Chainlink CCIP config. If you ever need to adjust any of those parameters, go to the Helper contract.

This contract also contains some enums, like `SupportedNetworks`:

```solidity
enum SupportedNetworks {
    ETHEREUM_SEPOLIA,   // 0
    OPTIMISM_GOERLI,    // 1
    AVALANCHE_FUJI,     // 2
    ARBITRUM_GOERLI,    // 3
    POLYGON_MUMBAI      // 4
}
```

This means that if you want to perform some action from `AVALANCHE_FUJI` blockchain to `ETHEREUM_SEPOLIA` blockchain, for example, you will need to pass `2 (uint8)` as a source blockchain flag and `0 (uint8)` as a destination blockchain flag.

Similarly, there is an `PayFeesIn` enum:

```solidity
enum PayFeesIn {
    Native,  // 0
    LINK     // 1
}
```

So, if you want to pay for Chainlink CCIP fees in LINK token, you will pass `1 (uint8)` as a function argument.

### Faucet

You will need test tokens for some of the examples in this Starter Kit. Public faucets sometimes limit how many tokens a user can create and token pools might not have enough liquidity. To resolve these issues, CCIP supports two test tokens that you can mint permissionlessly so you don't run out of tokens while testing different scenarios.

To get 10\*\*18 units of each of these tokens, use the `script/Faucet.s.sol` smart contract. Keep in mind that the `CCIP-BnM` test token you can mint on all testnets, while `CCIP-LnM` you can mint only on Ethereum Sepolia. On other testnets, the `CCIP-LnM` token representation is a wrapped/synthetic asset called `clCCIP-LnM`.

```solidity
function run(SupportedNetworks network) external;
```

For example, to mint 10\*\*18 units of both `CCIP-BnM` and `CCIP-LnM` test tokens on Ethereum Sepolia, run:

```shell
forge script ./script/Faucet.s.sol -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

Or if you want to mint 10\*\*18 units of `CCIP-BnM` test token on Avalanche Fuji, run:

```shell
forge script ./script/Faucet.s.sol -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

### Example 1 - Transfer Tokens from EOA to EOA

To transfer tokens from one EOA on one blockchain to another EOA on another blockchain you can use the `script/Example01.s.sol` smart contract:

```solidity
function run(
    SupportedNetworks source,
    SupportedNetworks destination,
    address receiver,
    address tokenToSend,
    uint256 amount,
    PayFeesIn payFeesIn
) external returns (bytes32 messageId);
```

For example, if you want to send 0.0000000000000001 LINK from Avalanche Fuji to Ethereum Sepolia and to pay for CCIP fees in native coin (Test AVAX), run:

```shell
forge script ./script/Example01.s.sol -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8,uint8,address,address,uint256,uint8)" -- 2 0 <RECEIVER_ADDRESS> 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 100 0
```

### Example 2 - Transfer Tokens from EOA to Smart Contract

To transfer tokens from EOA from the source blockchain to the smart contract on the destination blockchain, follow the next steps:

1. Deploy [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) to the **destination blockchain**, using the `script/Example02.s.sol:DeployBasicMessageReceiver` smart contract:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployBasicMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

2. Transfer tokens, from the **source blockchain** to the deployed BasicMessageReceiver smart contract using the `script/Example02.s.sol:CCIPTokenTransfer` smart contract:

```solidity
function run(
    SupportedNetworks source,
    SupportedNetworks destination,
    address basicMessageReceiver,
    address tokenToSend,
    uint256 amount,
    PayFeesIn payFeesIn
) external returns (bytes32 messageId);
```

For example, if you want to send 0.0000000000000001 LINK from Avalanche Fuji to Ethereum Sepolia and to pay for CCIP fees in native coin (Test AVAX), run:

```shell
forge script ./script/Example02.s.sol:CCIPTokenTransfer -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8,uint8,address,address,uint256,uint8)" -- 2 0 <BASIC_MESSAGE_RECEIVER_ADDRESS> 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 100 0
```

3. Once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Example02.s.sol:GetLatestMessageDetails` smart contract:

```solidity
function run(address basicMessageReceiver) external view;
```

For example,

```shell
forge script ./script/Example02.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <BASIC_MESSAGE_RECEIVER_ADDRESS>
```

4. Finally, you can always withdraw received tokens from the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract using the `cast send` command.

For example, to withdraw 100 units of LINK previously sent, run:

```shell
cast send <BASIC_MESSAGE_RECEIVER_ADDRESS> --rpc-url ethereumSepolia --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> 0x779877A7B0D9E8603169DdbD7836e478b4624789
```

### Example 3 - Transfer Token(s) from Smart Contract to any destination

To transfer a token or batch of tokens from a single, universal, smart contract to any address on the destination blockchain follow the next steps:

1. Deploy [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) to the **source blockchain**, using the `script/Example03.s.sol:DeployBasicTokenSender` smart contract:

```solidity
function run(SupportedNetworks source) external;
```

For example, if you want to send tokens from Avalanche Fuji to Ethereum Sepolia, run:

```shell
forge script ./script/Example03.s.sol:DeployBasicTokenSender -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

2. [OPTIONAL] If you want to send tokens to the smart contract, instead of EOA, you will need to deploy [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) to the **destination blockchain**. For this purpose, you can reuse the `script/Example02.s.sol:DeployBasicMessageReceiver` smart contract from the previous example:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployBasicMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

3. Fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) with tokens/coins for fees (you can always withdraw it later). You can do it manually from your wallet or by using the `cast send` command.

For example, if you want to pay for Chainlink CCIP Fees in LINK tokens, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 0.01 Avalanche Fuji LINK by running:

```shell
cast send 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 "transfer(address,uint256)" <BASIC_TOKEN_SENDER_ADDRESS> 10000000000000000 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
```

Or, if you want to pay for Chainlink CCIP Fees in Native coins, you can fill the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) smart contract with 0.1 Avalanche Fuji AVAX by running:

```shell
cast send <BASIC_TOKEN_SENDER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY --value 0.1ether
```

4. For each token you want to send, you will need to approve the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) to spend it on your behalf, by using the `cast send` command.

For example, if you want to send 0.0000000000000001 CCIP-BnM using the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) you will first need to approve that amount:

```shell
cast send 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4 "approve(address,uint256)" <BASIC_TOKEN_SENDER_ADDRESS> 100 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
```

Or, if you want to send 0.0000000000000001 LINK using the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) you will first need to approve that amount:

```shell
cast send 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 "approve(address,uint256)" <BASIC_TOKEN_SENDER_ADDRESS> 100 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
```

5. Finally, send tokens by providing the array of `Client.EVMTokenAmount {address token; uint256 amount;}` objects, using the `script/Example03.s.sol:SendBatch` smart contract:

```solidity
function run(
    SupportedNetworks destination,
    address payable basicTokenSenderAddres,
    address receiver,
    Client.EVMTokenAmount[] memory tokensToSendDetails,
    BasicTokenSender.PayFeesIn payFeesIn
) external;
```

For example, to send CCIP-BnM and LINK token amounts you previously approved from Avalanche Fuji to Ethereum Sepolia, and pay for Chainlink CCIP fees in LINK tokens, run:

```shell
forge script ./script/Example03.s.sol:SendBatch -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8,address,address,(address,uint256)[],uint8)" -- 0 <BASIC_TOKEN_SENDER_ADDRESS> <RECEIVER> "[(0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4,100),(0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,100)]" 1
```

6. Of course, you can always withdraw tokens you sent to the [`BasicTokenSender.sol`](./src/BasicTokenSender.sol) for fees, or from [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) if you received them there.

For example, to withdraw ERC20 tokens, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> <TOKEN_TO_WITHDRAW_ADDRESS>
```

And to withdraw Native coins, run:

```shell
cast send <CONTRACT_WITH_FUNDS_ADDRESS> --rpc-url <RPC_ENDPOINT> --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```

### Example 4 - Send & Receive Tokens and Data

To transfer tokens and data across multiple chains, follow the next steps:

1. Deploy the [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) smart contract to the **source blockchain**, using the `script/Example04.s.sol:DeployProgrammableTokenTransfers` smart contract:

```solidity
function run(SupportedNetworks network) external;
```

For example, if you want to send a message from Avalanche Fuji to Ethereum Sepolia type:

```shell
forge script ./script/Example04.s.sol:DeployProgrammableTokenTransfers -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

2. Open Metamask and fund your contract with Native tokens. For example, if you want to send a message from Avalanche Fuji to Ethereum Sepolia, you can send 0.01 Fuji AVAX to your contract. You can also do the same thing using the `cast send` command:

```shell
cast send <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY --value 0.1ether
```

3. Open Metamask and fund your contract with LINK tokens. For example, if you want to send a message from Avalanche Fuji to Ethereum Sepolia, you can send a 0.001 Fuji LINK to your contract. You can also do the same thing using the `cast send` command:

```shell
cast send 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 "transfer(address,uint256)" <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS> 10000000000000000 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
```

4. Deploy the [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) smart contract to the **destination blockchain**, using the `script/Example04.s.sol:DeployProgrammableTokenTransfers` smart contract, as you did in step number one.

For example, if you want to receive a message from Avalanche Fuji on Ethereum Sepolia type:

```shell
forge script ./script/Example04.s.sol:DeployProgrammableTokenTransfers -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

At this point, you have one **sender** contract on the source blockchain, and one **receiver** contract on the destination blockchain. Please note that [`ProgrammableTokenTransfers.sol`](./src/ProgrammableTokenTransfers.sol) can both send & receive tokens and data, hence we have two identical instances on both source and destination blockchains.

5. Send a message, using the `script/Example04.s.sol:SendTokensAndData` smart contract:

```solidity
function run(
    address payable sender,
    SupportedNetworks destination,
    address receiver,
    string memory message,
    address token,
    uint256 amount
) external;
```

For example, if you want to send a "Hello World" message alongside 100 units of Fuji LINK from Avalanche Fuji to Ethereum Sepolia, type:

```shell
forge script ./script/Example04.s.sol:SendTokensAndData -vvv --broadcast --rpc-url avalancheFuji --sig "run(address,uint8,address,string,address,uint256)" -- <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_SOURCE_BLOCKCHAIN> 0 <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_DESTINATION_BLOCKCHAIN> "Hello World" 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 100
```

6. Once the CCIP message is finalized on the destination blockchain, you can see the details of the latest CCIP message received, by running the following command:

```shell
cast call <PROGRAMMABLE_TOKEN_TRANSFERS_ADDRESS_ON_DESTINATION_BLOCKCHAIN> "getLastReceivedMessageDetails()" --rpc-url ethereumSepolia
```

### Example 5 - Send & Receive Cross-Chain Messages and Pay with Native Coins

To send simple Text Cross-Chain Messages and pay for CCIP fees in Native Tokens, follow the next steps:

1. Deploy the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract on the **source blockchain**, using the `script/Example05.s.sol:DeployBasicMessageSender` smart contract:

```solidity
function run(SupportedNetworks source) external;
```

For example, if you want to send a simple cross-chain message from Avalanche Fuji, run:

```shell
forge script ./script/Example05.s.sol:DeployBasicMessageSender -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

2. Fund the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract with Native Coins, either manually using your wallet or by using the `cast send` command. For example, if you want to send 0.1 Fuji AVAX, run:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY --value 0.1ether
```

3. Deploy the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract to the **destination blockchain**. For this purpose, you can reuse the `script/Example02.s.sol:DeployBasicMessageReceiver` smart contract from the second example:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployBasicMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

4. Finally, send a cross-chain message using the `script/Example05.s.sol:SendMessage` smart contract:

```solidity
function run(
    address payable sender,
    SupportedNetworks destination,
    address receiver,
    string memory message,
    BasicMessageSender.PayFeesIn payFeesIn
) external;
```

For example, if you want to send a "Hello World" message type:

```shell
forge script ./script/Example05.s.sol:SendMessage -vvv --broadcast --rpc-url avalancheFuji --sig "ru
n(address,uint8,address,string,uint8)" -- <BASIC_MESSAGE_SENDER_ADDRESS> 0 <BASIC_MESSAGE_RECEIVER_ADDRESS> "Hello World"
0
```

5. Once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Example02.s.sol:GetLatestMessageDetails` smart contract:

```solidity
function run(address basicMessageReceiver) external view;
```

For example,

```shell
forge script ./script/Example02.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <BASIC_MESSAGE_RECEIVER_ADDRESS>
```

6. You can always withdraw tokens for Chainlink CCIP fees from the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract using the `cast send` command:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```

### Example 6 - Send & Receive Cross-Chain Messages and Pay with LINK Tokens

To send simple Text Cross-Chain Messages and pay for CCIP fees in LINK Tokens, follow the next steps:

1. Deploy the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract on the **source blockchain**, using the `script/Example05.s.sol:DeployBasicMessageSender` smart contract:

```solidity
function run(SupportedNetworks source) external;
```

For example, if you want to send a simple cross-chain message from Avalanche Fuji, run:

```shell
forge script ./script/Example05.s.sol:DeployBasicMessageSender -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

2. Fund the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract with Testnet LINKs, either manually using your wallet or by using the `cast send` command. For example, if you want to send 0.01 Fuji LINK, run:

```shell
cast send 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 "transfer(address,uint256)" <BASIC_MESSAGE_SENDER_ADDRESS> 10000000000000000 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
```

3. Deploy the [`BasicMessageReceiver.sol`](./src/BasicMessageReceiver.sol) smart contract to the **destination blockchain**. For this purpose, you can reuse the `script/Example02.s.sol:DeployBasicMessageReceiver` smart contract from the second example:

```solidity
function run(SupportedNetworks destination) external;
```

For example, to deploy it to Ethereum Sepolia, run:

```shell
forge script ./script/Example02.s.sol:DeployBasicMessageReceiver -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

4. Finally, send a cross-chain message using the `script/Example05.s.sol:SendMessage` smart contract:

```solidity
function run(
    address payable sender,
    SupportedNetworks destination,
    address receiver,
    string memory message,
    BasicMessageSender.PayFeesIn payFeesIn
) external;
```

For example, if you want to send a "Hello World" message type:

```shell
forge script ./script/Example05.s.sol:SendMessage -vvv --broadcast --rpc-url avalancheFuji --sig "ru
n(address,uint8,address,string,uint8)" -- <BASIC_MESSAGE_SENDER_ADDRESS> 0 <BASIC_MESSAGE_RECEIVER_ADDRESS> "Hello World"
1
```

5. Once the CCIP message is finalized on the destination blockchain, you can see the details about the latest message using the `script/Example02.s.sol:GetLatestMessageDetails` smart contract:

```solidity
function run(address basicMessageReceiver) external view;
```

For example,

```shell
forge script ./script/Example02.s.sol:GetLatestMessageDetails -vvv --broadcast --rpc-url ethereumSepolia --sig "run(address)" -- <BASIC_MESSAGE_RECEIVER_ADDRESS>
```

6. You can always withdraw tokens for Chainlink CCIP fees from the [`BasicMessageSender.sol`](./src/BasicMessageSender.sol) smart contract using the `cast send` command:

```shell
cast send <BASIC_MESSAGE_SENDER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
```

### Example 7 - Execute Received Message as a Function Call

Our goal for this example is to mint an NFT on the destination blockchain by sending the `to` address from the source blockchain. It is extremely simple so we can understand the basic concepts, but you can expand it to accept payment for minting on the source blockchain, add extra features, etc.

The basic architecture diagram of what we want to accomplish looks like this:

```mermaid
flowchart LR
subgraph "Source Blockchain"
a("SourceMinter.sol") -- "`send abi.encodeWithSignature('mint(address)', msg.sender);`" --> b("Source Router")
end

b("Source Router") --> c("CCIP")

c("CCIP") --> d("Destination Router")

subgraph "Destination Blockchain"
d("Destination Router") -- "`receive abi.encodeWithSignature('mint(address)', msg.sender);`" --> e("DestinationMinter.sol")
e("DestinationMinter.sol") -- "`call mint(to)`" --> f("MyNFT.sol")
end
```

1. Deploy the [`MyNFT.sol`](./src/cross-chain-nft-minter/MyNFT.sol) and [`DestinationMinter.sol`](./src/cross-chain-nft-minter/DestinationMinter.sol) smart contracts from the `./src/cross-chain-nft-minter` folder on the **destination blockchain**, by using the `script/CrossChainNFT.s.sol:DeployDestination` smart contract:

```solidity
function run(SupportedNetworks destination) external;
```

For example, if you want to have an NFT collection on Ethereum Sepolia, run:

```shell
forge script ./script/CrossChainNFT.s.sol:DeployDestination -vvv --broadcast --rpc-url ethereumSepolia --sig "run(uint8)" -- 0
```

2. Deploy the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract on the **source blockchain**, by using the `script/CrossChainNFT.s.sol:DeploySource` smart contract:

```solidity
function run(SupportedNetworks source) external;
```

For example, if you want to mint NFTs on Ethereum Sepolia from Avalanche Fuji, run:

```shell
forge script ./script/CrossChainNFT.s.sol:DeploySource -vvv --broadcast --rpc-url avalancheFuji --sig "run(uint8)" -- 2
```

3. Fund the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract with tokens for CCIP fees.

- If you want to pay for CCIP fees in Native tokens:

  Open Metamask and fund your contract with Native tokens. For example, if you want to mint from Avalanche Fuji to Ethereum Sepolia, you can send 0.1 Fuji AVAX to the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract.

  Or, you can use the `cast send` command:

  ```shell
  cast send <SOURCE_MINTER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY --value 0.1ether
  ```

- If you want to pay for CCIP fees in LINK tokens:

  Open Metamask and fund your contract with LINK tokens. For example, if you want to mint from Avalanche Fuji to Ethereum Sepolia, you can send 0.01 Fuji LINK to the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract.

  Or, you can use the `cast send` command:

  ```shell
  cast send 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846 "transfer(address,uint256)" <SOURCE_MINTER_ADDRESS> 10000000000000000 --rpc-url avalancheFuji --private-key=$PRIVATE_KEY
  ```

4. Mint NFTs by calling the `mint()` function of the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract on the **source blockchain**. It will send the CCIP Cross-Chain Message with the ABI-encoded mint function signature from the [`MyNFT.sol`](./src/cross-chain-nft-minter/MyNFT.sol) smart contract. The [`DestinationMinter.sol`](./src/cross-chain-nft-minter/DestinationMinter.sol) smart contracts will receive the CCIP Cross-Chain Message with the ABI-encoded mint function signature as a payload and call the [`MyNFT.sol`](./src/cross-chain-nft-minter/MyNFT.sol) smart contract using it. The [`MyNFT.sol`](./src/cross-chain-nft-minter/MyNFT.sol) smart contract will then mint the new NFT to the `msg.sender` account from the `mint()` function of the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract, a.k.a to the account from which you will call the following command:

```solidity
function run(
    address payable sourceMinterAddress,
    SupportedNetworks destination,
    address destinationMinterAddress,
    SourceMinter.PayFeesIn payFeesIn
) external;
```

For example, if you want to mint NFTs on Ethereum Sepolia by sending requests from Avalanche Fuji, run:

```shell
forge script ./script/CrossChainNFT.s.sol:Mint -vvv --broadcast --rpc-url avalancheFuji --sig "run(a
ddress,uint8,address,uint8)" -- <SOURCE_MINTER_ADDRESS> 0 <DESTINATION_MINTER_ADDRESS> 0
```

5. Once the CCIP message is finalized on the destination blockchain, you can query the MyNFTs balance of your account, using the `cast call` command.

![ccip-explorer](./img/ccip-explorer.png)

For example, to verify that the new MyNFT was minted, type:

```shell
cast call <MY_NFT_ADDRESS> "balanceOf(address)" <PUT_YOUR_ADDRESS_HERE> --rpc-url ethereumSepolia
```

Of course, you can see your newly minted NFT on popular NFT Marketplaces, like OpenSea for instance:

![opensea](./img/opensea.png)

6. You can always withdraw tokens for Chainlink CCIP fees from the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) smart contract using the `cast send` command.

For example, to withdraw tokens previously sent for Chainlink CCIP fees, run:

```shell
cast send <SOURCE_MINTER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "withdraw(address)" <BENEFICIARY_ADDRESS>
```

or

```shell
cast send <SOURCE_MINTER_ADDRESS> --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "withdrawToken(address,address)" <BENEFICIARY_ADDRESS> 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
```

depending on whether you filled the [`SourceMinter.sol`](./src/cross-chain-nft-minter/SourceMinter.sol) contract with `Native (0)` or `LINK (1)` in step number 3.
