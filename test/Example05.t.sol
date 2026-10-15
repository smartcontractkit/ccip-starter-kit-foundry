// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {Example05} from "script/examples/Example05.s.sol";
import {EncodeExtraArgsOffchain} from "script/EncodeExtraArgsOffchain.s.sol";
import {BasicMessageReceiverWithCCVs} from "src/BasicMessageReceiverWithCCVs.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

/// @notice Example 05: ExtraArgsV3 with the NO_EXECUTION_ADDRESS executor (manual execution path).
/// @dev Chainlink Local does not model executors or manual execution: the local router ignores `executor`, so these
///      tests only verify what the script sends. Whether the message stays pending until manually executed can only be
///      observed on a real lane (or a fork), and is deliberately not asserted here.
contract Example05Test is LocalSimulatorTest {
    string internal constant MESSAGE_TEXT = "Manual execution";
    uint32 internal constant GAS_LIMIT = 200_000;
    uint16 internal constant BLOCK_CONFIRMATIONS = 3;

    Example05 internal example;
    BasicMessageReceiverWithCCVs internal receiver;

    function setUp() public override {
        super.setUp();
        example = new Example05();
        receiver = new BasicMessageReceiverWithCCVs(address(router));
        receiver.setMinBlockDepth(chainSelector, BLOCK_CONFIRMATIONS);
    }

    function test_sendsExtraArgsV3WithNoExecutionExecutor() public {
        EncodeExtraArgsOffchain encoder = new EncodeExtraArgsOffchain();
        bytes memory expectedExtraArgs = encoder.encodeV3(
            GAS_LIMIT,
            BLOCK_CONFIRMATIONS,
            new address[](0),
            new bytes[](0),
            encoder.getNoExecutionAddress(),
            "",
            "",
            ""
        );
        Client.EVM2AnyMessage memory expectedMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(receiver)),
            data: abi.encode(MESSAGE_TEXT),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: expectedExtraArgs,
            feeToken: address(0)
        });

        vm.expectCall(address(router), abi.encodeCall(IRouterClient.ccipSend, (chainSelector, expectedMessage)));
        bytes32 messageId = example.run(
            address(router), chainSelector, address(receiver), MESSAGE_TEXT, GAS_LIMIT, BLOCK_CONFIRMATIONS, address(0)
        );

        assertTrue(messageId != bytes32(0));
    }

    function test_revertsWhenMessageTextIsEmpty() public {
        vm.expectRevert("messageText cannot be empty");
        example.run(address(router), chainSelector, address(receiver), "", GAS_LIMIT, BLOCK_CONFIRMATIONS, address(0));
    }

    function test_revertsWhenGasLimitIsZero() public {
        vm.expectRevert("gasLimit must be > 0 for contract callback");
        example.run(address(router), chainSelector, address(receiver), MESSAGE_TEXT, 0, BLOCK_CONFIRMATIONS, address(0));
    }
}
