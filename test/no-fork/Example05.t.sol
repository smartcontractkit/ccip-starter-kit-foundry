// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulator, IRouterClient, LinkToken} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {BasicMessageSender} from "../../src/BasicMessageSender.sol";
import {BasicMessageReceiver} from "../../src/BasicMessageReceiver.sol";

contract Example05Test is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    BasicMessageSender public sender;
    BasicMessageReceiver public receiver;

    uint64 public destinationChainSelector;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (uint64 chainSelector, IRouterClient sourceRouter, IRouterClient destinationRouter,, LinkToken link,,) =
            ccipLocalSimulator.configuration();

        sender = new BasicMessageSender(address(sourceRouter), address(link));
        receiver = new BasicMessageReceiver(address(destinationRouter));

        destinationChainSelector = chainSelector;
    }

    function test_sendAndReceiveCrossChainMessagePayFeesInNative() external {
        deal(address(sender), 1 ether);

        string memory messageToSend = "Hello, World!";

        bytes32 messageId =
            sender.send(destinationChainSelector, address(receiver), messageToSend, BasicMessageSender.PayFeesIn.Native);

        (bytes32 latestMessageId, uint64 latestSourceChainSelector, address latestSender, string memory latestMessage) =
            receiver.getLatestMessageDetails();

        assertEq(latestMessageId, messageId);
        assertEq(latestSourceChainSelector, destinationChainSelector);
        assertEq(latestSender, address(sender));
        assertEq(latestMessage, messageToSend);
    }
}
