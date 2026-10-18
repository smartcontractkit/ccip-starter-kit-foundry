// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Vm} from "forge-std/Vm.sol";
import {LocalSimulatorTest} from "./utils/LocalSimulatorTest.sol";
import {CCIPLocalRouter} from "@chainlink/local/src/ccip/CCIPLocalRouter.sol";
import {BasicMessageReceiver} from "src/BasicMessageReceiver.sol";
import {BasicMessageSender} from "src/BasicMessageSender.sol";
import {Withdraw} from "src/utils/Withdraw.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";
import {ExtraArgsCodec} from "@chainlink/contracts-ccip/contracts/libraries/ExtraArgsCodec.sol";
import {Ownable} from "@openzeppelin/contracts@5.3.0/access/Ownable.sol";

/// @notice Tests BasicMessageSender, BasicMessageReceiver and the Withdraw base against the Chainlink Local router.
contract BasicMessageSenderAndReceiverTest is LocalSimulatorTest {
    uint256 internal constant AMOUNT = 1e17;
    uint32 internal constant GAS_LIMIT = 200_000;

    BasicMessageSender internal sender;
    BasicMessageReceiver internal receiver;
    address internal user = makeAddr("user");
    address internal beneficiary = makeAddr("beneficiary");

    function setUp() public override {
        super.setUp();
        sender = new BasicMessageSender(address(router), address(link));
        receiver = new BasicMessageReceiver(address(router));
    }

    function _noTokens() internal pure returns (Client.EVMTokenAmount[] memory) {
        return new Client.EVMTokenAmount[](0);
    }

    function _oneToken(uint256 amount) internal view returns (Client.EVMTokenAmount[] memory tokens) {
        tokens = new Client.EVMTokenAmount[](1);
        tokens[0] = Client.EVMTokenAmount({token: address(ccipBnM), amount: amount});
    }

    function _extraArgs(uint16 blockConfirmations) internal pure returns (bytes memory) {
        return
            ExtraArgsCodec._getBasicEncodedExtraArgsV3(GAS_LIMIT, FinalityCodec._encodeBlockDepth(blockConfirmations));
    }

    // --- BasicMessageSender ---

    function test_sendDataOnlyPayingNativeFee() public {
        uint256 fee = 0.01 ether;
        router.setFee(fee);
        vm.deal(address(sender), fee);

        bytes32 messageId =
            sender.send(chainSelector, address(receiver), "hello", _noTokens(), _extraArgs(0), address(0));

        assertEq(receiver.latestMessageId(), messageId);
        assertEq(receiver.latestSender(), address(sender));
        assertEq(receiver.latestMessage(), "hello");
        assertEq(address(router).balance, fee);
    }

    function test_sendDataOnlyPayingLinkFee() public {
        uint256 fee = 1e16;
        router.setFee(fee);
        simulator.requestLinkFromFaucet(address(sender), 1 ether);

        bytes32 messageId =
            sender.send(chainSelector, address(receiver), "hello", _noTokens(), _extraArgs(0), address(link));

        assertEq(receiver.latestMessageId(), messageId);
        assertEq(link.balanceOf(address(router)), fee);
        assertEq(link.balanceOf(address(sender)), 1 ether - fee);
    }

    function test_sendPullsTokenFromCallerAndDeliversToReceiver() public {
        ccipBnM.drip(user);
        vm.startPrank(user);
        ccipBnM.approve(address(sender), AMOUNT);

        sender.send(chainSelector, address(receiver), "with token", _oneToken(AMOUNT), _extraArgs(0), address(0));
        vm.stopPrank();

        assertEq(ccipBnM.balanceOf(address(receiver)), AMOUNT);
        assertEq(ccipBnM.balanceOf(user), 1e18 - AMOUNT);
        assertEq(ccipBnM.balanceOf(address(sender)), 0);
    }

    function test_sendRevertsWhenCallerHasNotApprovedToken() public {
        ccipBnM.drip(user);
        vm.prank(user);
        vm.expectRevert("ERC20: insufficient allowance");
        sender.send(chainSelector, address(receiver), "with token", _oneToken(AMOUNT), _extraArgs(0), address(0));
    }

    function test_sendRevertsWhenNativeFeeIsNotFunded() public {
        router.setFee(0.01 ether);

        // The sender forwards `{value: fee}` it does not hold, so the call fails with empty revert data.
        vm.expectRevert(bytes(""));
        sender.send(chainSelector, address(receiver), "hello", _noTokens(), _extraArgs(0), address(0));
    }

    function test_sendRevertsWhenMoreThanOneTokenIsRequestedByLocalRouterRules() public {
        // The contract's NatSpec says one token per message; CCIP 2.0 OnRamp enforces it and so does the local router.
        Client.EVMTokenAmount[] memory tokens = new Client.EVMTokenAmount[](2);
        tokens[0] = Client.EVMTokenAmount({token: address(ccipBnM), amount: 1});
        tokens[1] = Client.EVMTokenAmount({token: address(ccipBnM), amount: 1});
        ccipBnM.drip(user);
        vm.startPrank(user);
        ccipBnM.approve(address(sender), 2);

        vm.expectRevert(CCIPLocalRouter.CanOnlySendOneTokenPerMessage.selector);
        sender.send(chainSelector, address(receiver), "two tokens", tokens, _extraArgs(0), address(0));
        vm.stopPrank();
    }

    // --- BasicMessageReceiver ---

    function test_receiverStoresLatestMessageAndEmits() public {
        vm.recordLogs();
        bytes32 messageId =
            sender.send(chainSelector, address(receiver), "stored", _noTokens(), _extraArgs(0), address(0));

        assertEq(receiver.latestMessageId(), messageId);
        assertEq(receiver.latestSourceChainSelector(), chainSelector);
        assertEq(receiver.latestSender(), address(sender));
        assertEq(receiver.latestMessage(), "stored");

        // The receiver's event carries no indexed fields, so decode it from the recorded logs.
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 matches;
        for (uint256 i = 0; i < logs.length; ++i) {
            if (
                logs[i].emitter == address(receiver)
                    && logs[i].topics[0] == BasicMessageReceiver.MessageReceived.selector
            ) {
                (bytes32 id, uint64 selector, address from, bytes memory data) =
                    abi.decode(logs[i].data, (bytes32, uint64, address, bytes));
                assertEq(id, messageId);
                assertEq(selector, chainSelector);
                assertEq(from, address(sender));
                assertEq(data, "stored");
                ++matches;
            }
        }
        assertEq(matches, 1);
    }

    function test_receiverRejectsCallsFromNonRouter() public {
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(uint256(1)),
            sourceChainSelector: chainSelector,
            sender: abi.encode(user),
            data: "spoofed",
            destTokenAmounts: _noTokens()
        });

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("InvalidRouter(address)", user));
        receiver.ccipReceive(message);
    }

    function test_receiverOnlyAcceptsFullFinalityByDefault() public {
        // BasicMessageReceiver inherits CCIPReceiver's default config: finality required, no Fast Transfers.
        vm.expectRevert(
            abi.encodeWithSelector(
                FinalityCodec.InvalidRequestedFinality.selector,
                FinalityCodec._encodeBlockDepth(3),
                FinalityCodec.WAIT_FOR_FINALITY_FLAG
            )
        );
        sender.send(chainSelector, address(receiver), "fast", _noTokens(), _extraArgs(3), address(0));
    }

    // --- Withdraw (inherited by BasicMessageSender) ---

    function test_senderAcceptsNativeAndOwnerCanWithdraw() public {
        vm.deal(address(sender), 1 ether);

        sender.withdraw(beneficiary);

        assertEq(beneficiary.balance, 1 ether);
        assertEq(address(sender).balance, 0);
    }

    function test_ownerCanWithdrawTokens() public {
        ccipBnM.drip(address(sender));

        sender.withdrawToken(beneficiary, address(ccipBnM));

        assertEq(ccipBnM.balanceOf(beneficiary), 1e18);
        assertEq(ccipBnM.balanceOf(address(sender)), 0);
    }

    function test_withdrawRevertsForNonOwner() public {
        vm.deal(address(sender), 1 ether);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        sender.withdraw(beneficiary);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        sender.withdrawToken(beneficiary, address(ccipBnM));
    }

    function test_withdrawRevertsWhenBeneficiaryRejectsEther() public {
        vm.deal(address(sender), 1 ether);
        address rejecting = address(this); // this test contract has no payable receive()

        vm.expectRevert(
            abi.encodeWithSelector(Withdraw.FailedToWithdrawEth.selector, address(this), rejecting, 1 ether)
        );
        sender.withdraw(rejecting);
    }
}
