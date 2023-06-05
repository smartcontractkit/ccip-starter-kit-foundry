## CCIP Starter Kit

**INTERNAL ONLY, WORK IN PROGRESS**

_This repository represents an example of using a Chainlink product or service. It is provided to help you understand how to interact with Chainlink’s systems so that you can integrate them into your own. This template is provided "AS IS" without warranties of any kind, has not been audited, and may be missing key checks or error handling to make the usage of the product more clear. Take everything in this repository as an example and not something to be copy pasted into a production ready service._

## Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Getting Started

1. Install packages
```
forge install
```

2. Compile contracts
```
forge build
```

3. Run tests
```
forge test
```


### Example #1: Immutable :telephone_receiver:

This is an abstract contract that provides a simple platform for developers to write contracts that interact with CCIP (to both send and receive messages). It is constructed with a router address which acts as the entry point and exit point of CCIP. It implements ERC-165 to ensure the consumer contract can support the interface IAny2EVMMessageReceiver. This allows the ccipReceive function to be called on compatible contracts when messages are executed and ensure that messages sent to non-conforming contracts (such as smart contract wallets) do not revert.

### Example #2: Ping Pong :ping_pong:

This is a simple demo of Send-Receive CCIP message lifecycle. To run it, follow next steps:

1. Deploy the PingPongDemo.sol on the source chain, for example Ethereum Sepolia
2. Deploy the PingPongDemo.sol on the destination chain, for example Polygon Mumbai
3. Call `setCounterpart` function on the source chain, for example on Ethereum Sepolia call `setCounterpart(12532609583862916517, polygonMumbaiPingPongDemo)`
4. Call `setCounterpart` function on the destination chain, for example on Polygon Mumbai call `setCounterpart(16015286601757825753, ethereumSepoliaPingPongDemo)`

### Example #3: Cross-Chain Name Service :mailbox_with_mail:

![CCNS Architecture](ccns.png)
