// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BasicMessageReceiverWithCCVs} from "src/BasicMessageReceiverWithCCVs.sol";

import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";
import {Ownable} from "@openzeppelin/contracts@5.3.0/access/Ownable.sol";

contract BasicMessageReceiverWithCCVsTest is Test {
    uint64 internal constant SOURCE_CHAIN = 16015286601757825753;
    address internal constant ROUTER = address(0xC0FFEE);

    BasicMessageReceiverWithCCVs internal receiver;
    address internal ccvA = makeAddr("ccvA");
    address internal ccvB = makeAddr("ccvB");
    address internal ccvC = makeAddr("ccvC");
    address internal stranger = makeAddr("stranger");

    function setUp() public {
        receiver = new BasicMessageReceiverWithCCVs(ROUTER);
    }

    function _args(address[] memory required, address[] memory optional, uint8 threshold)
        internal
        pure
        returns (BasicMessageReceiverWithCCVs.CCVConfigArgs[] memory args)
    {
        args = new BasicMessageReceiverWithCCVs.CCVConfigArgs[](1);
        args[0] = BasicMessageReceiverWithCCVs.CCVConfigArgs({
            requiredCCVs: required,
            optionalCCVs: optional,
            sourceChainSelector: SOURCE_CHAIN,
            optionalThreshold: threshold
        });
    }

    function _addrs(address a) internal pure returns (address[] memory list) {
        list = new address[](1);
        list[0] = a;
    }

    function _addrs(address a, address b) internal pure returns (address[] memory list) {
        list = new address[](2);
        list[0] = a;
        list[1] = b;
    }

    function _addrs(address a, address b, address c) internal pure returns (address[] memory list) {
        list = new address[](3);
        list[0] = a;
        list[1] = b;
        list[2] = c;
    }

    // --- constructor / ownership ---

    function test_constructorSetsRouterAndOwner() public view {
        assertEq(receiver.getRouter(), ROUTER);
        assertEq(receiver.owner(), address(this));
    }

    // --- min block depth -> allowed finality ---

    function test_getCCVsAndFinalityConfigDefaultsToFullFinalityAndNoCCVs() public view {
        (address[] memory required, address[] memory optional, uint8 threshold, bytes4 finality) =
            receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");

        assertEq(required.length, 0);
        assertEq(optional.length, 0);
        assertEq(threshold, 0);
        assertEq(finality, FinalityCodec.WAIT_FOR_FINALITY_FLAG);
    }

    function test_setMinBlockDepthIsReflectedAsBlockDepthFinality() public {
        vm.expectEmit(true, false, false, true, address(receiver));
        emit BasicMessageReceiverWithCCVs.MinBlockDepthSet(SOURCE_CHAIN, 7);
        receiver.setMinBlockDepth(SOURCE_CHAIN, 7);

        (,,, bytes4 finality) = receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");
        assertEq(finality, FinalityCodec._encodeBlockDepth(7));
    }

    function test_minBlockDepthIsPerSourceChain() public {
        receiver.setMinBlockDepth(SOURCE_CHAIN, 7);

        (,,, bytes4 otherChainFinality) = receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN + 1, "");
        assertEq(otherChainFinality, FinalityCodec.WAIT_FOR_FINALITY_FLAG);
    }

    function test_resettingMinBlockDepthToZeroRestoresFullFinality() public {
        receiver.setMinBlockDepth(SOURCE_CHAIN, 7);
        receiver.setMinBlockDepth(SOURCE_CHAIN, 0);

        (,,, bytes4 finality) = receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");
        assertEq(finality, FinalityCodec.WAIT_FOR_FINALITY_FLAG);
    }

    function test_setMinBlockDepthRevertsForNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        receiver.setMinBlockDepth(SOURCE_CHAIN, 7);
    }

    // --- CCV config ---

    function test_applyCCVConfigUpdatesStoresConfigAndEmits() public {
        address[] memory required = _addrs(ccvA);
        address[] memory optional = _addrs(ccvB, ccvC);

        vm.expectEmit(true, false, false, true, address(receiver));
        emit BasicMessageReceiverWithCCVs.CCVConfigSet(SOURCE_CHAIN, required, optional, 1);
        receiver.applyCCVConfigUpdates(_args(required, optional, 1));

        (address[] memory gotRequired, address[] memory gotOptional, uint8 threshold,) =
            receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");
        assertEq(gotRequired, required);
        assertEq(gotOptional, optional);
        assertEq(threshold, 1);
    }

    function test_applyCCVConfigUpdatesOverwritesPreviousConfig() public {
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), _addrs(ccvB, ccvC), 1));
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvC), new address[](0), 0));

        (address[] memory gotRequired, address[] memory gotOptional, uint8 threshold,) =
            receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");
        assertEq(gotRequired, _addrs(ccvC));
        assertEq(gotOptional.length, 0);
        assertEq(threshold, 0);
    }

    function test_applyCCVConfigUpdatesAllowsZeroAddressAsRequiredCCV() public {
        // address(0) as a required CCV signals "always enforce the lane's default CCVs".
        receiver.applyCCVConfigUpdates(_args(_addrs(address(0)), new address[](0), 0));

        (address[] memory gotRequired,,,) = receiver.getCCVsAndFinalityConfig(SOURCE_CHAIN, "");
        assertEq(gotRequired, _addrs(address(0)));
    }

    function test_applyCCVConfigUpdatesRevertsForNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), new address[](0), 0));
    }

    function test_applyCCVConfigUpdatesRevertsWhenThresholdEqualsOptionalCount() public {
        // threshold == optional count means the optional CCVs are effectively required.
        vm.expectRevert(
            abi.encodeWithSelector(BasicMessageReceiverWithCCVs.InvalidOptionalThreshold.selector, SOURCE_CHAIN, 2)
        );
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), _addrs(ccvB, ccvC), 2));
    }

    function test_applyCCVConfigUpdatesRevertsWhenThresholdExceedsOptionalCount() public {
        vm.expectRevert(
            abi.encodeWithSelector(BasicMessageReceiverWithCCVs.InvalidOptionalThreshold.selector, SOURCE_CHAIN, 3)
        );
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), _addrs(ccvB, ccvC), 3));
    }

    function test_applyCCVConfigUpdatesRevertsWhenThresholdSetWithoutOptionalCCVs() public {
        vm.expectRevert(
            abi.encodeWithSelector(BasicMessageReceiverWithCCVs.InvalidOptionalThreshold.selector, SOURCE_CHAIN, 1)
        );
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), new address[](0), 1));
    }

    function test_applyCCVConfigUpdatesRevertsOnZeroAddressAsOptionalCCV() public {
        vm.expectRevert(BasicMessageReceiverWithCCVs.ZeroAddressNotAllowedAsOptional.selector);
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), _addrs(address(0), ccvB), 1));
    }

    function test_applyCCVConfigUpdatesRevertsOnDuplicateWithinRequired() public {
        vm.expectRevert(abi.encodeWithSelector(BasicMessageReceiverWithCCVs.DuplicateCCV.selector, SOURCE_CHAIN, ccvA));
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA, ccvA), new address[](0), 0));
    }

    function test_applyCCVConfigUpdatesRevertsOnDuplicateAcrossRequiredAndOptional() public {
        vm.expectRevert(abi.encodeWithSelector(BasicMessageReceiverWithCCVs.DuplicateCCV.selector, SOURCE_CHAIN, ccvA));
        receiver.applyCCVConfigUpdates(_args(_addrs(ccvA), _addrs(ccvA, ccvB), 1));
    }
}
