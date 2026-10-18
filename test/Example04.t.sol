// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {DeployBasicMessageReceiver, DeployBasicMessageSender, Example04} from "script/examples/Example04.s.sol";
import {BasicMessageReceiver} from "src/BasicMessageReceiver.sol";
import {BasicMessageSender} from "src/BasicMessageSender.sol";

/// @notice Example 04: programmable token transfer (data + token) through BasicMessageSender with default finality.
contract Example04Test is LocalSimulatorTest {
    string internal constant MESSAGE_TEXT = "Hello via sender contract";
    uint256 internal constant AMOUNT = 1e17;
    uint32 internal constant GAS_LIMIT = 200_000;

    Example04 internal example;
    BasicMessageSender internal sender;
    BasicMessageReceiver internal receiver;

    function setUp() public override {
        super.setUp();
        example = new Example04();
        sender = BasicMessageSender(payable(new DeployBasicMessageSender().run(address(router), address(link))));
        receiver = BasicMessageReceiver(new DeployBasicMessageReceiver().run(address(router)));
        ccipBnM.drip(broadcaster);
    }

    function _send() internal returns (bytes32) {
        return example.run(
            address(sender),
            address(router),
            chainSelector,
            address(receiver),
            MESSAGE_TEXT,
            address(ccipBnM),
            AMOUNT,
            GAS_LIMIT
        );
    }

    function test_deliversTokensAndDataThroughSenderContract() public {
        uint256 fee = 0.01 ether;
        router.setFee(fee);
        deal(broadcaster, 1 ether);
        uint256 senderBefore = ccipBnM.balanceOf(broadcaster);

        bytes32 messageId = _send();

        assertEq(ccipBnM.balanceOf(address(receiver)), AMOUNT);
        assertEq(ccipBnM.balanceOf(broadcaster), senderBefore - AMOUNT);
        assertEq(receiver.latestMessageId(), messageId);
        assertEq(receiver.latestSourceChainSelector(), chainSelector);
        // The router sees the sender contract, not the EOA, as the message sender.
        assertEq(receiver.latestSender(), address(sender));
        assertEq(receiver.latestMessage(), abi.encode(MESSAGE_TEXT));
        assertEq(address(router).balance, fee);
        assertEq(address(sender).balance, 0);
    }

    function test_deliversWhenFeeIsZero() public {
        bytes32 messageId = _send();

        assertEq(receiver.latestMessageId(), messageId);
        assertEq(ccipBnM.balanceOf(address(receiver)), AMOUNT);
    }

    function test_revertsWhenAmountIsZero() public {
        vm.expectRevert("amount must be > 0");
        example.run(
            address(sender),
            address(router),
            chainSelector,
            address(receiver),
            MESSAGE_TEXT,
            address(ccipBnM),
            0,
            GAS_LIMIT
        );
    }

    function test_revertsWhenGasLimitIsZero() public {
        vm.expectRevert("gasLimit must be > 0 for contract callback");
        example.run(
            address(sender),
            address(router),
            chainSelector,
            address(receiver),
            MESSAGE_TEXT,
            address(ccipBnM),
            AMOUNT,
            0
        );
    }
}
