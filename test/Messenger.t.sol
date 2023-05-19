// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "chainlink-ccip/contracts/src/v0.8/ccip/test/onRamp/EVM2EVMOnRampSetup.t.sol";
import "forge-std/console.sol";
import {MessengerDemo} from "../src/Messenger.sol";

// setup
contract MessengerTest is EVM2EVMOnRampSetup {
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string message,
        uint256 fees
    );

    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string message
    );

    MessengerDemo s_messenger;

    MessengerDemo s_receiver;

    function setUp() public virtual override {
        EVM2EVMOnRampSetup.setUp();

        s_messenger = new MessengerDemo(address(s_sourceRouter));
        s_receiver = new MessengerDemo(address(s_sourceRouter));

        // fund in native tokens

        deal(address(s_messenger), 100 ether);
    }

    function testCommunication() public {
        string memory message = "Hello World!";
        uint256 fees = s_messenger.getFees(
            DEST_CHAIN_ID,
            address(s_receiver),
            message
        );

        console.log(
            "fees for sending message '%s' to '%s' are '%d'",
            message,
            address(s_receiver),
            fees
        );

        vm.expectEmit(false, true, true, true);
        emit MessageSent("", DEST_CHAIN_ID, address(s_receiver), message, fees);

        bytes32 messageId = s_messenger.sendMessage(
            DEST_CHAIN_ID,
            address(s_receiver),
            message
        );
        console.logBytes32(messageId);
        // receive message
        changePrank(address(s_sourceRouter));
        Client.Any2EVMMessage memory any2EVMMessage = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: SOURCE_CHAIN_ID,
            sender: abi.encode(s_messenger),
            data: abi.encode(message),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.expectEmit();
        emit MessageReceived(
            messageId,
            SOURCE_CHAIN_ID,
            address(s_messenger),
            message
        );

        s_receiver.ccipReceive(any2EVMMessage);
        assertEq(s_receiver.getNumberOfReceivedMessages(), 1);
        (
            bytes32 receivedMessageId,
            uint64 sourceChainSelector,
            address sender,
            string memory receivedMessage
        ) = s_receiver.getReceivedMessageAt(0);
        assertEq(receivedMessageId, messageId);
        assertEq(sourceChainSelector, SOURCE_CHAIN_ID);
        assertEq(sender, address(s_messenger));
        assertEq(receivedMessage, message);
    }
}
