// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {BasicMessageSender} from "src/BasicMessageSender.sol";
import {BasicMessageReceiver} from "src/BasicMessageReceiver.sol";
import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

contract DeployBasicMessageReceiver is Script {
    function run(address ccipRouter) external {
        vm.startBroadcast();

        BasicMessageReceiver basicMessageReceiver = new BasicMessageReceiver(ccipRouter);
        console2.log(
            "Basic Message Receiver deployed to Chain ID: ",
            block.chainid,
            ", with address: ",
            address(basicMessageReceiver)
        );

        vm.stopBroadcast();
    }
}

contract Example02 is Script {
    function run(address payable basicMessageSender, uint64 destinationChainSelector, address receiver) external {
        console2.log("Test scenario 1: Sending Hello world, paying fees in native, ExtraArgsV1, gas limit 200_000");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        uint256 gasLimit = 200_000;
        bytes memory extraArgs = extraArgsEncoder.encodeV1(gasLimit); // Legacy

        bytes memory dataToSend = abi.encode("Hello, World");

        vm.startBroadcast();

        // Fund sender contract
        (bool sent,) = basicMessageSender.call{value: 0.1 ether}("");
        require(sent, "Funding failed");

        bytes32 messageId = BasicMessageSender(basicMessageSender).send(
            destinationChainSelector, receiver, dataToSend, new Client.EVMTokenAmount[](0), extraArgs, address(0)
        );

        console2.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console2.logBytes32(messageId);

        // // Refund leftover, must be called by BasicMessageSender deployer
        // BasicMessageSender(basicMessageSender).withdraw(msg.sender);

        vm.stopBroadcast();
    }
}
