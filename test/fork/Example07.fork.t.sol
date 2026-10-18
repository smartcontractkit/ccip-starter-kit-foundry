// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CCTForkTest} from "./utils/CCTForkTest.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {DeployCCTLockReleaseTokenAndPool, FundCCTLockBoxLiquidity, Example07} from "script/examples/Example07.s.sol";

import {LockReleaseTokenPool} from "@chainlink/contracts-ccip/contracts/pools/LockReleaseTokenPool.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

/// @notice Example 07 (CCT 02): CrossChainToken + lock box + LockRelease pool on Sepolia -> Amoy.
/// @dev Runs against pinned forks of the live testnets. See `CCTForkTest` for what is and is not simulated.
contract Example07ForkTest is CCTForkTest {
    uint256 internal constant PREMINT = 1_000_000 ether;
    uint256 internal constant DESTINATION_LIQUIDITY = 10 ether;

    DeployCCTLockReleaseTokenAndPool internal deployScript;
    FundCCTLockBoxLiquidity internal fundLockBoxScript;
    Example07 internal configureLaneScript;

    address internal sepoliaToken;
    address internal sepoliaLockBox;
    address internal sepoliaPool;
    address internal amoyToken;
    address internal amoyLockBox;
    address internal amoyPool;

    function setUp() public override {
        super.setUp();
        deployScript = DeployCCTLockReleaseTokenAndPool(_persistent(address(new DeployCCTLockReleaseTokenAndPool())));
        fundLockBoxScript = FundCCTLockBoxLiquidity(_persistent(address(new FundCCTLockBoxLiquidity())));
        configureLaneScript = Example07(_persistent(address(new Example07())));

        (sepoliaToken, sepoliaLockBox, sepoliaPool) = _deploy(sepoliaFork, sepolia);
        (amoyToken, amoyLockBox, amoyPool) = _deploy(amoyFork, amoy);

        vm.selectFork(sepoliaFork);
        configureLaneScript.run(sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        vm.selectFork(amoyFork);
        configureLaneScript.run(amoyPool, sepolia.chainSelector, sepoliaToken, sepoliaPool);
    }

    function test_deploy_createsTokenLockBoxAndPoolAndRegistersThem() public {
        _assertDeployed(sepoliaFork, sepolia, sepoliaToken, sepoliaLockBox, sepoliaPool);
        _assertDeployed(amoyFork, amoy, amoyToken, amoyLockBox, amoyPool);
    }

    function test_configureLane_setsRemoteTokenAndPool() public {
        _assertLinked(sepoliaFork, sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        _assertLinked(amoyFork, amoyPool, sepolia.chainSelector, sepoliaToken, sepoliaPool);
    }

    function test_fundLockBox_movesTokensIntoLockBox() public {
        _fundDestinationLockBox();

        assertEq(_balanceOnFork(amoyFork, amoyToken, amoyLockBox), DESTINATION_LIQUIDITY);
        assertEq(_balanceOnFork(amoyFork, amoyToken, broadcaster), PREMINT - DESTINATION_LIQUIDITY);
    }

    function test_send_locksOnSourceAndReleasesFromDestinationLockBox() public {
        _fundDestinationLockBox();

        _sendDefaultFinalityAndRoute(sepoliaToken, TRANSFER_AMOUNT);

        // Source: tokens move from the sender to the lock box, supply is unchanged (nothing is burned).
        assertEq(_balanceOnFork(sepoliaFork, sepoliaToken, broadcaster), PREMINT - TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(sepoliaFork, sepoliaToken, sepoliaLockBox), TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(sepoliaFork, sepoliaToken), PREMINT);
        // Destination: tokens are released from the lock box to the receiver, supply is unchanged (nothing is minted).
        assertEq(_balanceOnFork(amoyFork, amoyToken, receiver), TRANSFER_AMOUNT);
        assertEq(_balanceOnFork(amoyFork, amoyToken, amoyLockBox), DESTINATION_LIQUIDITY - TRANSFER_AMOUNT);
        assertEq(_supplyOnFork(amoyFork, amoyToken), PREMINT);
    }

    /// @dev The book tells you to fund the destination lock box first. Without liquidity the OffRamp cannot release
    ///      the tokens, and strict routing surfaces the recorded failure.
    function test_send_failsToExecuteWhenDestinationLockBoxIsEmpty() public {
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

        vm.expectPartialRevert(CCIPLocalSimulatorFork.CCIPLocalSimulatorFork__MessageExecutionFailed.selector);
        simulator.switchChainAndRouteMessage(amoyFork);
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    function _deploy(uint256 fork, Register.NetworkDetails memory network)
        internal
        returns (address token, address lockBox, address pool)
    {
        vm.selectFork(fork);
        (token, lockBox, pool) = deployScript.run(
            network.tokenAdminRegistryAddress,
            network.registryModuleOwnerCustomAddress,
            network.rmnProxyAddress,
            network.routerAddress
        );
    }

    /// @dev Book step "fund the Amoy lock box first", needed for Sepolia -> Amoy transfers.
    function _fundDestinationLockBox() internal {
        vm.selectFork(amoyFork);
        fundLockBoxScript.run(amoyToken, amoyLockBox, DESTINATION_LIQUIDITY);
    }

    function _assertDeployed(
        uint256 fork,
        Register.NetworkDetails memory network,
        address token,
        address lockBox,
        address pool
    ) internal {
        vm.selectFork(fork);
        assertEq(IERC20(token).totalSupply(), PREMINT);
        assertEq(IERC20(token).balanceOf(broadcaster), PREMINT);
        assertEq(IERC20(token).balanceOf(lockBox), 0, "lock box starts empty");

        LockReleaseTokenPool tokenPool = LockReleaseTokenPool(pool);
        assertEq(address(tokenPool.getToken()), token);
        assertEq(tokenPool.getLockBox(), lockBox);
        assertEq(tokenPool.getRmnProxy(), network.rmnProxyAddress);

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
