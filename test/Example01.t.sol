// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {Example01} from "script/examples/Example01.s.sol";

/// @notice Example 01: token transfer to an EOA with ExtraArgsV3 and Fast Transfers (non-zero block confirmations).
contract Example01Test is LocalSimulatorTest {
    uint256 internal constant AMOUNT = 1e17;
    uint32 internal constant EOA_GAS_LIMIT = 0;
    uint16 internal constant BLOCK_CONFIRMATIONS = 5;

    Example01 internal example;
    address internal receiver;

    function setUp() public override {
        super.setUp();
        example = new Example01();
        receiver = makeAddr("receiver");
        ccipBnM.drip(broadcaster);
    }

    function test_transfersTokenToEoaPayingNativeFee() public {
        uint256 fee = 0.01 ether;
        router.setFee(fee);
        deal(broadcaster, 1 ether);

        uint256 senderBefore = ccipBnM.balanceOf(broadcaster);

        bytes32 messageId = example.run(
            address(router),
            chainSelector,
            receiver,
            address(ccipBnM),
            AMOUNT,
            EOA_GAS_LIMIT,
            BLOCK_CONFIRMATIONS,
            address(0)
        );

        assertTrue(messageId != bytes32(0));
        assertEq(ccipBnM.balanceOf(receiver), AMOUNT);
        assertEq(ccipBnM.balanceOf(broadcaster), senderBefore - AMOUNT);
        assertEq(address(router).balance, fee);
    }

    function test_transfersTokenToEoaPayingLinkFee() public {
        uint256 fee = 1e16;
        router.setFee(fee);
        simulator.requestLinkFromFaucet(broadcaster, 1 ether);

        bytes32 messageId = example.run(
            address(router),
            chainSelector,
            receiver,
            address(ccipBnM),
            AMOUNT,
            EOA_GAS_LIMIT,
            BLOCK_CONFIRMATIONS,
            address(link)
        );

        assertTrue(messageId != bytes32(0));
        assertEq(ccipBnM.balanceOf(receiver), AMOUNT);
        assertEq(link.balanceOf(address(router)), fee);
    }

    function test_revertsWhenBlockConfirmationsIsZero() public {
        vm.expectRevert("blockConfirmations == 0 means default finality; use > 0 for Faster Than Finality");
        example.run(address(router), chainSelector, receiver, address(ccipBnM), AMOUNT, EOA_GAS_LIMIT, 0, address(0));
    }

    function test_revertsWhenAmountIsZero() public {
        vm.expectRevert("amount must be > 0");
        example.run(
            address(router),
            chainSelector,
            receiver,
            address(ccipBnM),
            0,
            EOA_GAS_LIMIT,
            BLOCK_CONFIRMATIONS,
            address(0)
        );
    }
}
