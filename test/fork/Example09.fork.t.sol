// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AdvancedPoolHooksForkTest} from "./utils/AdvancedPoolHooksForkTest.sol";
import {CountingCCV} from "./utils/CountingCCV.sol";
import {Example09SetPoolCCVConfig, Example09SetThresholdAmount} from "script/examples/Example09.s.sol";

import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";

/// @notice Example 09 (CCT 04): pool-based CCV requirements on AdvancedPoolHooks, Sepolia -> Amoy.
/// @dev Runs against pinned forks of the live testnets. See `CCTForkTest` for what is and is not simulated.
///      A pool-required CCV must exist at the same address on both chains: the source OnRamp consults it
///      outbound and the destination OffRamp resolves `getInboundImplementation` on the same address. The
///      test deploys a counting no-op CCV once and makes it persistent, so it exists at that address on
///      both chains (real CCVs are CREATE2-deployed to matching addresses). Like the simulator's own CCVs,
///      it performs no real verification.
contract Example09ForkTest is AdvancedPoolHooksForkTest {
    Example09SetPoolCCVConfig internal setCCVConfigScript;
    Example09SetThresholdAmount internal setThresholdScript;

    /// @dev Deployed once and made persistent, so it exists at the same address on both chains — which is
    ///      exactly what a pool-required CCV needs (real CCVs are CREATE2-deployed to matching addresses).
    CountingCCV internal ccv;
    CountingCCV internal thresholdCCV;

    function setUp() public override {
        super.setUp();

        setCCVConfigScript = Example09SetPoolCCVConfig(_persistent(address(new Example09SetPoolCCVConfig())));
        setThresholdScript = Example09SetThresholdAmount(_persistent(address(new Example09SetThresholdAmount())));

        vm.selectFork(sepoliaFork);
        ccv = CountingCCV(_persistent(address(new CountingCCV())));
        thresholdCCV = CountingCCV(_persistent(address(new CountingCCV())));
    }

    function test_setPoolCCVConfig_storesConfigOnBothHooks() public {
        _setCCVConfig(sepoliaFork, sepoliaHook, amoy.chainSelector, address(ccv));
        _setCCVConfig(amoyFork, amoyHook, sepolia.chainSelector, address(ccv));

        vm.selectFork(sepoliaFork);
        AdvancedPoolHooks.CCVConfig memory sepoliaConfig =
            AdvancedPoolHooks(sepoliaHook).getCCVConfig(amoy.chainSelector);
        assertEq(sepoliaConfig.outboundCCVs.length, 1);
        assertEq(sepoliaConfig.outboundCCVs[0], address(ccv));
        assertEq(sepoliaConfig.inboundCCVs.length, 1);
        assertEq(sepoliaConfig.inboundCCVs[0], address(ccv));

        vm.selectFork(amoyFork);
        AdvancedPoolHooks.CCVConfig memory amoyConfig = AdvancedPoolHooks(amoyHook).getCCVConfig(sepolia.chainSelector);
        assertEq(amoyConfig.outboundCCVs.length, 1);
        assertEq(amoyConfig.outboundCCVs[0], address(ccv));
        assertEq(amoyConfig.inboundCCVs.length, 1);
        assertEq(amoyConfig.inboundCCVs[0], address(ccv));
    }

    function test_send_poolRequiredCCVIsConsultedOnBothSides() public {
        _setCCVConfig(sepoliaFork, sepoliaHook, amoy.chainSelector, address(ccv));
        _setCCVConfig(amoyFork, amoyHook, sepolia.chainSelector, address(ccv));

        uint256 destinationSupplyBefore = _supplyOnFork(amoyFork, amoyToken);

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        // The transfer still succeeds end to end.
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), destinationSupplyBefore + TRANSFER_AMOUNT);

        // The source OnRamp consulted the CCV outbound (getOutboundImplementation + forwardToVerifier).
        vm.selectFork(sepoliaFork);
        assertEq(ccv.outboundConsultations(), 1, "source OnRamp did not consult the pool-required CCV");

        // The destination OffRamp verified the message inbound (getInboundImplementation + verifyMessage).
        vm.selectFork(amoyFork);
        assertEq(ccv.inboundVerifications(), 1, "destination OffRamp did not verify with the pool-required CCV");
    }

    function test_send_thresholdCCVsAreRequiredAboveThresholdAmount() public {
        // Base CCVs: the double. Threshold CCVs: a second CCV, as duplicates within a config are rejected.
        // First raise the threshold above the transfer amount: only the base CCV is required.
        _setThreshold(sepoliaFork, sepoliaHook, TRANSFER_AMOUNT + 1);
        _setThreshold(amoyFork, amoyHook, TRANSFER_AMOUNT + 1);
        _setCCVConfigWithThreshold(sepoliaFork, sepoliaHook, amoy.chainSelector, address(ccv), address(thresholdCCV));
        _setCCVConfigWithThreshold(amoyFork, amoyHook, sepolia.chainSelector, address(ccv), address(thresholdCCV));

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        vm.selectFork(sepoliaFork);
        assertEq(ccv.outboundConsultations(), 1);
        assertEq(thresholdCCV.outboundConsultations(), 0, "threshold CCV consulted below threshold");

        vm.selectFork(amoyFork);
        assertEq(ccv.inboundVerifications(), 1);
        assertEq(thresholdCCV.inboundVerifications(), 0, "threshold CCV verified below threshold");

        // Now lower the threshold to 1 wei: the same transfer amount requires the threshold CCV too.
        _setThreshold(sepoliaFork, sepoliaHook, 1);
        _setThreshold(amoyFork, amoyHook, 1);

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        vm.selectFork(sepoliaFork);
        assertEq(ccv.outboundConsultations(), 2);
        assertEq(thresholdCCV.outboundConsultations(), 1, "threshold CCV not consulted at/above threshold");

        vm.selectFork(amoyFork);
        assertEq(ccv.inboundVerifications(), 2);
        assertEq(thresholdCCV.inboundVerifications(), 1, "threshold CCV not verified at/above threshold");
    }

    function test_setPoolCCVConfig_clearingWithEmptyListsRemovesConfig() public {
        _setCCVConfig(sepoliaFork, sepoliaHook, amoy.chainSelector, address(ccv));
        assertTrue(AdvancedPoolHooks(sepoliaHook).getCCVConfig(amoy.chainSelector).outboundCCVs.length > 0);

        // Clearing with empty lists removes the selector from the configured set.
        _clearCCVConfig(sepoliaFork, sepoliaHook, amoy.chainSelector);

        AdvancedPoolHooks.CCVConfig memory cleared = AdvancedPoolHooks(sepoliaHook).getCCVConfig(amoy.chainSelector);
        assertEq(cleared.outboundCCVs.length, 0);
        assertEq(cleared.inboundCCVs.length, 0);
        assertEq(AdvancedPoolHooks(sepoliaHook).getAllCCVConfigs().length, 0);
    }

    function test_setPoolCCVConfig_revertsWhenThresholdCCVsHaveNoBaseCCVs() public {
        vm.selectFork(sepoliaFork);
        vm.expectPartialRevert(AdvancedPoolHooks.MustSpecifyUnderThresholdCCVsForThresholdCCVs.selector);
        setCCVConfigScript.run(
            sepoliaHook,
            amoy.chainSelector,
            new address[](0), // no base outbound CCVs
            _single(address(ccv)), // threshold outbound CCVs
            new address[](0),
            new address[](0)
        );
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    function _setCCVConfig(uint256 fork, address hook, uint64 remoteChainSelector, address ccv) internal {
        _setCCVConfigWithThreshold(fork, hook, remoteChainSelector, ccv, address(0));
    }

    function _setCCVConfigWithThreshold(
        uint256 fork,
        address hook,
        uint64 remoteChainSelector,
        address baseCCV,
        address thresholdCCV
    ) internal {
        vm.selectFork(fork);
        address[] memory outboundCCVs = _single(baseCCV);
        address[] memory inboundCCVs = _single(baseCCV);
        address[] memory thresholdOutboundCCVs = thresholdCCV != address(0) ? _single(thresholdCCV) : new address[](0);
        address[] memory thresholdInboundCCVs = thresholdCCV != address(0) ? _single(thresholdCCV) : new address[](0);
        setCCVConfigScript.run(
            hook, remoteChainSelector, outboundCCVs, thresholdOutboundCCVs, inboundCCVs, thresholdInboundCCVs
        );
    }

    function _clearCCVConfig(uint256 fork, address hook, uint64 remoteChainSelector) internal {
        vm.selectFork(fork);
        setCCVConfigScript.run(
            hook, remoteChainSelector, new address[](0), new address[](0), new address[](0), new address[](0)
        );
    }

    function _setThreshold(uint256 fork, address hook, uint256 thresholdAmount) internal {
        vm.selectFork(fork);
        setThresholdScript.run(hook, thresholdAmount);
    }

    function _single(address account) internal pure returns (address[] memory accounts) {
        accounts = new address[](1);
        accounts[0] = account;
    }
}
