// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AdvancedPoolHooksForkTest} from "./utils/AdvancedPoolHooksForkTest.sol";
import {
    Example10AttachPolicyEngine,
    Example10DetachPolicyEngine,
    Example10DeployExamplePolicyEngine
} from "script/examples/Example10.s.sol";

import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";
import {ExamplePolicyEngine} from "../../src/ExamplePolicyEngine.sol";
import {CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

/// @notice Example 10 (CCT 05): policy engine on AdvancedPoolHooks, Sepolia -> Amoy.
/// @dev Runs against pinned forks of the live testnets. See `CCTForkTest` for what is and is not simulated.
///      The hook calls the engine locally on each chain, so the source and destination engines are
///      independent instances (unlike pool-required CCVs, they do not need to share an address).
contract Example10ForkTest is AdvancedPoolHooksForkTest {
    Example10AttachPolicyEngine internal attachEngineScript;
    Example10DetachPolicyEngine internal detachEngineScript;
    Example10DeployExamplePolicyEngine internal deployEngineScript;

    function setUp() public override {
        super.setUp();
        attachEngineScript = Example10AttachPolicyEngine(_persistent(address(new Example10AttachPolicyEngine())));
        detachEngineScript = Example10DetachPolicyEngine(_persistent(address(new Example10DetachPolicyEngine())));
        deployEngineScript =
            Example10DeployExamplePolicyEngine(_persistent(address(new Example10DeployExamplePolicyEngine())));
    }

    function test_attachPolicyEngine_attachesEngineToHook() public {
        vm.selectFork(sepoliaFork);
        address engine = deployEngineScript.run();
        attachEngineScript.run(sepoliaHook, engine);

        assertEq(AdvancedPoolHooks(sepoliaHook).getPolicyEngine(), engine);
        assertTrue(ExamplePolicyEngine(engine).isAttached(sepoliaHook), "engine did not record the hook as attached");
    }

    function test_send_policyEngineAllowsTransfersWithinCap() public {
        vm.selectFork(sepoliaFork);
        address engine = deployEngineScript.run();
        attachEngineScript.run(sepoliaHook, engine);

        uint256 destinationSupplyBefore = _supplyOnFork(amoyFork, amoyToken);

        // The default cap (10 ether) is above the transfer amount, so the engine allows the transfer.
        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), destinationSupplyBefore + TRANSFER_AMOUNT);
    }

    function test_send_revertsWhenAmountExceedsEngineCap() public {
        vm.selectFork(sepoliaFork);
        address engine = deployEngineScript.run();
        attachEngineScript.run(sepoliaHook, engine);

        // Lower the cap below the transfer amount: the source-side preflight check rejects the send.
        // The engine is owned by the broadcaster (the script deployer), so prank as it to set the cap.
        vm.prank(broadcaster);
        ExamplePolicyEngine(engine).setCap(TRANSFER_AMOUNT / 2);

        vm.expectPartialRevert(ExamplePolicyEngine.AmountExceedsCap.selector);
        sendDefaultFinality.run(
            sepolia.routerAddress,
            amoy.chainSelector,
            receiver,
            sepoliaToken,
            TRANSFER_AMOUNT,
            EOA_RECEIVER_GAS_LIMIT,
            address(0)
        );
    }

    function test_send_failsToExecuteWhenDestinationEngineRejects() public {
        vm.selectFork(sepoliaFork);
        address sourceEngine = deployEngineScript.run();
        attachEngineScript.run(sepoliaHook, sourceEngine);

        // Attach a destination engine with a cap below the transfer amount: the send succeeds on the
        // source, but the destination-side postflight check rejects the execution.
        vm.selectFork(amoyFork);
        address destinationEngine = deployEngineScript.run();
        attachEngineScript.run(amoyHook, destinationEngine);
        vm.prank(broadcaster);
        ExamplePolicyEngine(destinationEngine).setCap(TRANSFER_AMOUNT / 2);

        vm.selectFork(sepoliaFork);
        sendDefaultFinality.run(
            sepolia.routerAddress,
            amoy.chainSelector,
            receiver,
            sepoliaToken,
            TRANSFER_AMOUNT,
            EOA_RECEIVER_GAS_LIMIT,
            address(0)
        );

        // Strict routing surfaces the recorded destination-side failure.
        vm.expectPartialRevert(CCIPLocalSimulatorFork.CCIPLocalSimulatorFork__MessageExecutionFailed.selector);
        simulator.switchChainAndRouteMessage(amoyFork);
    }

    function test_detachPolicyEngine_restoresUnrestrictedTransfers() public {
        vm.selectFork(sepoliaFork);
        address engine = deployEngineScript.run();
        attachEngineScript.run(sepoliaHook, engine);
        vm.prank(broadcaster);
        ExamplePolicyEngine(engine).setCap(TRANSFER_AMOUNT / 2);

        detachEngineScript.run(sepoliaHook);
        assertEq(AdvancedPoolHooks(sepoliaHook).getPolicyEngine(), address(0));
        assertFalse(ExamplePolicyEngine(engine).isAttached(sepoliaHook), "engine still records the hook as attached");

        // With the engine detached, the same transfer that was rejected now succeeds.
        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
    }
}
