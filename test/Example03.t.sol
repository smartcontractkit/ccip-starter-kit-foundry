// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {Example03} from "script/examples/Example03.s.sol";
import {BasicMessageReceiverWithCCVs} from "src/BasicMessageReceiverWithCCVs.sol";

import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";

/// @notice Example 03: programmable token transfer (data + token) to a contract receiver using Fast Transfers.
contract Example03Test is LocalSimulatorTest {
    string internal constant MESSAGE_TEXT = "Hello with tokens";
    uint256 internal constant AMOUNT = 1e17;
    uint32 internal constant GAS_LIMIT = 200_000;

    Example03 internal example;
    BasicMessageReceiverWithCCVs internal receiver;

    function setUp() public override {
        super.setUp();
        example = new Example03();
        receiver = new BasicMessageReceiverWithCCVs(address(router));
        receiver.setMinBlockDepth(chainSelector, 3);
        ccipBnM.drip(broadcaster);
    }

    function _send(uint16 blockConfirmations, address feeToken) internal returns (bytes32) {
        return example.run(
            address(router),
            chainSelector,
            address(receiver),
            MESSAGE_TEXT,
            address(ccipBnM),
            AMOUNT,
            GAS_LIMIT,
            blockConfirmations,
            feeToken
        );
    }

    function test_deliversTokensAndDataPayingNativeFee() public {
        uint256 fee = 0.01 ether;
        router.setFee(fee);
        deal(broadcaster, 1 ether);

        bytes32 messageId = _send(5, address(0));

        assertEq(ccipBnM.balanceOf(address(receiver)), AMOUNT);
        assertEq(receiver.latestMessageId(), messageId);
        assertEq(receiver.latestSender(), broadcaster);
        assertEq(receiver.latestMessage(), abi.encode(MESSAGE_TEXT));
        assertEq(address(router).balance, fee);
    }

    function test_deliversTokensAndDataPayingLinkFee() public {
        uint256 fee = 1e16;
        router.setFee(fee);
        simulator.requestLinkFromFaucet(broadcaster, 1 ether);

        bytes32 messageId = _send(5, address(link));

        assertEq(ccipBnM.balanceOf(address(receiver)), AMOUNT);
        assertEq(receiver.latestMessageId(), messageId);
        assertEq(link.balanceOf(address(router)), fee);
    }

    /// @dev A token+data message is not a token-only transfer, so the receiver's finality config is enforced
    ///      and no tokens move when it is rejected.
    function test_revertsWhenConfirmationsAreBelowReceiverMinBlockDepth() public {
        uint256 senderBefore = ccipBnM.balanceOf(broadcaster);

        vm.expectRevert(
            abi.encodeWithSelector(
                FinalityCodec.InvalidRequestedFinality.selector,
                FinalityCodec._encodeBlockDepth(2),
                FinalityCodec._encodeBlockDepth(3)
            )
        );
        _send(2, address(0));

        assertEq(ccipBnM.balanceOf(address(receiver)), 0);
        assertEq(ccipBnM.balanceOf(broadcaster), senderBefore);
    }

    function test_revertsWhenGasLimitIsZero() public {
        vm.expectRevert("gasLimit must be > 0 for contract callback");
        example.run(
            address(router), chainSelector, address(receiver), MESSAGE_TEXT, address(ccipBnM), AMOUNT, 0, 5, address(0)
        );
    }
}
