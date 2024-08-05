// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {
    CCIPLocalSimulator, IRouterClient, BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {ProgrammableTokenTransfers} from "../../src/ProgrammableTokenTransfers.sol";

contract Example04Test is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    ProgrammableTokenTransfers public sender;
    ProgrammableTokenTransfers public receiver;

    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();
        (uint64 chainSelector, IRouterClient sourceRouter,,,, BurnMintERC677Helper ccipBnM,) =
            ccipLocalSimulator.configuration();

        sender = new ProgrammableTokenTransfers(address(sourceRouter));
        receiver = new ProgrammableTokenTransfers(address(sourceRouter));

        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
    }

    function test_programmableTokenTransfers() external {
        deal(address(sender), 1 ether);
        ccipBnMToken.drip(address(sender));

        uint256 balanceOfSenderBefore = ccipBnMToken.balanceOf(address(sender));
        uint256 balanceOfReceiverBefore = ccipBnMToken.balanceOf(address(receiver));

        string memory messageToSend = "Hello, World!";
        uint256 amountToSend = 100;

        bytes32 messageId = sender.sendMessage(
            destinationChainSelector, address(receiver), messageToSend, address(ccipBnMToken), amountToSend
        );

        (
            bytes32 latestMessageId,
            uint64 latestMessageSourceChainSelector,
            address latestMessageSender,
            string memory latestMessage,
            address latestMessageToken,
            uint256 latestMessageAmount
        ) = receiver.getLastReceivedMessageDetails();

        uint256 balanceOfSenderAfter = ccipBnMToken.balanceOf(address(sender));
        uint256 balanceOfReceiverAfter = ccipBnMToken.balanceOf(address(receiver));

        assertEq(latestMessageId, messageId);
        assertEq(latestMessageSourceChainSelector, destinationChainSelector);
        assertEq(latestMessageSender, address(sender));
        assertEq(latestMessage, messageToSend);
        assertEq(latestMessageToken, address(ccipBnMToken));
        assertEq(latestMessageAmount, amountToSend);

        assertEq(balanceOfSenderAfter, balanceOfSenderBefore - amountToSend);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amountToSend);
    }
}
