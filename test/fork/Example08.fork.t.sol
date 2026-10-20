// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AdvancedPoolHooksForkTest} from "./utils/AdvancedPoolHooksForkTest.sol";
import {Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Example08UpdateAllowlist} from "script/examples/Example08.s.sol";

import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";

/// @notice Example 08 (CCT 03): CrossChainToken + AdvancedPoolHooks + BurnMint pool on Sepolia -> Amoy.
/// @dev Runs against pinned forks of the live testnets. See `CCTForkTest` for what is and is not simulated.
///      The scripts seed the hook allowlist with the broadcaster, the only account that sends in these tests.
contract Example08ForkTest is AdvancedPoolHooksForkTest {
    Example08UpdateAllowlist internal updateAllowlistScript;

    function setUp() public override {
        super.setUp();
        updateAllowlistScript = Example08UpdateAllowlist(_persistent(address(new Example08UpdateAllowlist())));
    }

    function test_deploy_attachesHookWithBroadcasterOnAllowlist() public {
        _assertDeployed(sepoliaFork, sepolia, sepoliaToken, sepoliaHook, sepoliaPool);
        _assertDeployed(amoyFork, amoy, amoyToken, amoyHook, amoyPool);
    }

    function test_configureLane_setsRemoteTokenAndPool() public {
        vm.selectFork(sepoliaFork);
        assertTrue(TokenPool(sepoliaPool).isSupportedChain(amoy.chainSelector));
        assertEq(abi.decode(TokenPool(sepoliaPool).getRemoteToken(amoy.chainSelector), (address)), amoyToken);
        vm.selectFork(amoyFork);
        assertTrue(TokenPool(amoyPool).isSupportedChain(sepolia.chainSelector));
        assertEq(abi.decode(TokenPool(amoyPool).getRemoteToken(sepolia.chainSelector), (address)), sepoliaToken);
    }

    function test_send_allowlistedSenderBurnsAndMints() public {
        uint256 destinationSupplyBefore = _supplyOnFork(amoyFork, amoyToken);

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        assertEq(_balanceOnFork(sepoliaFork, sepoliaToken, broadcaster), PREMINT - TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(sepoliaFork, sepoliaToken), PREMINT - TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), destinationSupplyBefore + TRANSFER_AMOUNT);
    }

    function test_send_revertsWhenSenderIsRemovedFromAllowlist() public {
        _updateAllowlist(sepoliaFork, sepoliaHook, _single(broadcaster), new address[](0));

        vm.selectFork(sepoliaFork);
        vm.expectPartialRevert(AdvancedPoolHooks.SenderNotAllowed.selector);
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

    function test_updateAllowlist_removeThenAddRestoresAccess() public {
        _updateAllowlist(sepoliaFork, sepoliaHook, _single(broadcaster), new address[](0));
        assertEq(AdvancedPoolHooks(sepoliaHook).getAllowList().length, 0);

        _updateAllowlist(sepoliaFork, sepoliaHook, new address[](0), _single(broadcaster));
        address[] memory allowlist = AdvancedPoolHooks(sepoliaHook).getAllowList();
        assertEq(allowlist.length, 1);
        assertEq(allowlist[0], broadcaster);

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    function _updateAllowlist(uint256 fork, address hook, address[] memory removes, address[] memory adds) internal {
        vm.selectFork(fork);
        updateAllowlistScript.run(hook, removes, adds);
    }

    function _single(address account) internal pure returns (address[] memory accounts) {
        accounts = new address[](1);
        accounts[0] = account;
    }

    function _assertDeployed(
        uint256 fork,
        Register.NetworkDetails memory network,
        address token,
        address hook,
        address pool
    ) internal override {
        super._assertDeployed(fork, network, token, hook, pool);

        AdvancedPoolHooks advancedPoolHooks = AdvancedPoolHooks(hook);
        assertTrue(advancedPoolHooks.getAllowListEnabled(), "allowlist should be enabled");
        address[] memory allowlist = advancedPoolHooks.getAllowList();
        assertEq(allowlist.length, 1);
        assertEq(allowlist[0], broadcaster);
        assertEq(advancedPoolHooks.getThresholdAmount(), THRESHOLD);
        assertEq(address(advancedPoolHooks.getPolicyEngine()), address(0), "policy engine is disabled");
    }
}
