// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

import {
    SendCCTTokenWithExtraArgsV3DefaultFinality,
    SendCCTTokenWithExtraArgsV3CustomFinality,
    Example06SetPoolAllowedFinalityConfig,
    Example06GetPoolAllowedFinalityConfig,
    FinalityQuoter,
    IRouterOnRampView,
    ITypeAndVersionView
} from "script/examples/Example06.s.sol";

import {TokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/TokenAdminRegistry.sol";
import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

/// @notice Shared setup for fork tests of the CCT examples (Example06-08) on Ethereum Sepolia -> Polygon Amoy.
/// @dev Chainlink Local no-fork mode has no token pools or TokenAdminRegistry, so these tests run the real example
///      scripts against forks of the live testnets and let `CCIPLocalSimulatorFork` route the message to the
///      destination OffRamp. Both forks are pinned to a block (see `DEFAULT_*_FORK_BLOCK`), so a run is reproducible.
///
///      The scripts call `vm.startBroadcast()` with no argument, so in a test every script transaction is sent by
///      `DEFAULT_SENDER` (exposed as `broadcaster`). Foundry keeps that account persistent across forks, but contracts
///      created inside the test are per-fork unless made persistent, hence `_persistent`.
///
///      Not modelled by the simulator (and not asserted): real CCV attestations, RMN, executor fees and manual
///      execution. CCVs on the lane are replaced by a synthetic verifier.
abstract contract CCTForkTest is Test {
    uint256 internal constant TRANSFER_AMOUNT = 1 ether;
    uint32 internal constant EOA_RECEIVER_GAS_LIMIT = 0;

    /// @dev Committed fork pins, so a fresh clone runs the same chain state. Override per run with the
    ///      `ETHEREUM_SEPOLIA_FORK_BLOCK` / `POLYGON_AMOY_FORK_BLOCK` env vars (for example a recent block, to check
    ///      whether the live lane has drifted). To re-pin, update both numbers here, see AGENTS.md ("Re-pinning").
    uint256 internal constant DEFAULT_SEPOLIA_FORK_BLOCK = 11_920_292;
    uint256 internal constant DEFAULT_AMOY_FORK_BLOCK = 50_243_111;

    CCIPLocalSimulatorFork internal simulator;
    uint256 internal sepoliaFork;
    uint256 internal amoyFork;
    Register.NetworkDetails internal sepolia;
    Register.NetworkDetails internal amoy;

    address internal broadcaster = DEFAULT_SENDER;
    address internal receiver = makeAddr("receiver");

    SendCCTTokenWithExtraArgsV3DefaultFinality internal sendDefaultFinality;
    SendCCTTokenWithExtraArgsV3CustomFinality internal sendCustomFinality;
    Example06SetPoolAllowedFinalityConfig internal setAllowedFinality;
    Example06GetPoolAllowedFinalityConfig internal getAllowedFinality;
    FinalityQuoter internal finalityQuoter;

    function setUp() public virtual {
        sepoliaFork =
            vm.createSelectFork("ethereumSepolia", vm.envOr("ETHEREUM_SEPOLIA_FORK_BLOCK", DEFAULT_SEPOLIA_FORK_BLOCK));
        amoyFork = vm.createFork("polygonAmoy", vm.envOr("POLYGON_AMOY_FORK_BLOCK", DEFAULT_AMOY_FORK_BLOCK));

        // The simulator must be created on a fork and be persistent so it can route across forks.
        simulator = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(simulator));

        sepolia = simulator.getNetworkDetails(block.chainid);
        vm.selectFork(amoyFork);
        amoy = simulator.getNetworkDetails(block.chainid);

        vm.selectFork(sepoliaFork);
        vm.deal(broadcaster, 100 ether);
        vm.selectFork(amoyFork);
        vm.deal(broadcaster, 100 ether);
        vm.selectFork(sepoliaFork);

        // Fail with a clear message if the pinned block or the lane is not what the book describes.
        address onRamp = IRouterOnRampView(sepolia.routerAddress).getOnRamp(amoy.chainSelector);
        assertTrue(onRamp != address(0), "Sepolia router has no OnRamp for Amoy at the pinned block");
        assertEq(ITypeAndVersionView(onRamp).typeAndVersion(), "OnRamp 2.0.0", "Sepolia -> Amoy is not a CCIP 2.0 lane");

        sendDefaultFinality = SendCCTTokenWithExtraArgsV3DefaultFinality(
            _persistent(address(new SendCCTTokenWithExtraArgsV3DefaultFinality()))
        );
        sendCustomFinality = SendCCTTokenWithExtraArgsV3CustomFinality(
            _persistent(address(new SendCCTTokenWithExtraArgsV3CustomFinality()))
        );
        setAllowedFinality =
            Example06SetPoolAllowedFinalityConfig(_persistent(address(new Example06SetPoolAllowedFinalityConfig())));
        getAllowedFinality =
            Example06GetPoolAllowedFinalityConfig(_persistent(address(new Example06GetPoolAllowedFinalityConfig())));
        finalityQuoter = FinalityQuoter(_persistent(address(new FinalityQuoter())));
    }

    // ----------------------------------------------------------------
    // Script wrappers
    // ----------------------------------------------------------------

    /// @dev Sends `amount` of `token` Sepolia -> Amoy to `receiver` (native fee, default finality) and routes it.
    ///      The active fork is Amoy when this returns.
    function _sendDefaultFinalityAndRoute(address token, uint256 amount) internal {
        vm.selectFork(sepoliaFork);
        sendDefaultFinality.run(
            sepolia.routerAddress, amoy.chainSelector, receiver, token, amount, EOA_RECEIVER_GAS_LIMIT, address(0)
        );
        simulator.switchChainAndRouteMessage(amoyFork);
    }

    /// @dev Same as above but requests `depth` block confirmations (Faster Than Finality).
    function _sendCustomFinalityAndRoute(address token, uint256 amount, uint16 depth) internal {
        vm.selectFork(sepoliaFork);
        sendCustomFinality.run(
            sepolia.routerAddress,
            amoy.chainSelector,
            receiver,
            token,
            amount,
            EOA_RECEIVER_GAS_LIMIT,
            depth,
            address(0)
        );
        simulator.switchChainAndRouteMessage(amoyFork);
    }

    /// @dev Sets the pool's allowed finality to a minimum block depth through the book's script, on the active fork.
    function _setPoolMinBlockDepth(address pool, uint16 depth) internal {
        setAllowedFinality.run(pool, FinalityCodec._encodeBlockDepth(depth));
    }

    /// @dev Smallest candidate depth the live lane accepts for a token-only transfer of `token`, found by quoting.
    ///      Candidates are probed in ascending order. The source pool must already allow depth 1 or above, otherwise
    ///      the quote reverts at the pool.
    function _findLaneFtfDepth(address token) internal returns (uint16 depth) {
        uint16[8] memory candidates = [uint16(1), 2, 3, 5, 10, 20, 50, 100];
        vm.selectFork(sepoliaFork);
        for (uint256 i = 0; i < candidates.length; ++i) {
            try finalityQuoter.quote(sepolia.routerAddress, amoy.chainSelector, token, candidates[i]) returns (
                uint256
            ) {
                return candidates[i];
            } catch {}
        }
        revert("no Faster Than Finality depth up to 100 is accepted by the Sepolia -> Amoy lane at the pinned block");
    }

    // ----------------------------------------------------------------
    // Assertions
    // ----------------------------------------------------------------

    function _assertRegistered(Register.NetworkDetails memory network, address token, address pool, address admin)
        internal
        view
    {
        TokenAdminRegistry.TokenConfig memory config =
            TokenAdminRegistry(network.tokenAdminRegistryAddress).getTokenConfig(token);
        assertEq(config.administrator, admin, "registry administrator");
        assertEq(config.pendingAdministrator, address(0), "registry pending administrator");
        assertEq(config.tokenPool, pool, "registry token pool");
    }

    function _balanceOnFork(uint256 fork, address token, address account) internal returns (uint256 balance) {
        vm.selectFork(fork);
        balance = IERC20(token).balanceOf(account);
    }

    function _supplyOnFork(uint256 fork, address token) internal returns (uint256 supply) {
        vm.selectFork(fork);
        supply = IERC20(token).totalSupply();
    }

    function _persistent(address target) internal returns (address) {
        vm.makePersistent(target);
        return target;
    }
}
