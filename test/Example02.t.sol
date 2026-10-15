// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {
    DeployBasicMessageReceiverWithCCVs,
    SetBasicMessageReceiverWithCCVsMinBlockDepth,
    Example02
} from "script/examples/Example02.s.sol";
import {BasicMessageReceiverWithCCVs} from "src/BasicMessageReceiverWithCCVs.sol";

import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";

/// @notice Example 02: data-only message to BasicMessageReceiverWithCCVs using Fast Transfers.
/// @dev The receiver only accepts a Fast Transfer when its min block depth for the source chain is set and
///      the requested block confirmations are >= that depth. The local simulator reproduces that OffRamp check.
contract Example02Test is LocalSimulatorTest {
    string internal constant MESSAGE_TEXT = "Hello CCIP 2.0";
    uint32 internal constant GAS_LIMIT = 200_000;

    Example02 internal example;
    BasicMessageReceiverWithCCVs internal receiver;

    function setUp() public override {
        super.setUp();
        example = new Example02();
        receiver = BasicMessageReceiverWithCCVs(new DeployBasicMessageReceiverWithCCVs().run(address(router)));
    }

    function _setMinBlockDepth(uint16 minBlockDepth) internal {
        new SetBasicMessageReceiverWithCCVsMinBlockDepth().run(address(receiver), chainSelector, minBlockDepth);
    }

    function _send(uint16 blockConfirmations) internal returns (bytes32) {
        return example.run(
            address(router), chainSelector, address(receiver), MESSAGE_TEXT, GAS_LIMIT, blockConfirmations, address(0)
        );
    }

    function test_deployScriptWiresReceiverToRouterAndBroadcasterOwnsIt() public view {
        assertEq(receiver.getRouter(), address(router));
        assertEq(receiver.owner(), broadcaster);
    }

    function test_deliversMessageWhenConfirmationsAreAtLeastMinBlockDepth() public {
        _setMinBlockDepth(3);

        bytes32 messageId = _send(5);

        assertEq(receiver.latestMessageId(), messageId);
        assertEq(receiver.latestSourceChainSelector(), chainSelector);
        assertEq(receiver.latestSender(), broadcaster);
        assertEq(receiver.latestMessage(), abi.encode(MESSAGE_TEXT));
    }

    function test_deliversMessageWhenConfirmationsEqualMinBlockDepth() public {
        _setMinBlockDepth(3);

        bytes32 messageId = _send(3);

        assertEq(receiver.latestMessageId(), messageId);
    }

    function test_revertsWhenConfirmationsAreBelowMinBlockDepth() public {
        _setMinBlockDepth(3);

        vm.expectRevert(
            abi.encodeWithSelector(
                FinalityCodec.InvalidRequestedFinality.selector,
                FinalityCodec._encodeBlockDepth(2),
                FinalityCodec._encodeBlockDepth(3)
            )
        );
        _send(2);
    }

    function test_revertsWhenMinBlockDepthIsUnsetSoOnlyFullFinalityIsAccepted() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                FinalityCodec.InvalidRequestedFinality.selector,
                FinalityCodec._encodeBlockDepth(1),
                FinalityCodec.WAIT_FOR_FINALITY_FLAG
            )
        );
        _send(1);
    }

    function test_setMinBlockDepthScriptRejectsZeroSourceChainSelector() public {
        SetBasicMessageReceiverWithCCVsMinBlockDepth setter = new SetBasicMessageReceiverWithCCVsMinBlockDepth();
        vm.expectRevert("sourceChainSelector cannot be zero");
        setter.run(address(receiver), 0, 3);
    }

    function test_sendScriptRequiresNonZeroBlockConfirmations() public {
        vm.expectRevert("blockConfirmations == 0 means default finality; use > 0 for Faster Than Finality");
        _send(0);
    }
}
