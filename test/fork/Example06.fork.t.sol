// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CCTForkTest} from "./utils/CCTForkTest.sol";
import {Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {DeployCCTBurnMintTokenAndPool, Example06, Example06CheckFinalityGates} from "script/examples/Example06.s.sol";

import {CrossChainToken} from "@chainlink/contracts-ccip/contracts/tokens/CrossChainToken.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";

/// @notice Example 06 (CCT 01): CrossChainToken + BurnMint pool on Sepolia -> Amoy, driven through the book's scripts.
/// @dev Runs against pinned forks of the live testnets. See `CCTForkTest` for what is and is not simulated.
contract Example06ForkTest is CCTForkTest {
    uint256 internal constant PREMINT = 1_000_000 ether;
    uint256 internal constant MAX_SUPPLY = 100_000_000 ether;

    DeployCCTBurnMintTokenAndPool internal deployScript;
    Example06 internal configureLaneScript;
    Example06CheckFinalityGates internal checkFinalityGatesScript;

    address internal sepoliaToken;
    address internal sepoliaPool;
    address internal amoyToken;
    address internal amoyPool;

    function setUp() public override {
        super.setUp();
        deployScript = DeployCCTBurnMintTokenAndPool(_persistent(address(new DeployCCTBurnMintTokenAndPool())));
        configureLaneScript = Example06(_persistent(address(new Example06())));
        checkFinalityGatesScript = Example06CheckFinalityGates(_persistent(address(new Example06CheckFinalityGates())));

        (sepoliaToken, sepoliaPool) = _deploy(sepoliaFork, sepolia);
        (amoyToken, amoyPool) = _deploy(amoyFork, amoy);
    }

    function test_deploy_createsTokenAndPoolAndRegistersThem() public {
        _assertDeployed(sepoliaFork, sepolia, sepoliaToken, sepoliaPool);
        _assertDeployed(amoyFork, amoy, amoyToken, amoyPool);
    }

    function test_configureLane_setsRemoteTokenAndPool() public {
        _linkPools();

        _assertLinked(sepoliaFork, sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        _assertLinked(amoyFork, amoyPool, sepolia.chainSelector, sepoliaToken, sepoliaPool);
    }

    function test_configureLane_rerunReplacesExistingConfig() public {
        _linkPools();
        _linkPools();

        _assertLinked(sepoliaFork, sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        assertEq(TokenPool(sepoliaPool).getSupportedChains().length, 1);
    }

    function test_send_defaultFinalityBurnsOnSourceAndMintsOnDestination() public {
        _linkPools();
        uint256 sourceBalanceBefore = _balanceOnFork(sepoliaFork, sepoliaToken, broadcaster);
        uint256 sourceSupplyBefore = _supplyOnFork(sepoliaFork, sepoliaToken);
        uint256 destinationSupplyBefore = _supplyOnFork(amoyFork, amoyToken);

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        assertEq(_balanceOnFork(sepoliaFork, sepoliaToken, broadcaster), sourceBalanceBefore - TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(sepoliaFork, sepoliaToken), sourceSupplyBefore - TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), destinationSupplyBefore + TRANSFER_AMOUNT);
    }

    function test_send_fasterThanFinalityRevertsUntilPoolOptsIn() public {
        _linkPools();
        vm.selectFork(sepoliaFork);

        // New pools allow full finality only, so any block depth request is rejected by the pool.
        assertEq(TokenPool(sepoliaPool).getAllowedFinalityConfig(), FinalityCodec.WAIT_FOR_FINALITY_FLAG);
        vm.expectPartialRevert(FinalityCodec.InvalidRequestedFinality.selector);
        sendCustomFinality.run(
            sepolia.routerAddress,
            amoy.chainSelector,
            receiver,
            sepoliaToken,
            TRANSFER_AMOUNT,
            EOA_RECEIVER_GAS_LIMIT,
            1,
            address(0)
        );
    }

    function test_send_fasterThanFinalityDeliversAfterPoolsOptIn() public {
        _linkPools();

        // Book step 5: opt both pools in. Depth 1 is the most permissive pool setting, so it lets us ask the lane
        // (executor and CCVs) for the smallest depth it accepts, which is then what both pools are set to.
        vm.selectFork(sepoliaFork);
        _setPoolMinBlockDepth(sepoliaPool, 1);
        uint16 depth = _findLaneFtfDepth(sepoliaToken);
        _setPoolMinBlockDepth(sepoliaPool, depth);
        vm.selectFork(amoyFork);
        _setPoolMinBlockDepth(amoyPool, depth);

        vm.selectFork(sepoliaFork);
        assertEq(getAllowedFinality.run(sepoliaPool), FinalityCodec._encodeBlockDepth(depth));
        vm.selectFork(amoyFork);
        assertEq(getAllowedFinality.run(amoyPool), FinalityCodec._encodeBlockDepth(depth));

        uint256 sourceBalanceBefore = _balanceOnFork(sepoliaFork, sepoliaToken, broadcaster);
        uint256 sourceSupplyBefore = _supplyOnFork(sepoliaFork, sepoliaToken);
        uint256 destinationSupplyBefore = _supplyOnFork(amoyFork, amoyToken);

        _sendCustomFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT, depth);

        assertEq(_balanceOnFork(sepoliaFork, sepoliaToken, broadcaster), sourceBalanceBefore - TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(sepoliaFork, sepoliaToken), sourceSupplyBefore - TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), destinationSupplyBefore + TRANSFER_AMOUNT);
    }

    /// @dev The book's read-only pre-flight must run to completion for a registered token on a CCIP 2.0 lane. It
    ///      reverts if the OnRamp is not 2.0.0 or the token has no pool in the TokenAdminRegistry for the lane.
    function test_checkFinalityGates_findsRegisteredPool() public {
        _linkPools();
        vm.selectFork(sepoliaFork);

        checkFinalityGatesScript.run(sepolia.routerAddress, amoy.chainSelector, sepoliaToken, 1);
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    function _deploy(uint256 fork, Register.NetworkDetails memory network)
        internal
        returns (address token, address pool)
    {
        vm.selectFork(fork);
        (token, pool) = deployScript.run(
            network.tokenAdminRegistryAddress,
            network.registryModuleOwnerCustomAddress,
            network.rmnProxyAddress,
            network.routerAddress
        );
    }

    /// @dev Book steps 3 and 4: configure each pool with the other chain as its remote.
    function _linkPools() internal {
        vm.selectFork(sepoliaFork);
        configureLaneScript.run(sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        vm.selectFork(amoyFork);
        configureLaneScript.run(amoyPool, sepolia.chainSelector, sepoliaToken, sepoliaPool);
    }

    function _assertDeployed(uint256 fork, Register.NetworkDetails memory network, address token, address pool)
        internal
    {
        vm.selectFork(fork);
        CrossChainToken crossChainToken = CrossChainToken(token);
        assertEq(crossChainToken.name(), "TestToken");
        assertEq(crossChainToken.symbol(), "TEST");
        assertEq(crossChainToken.decimals(), 18);
        assertEq(crossChainToken.maxSupply(), MAX_SUPPLY);
        assertEq(crossChainToken.totalSupply(), PREMINT);
        assertEq(crossChainToken.balanceOf(broadcaster), PREMINT);
        assertEq(crossChainToken.getCCIPAdmin(), broadcaster);
        assertTrue(crossChainToken.hasRole(crossChainToken.MINTER_ROLE(), pool), "pool is not a minter");
        assertTrue(crossChainToken.hasRole(crossChainToken.BURNER_ROLE(), pool), "pool is not a burner");

        TokenPool tokenPool = TokenPool(pool);
        assertEq(address(tokenPool.getToken()), token);
        assertEq(tokenPool.getRmnProxy(), network.rmnProxyAddress);
        assertEq(address(tokenPool.getAdvancedPoolHooks()), address(0), "Example 06 uses no pool hook");
        assertEq(
            tokenPool.getAllowedFinalityConfig(),
            FinalityCodec.WAIT_FOR_FINALITY_FLAG,
            "new pools allow full finality only"
        );

        _assertRegistered(network, token, pool, broadcaster);
    }

    function _assertLinked(
        uint256 fork,
        address pool,
        uint64 remoteChainSelector,
        address remoteToken,
        address remotePool
    ) internal {
        vm.selectFork(fork);
        TokenPool tokenPool = TokenPool(pool);
        assertTrue(tokenPool.isSupportedChain(remoteChainSelector));
        assertEq(abi.decode(tokenPool.getRemoteToken(remoteChainSelector), (address)), remoteToken);
        bytes[] memory remotePools = tokenPool.getRemotePools(remoteChainSelector);
        assertEq(remotePools.length, 1);
        assertEq(abi.decode(remotePools[0], (address)), remotePool);
    }
}
