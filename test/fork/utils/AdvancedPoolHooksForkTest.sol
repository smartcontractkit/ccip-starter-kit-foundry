// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {CCTForkTest} from "./CCTForkTest.sol";
import {Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook, Example08} from "script/examples/Example08.s.sol";

import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

/// @notice Shared setup for the AdvancedPoolHooks fork tests (Example08-10): deploys a CCT BurnMint
///         token + hook + pool on both chains and links the lanes, so each test file only adds the
///         hook feature it covers (allowlist, pool CCVs, policy engine).
/// @dev The deploy script seeds the hook allowlist with the broadcaster, the only account that sends
///      in these tests, so allowlist checks pass by default.
abstract contract AdvancedPoolHooksForkTest is CCTForkTest {
    uint256 internal constant PREMINT = 1_000_000 ether;
    /// @dev The value the book passes for `thresholdAmountForAdditionalCCVs`.
    uint256 internal constant THRESHOLD = 1;

    DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook internal deployScript;
    Example08 internal configureLaneScript;

    address internal sepoliaToken;
    address internal sepoliaHook;
    address internal sepoliaPool;
    address internal amoyToken;
    address internal amoyHook;
    address internal amoyPool;

    function setUp() public virtual override {
        super.setUp();
        deployScript = DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook(
            _persistent(address(new DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook()))
        );
        configureLaneScript = Example08(_persistent(address(new Example08())));

        (sepoliaToken, sepoliaHook, sepoliaPool) = _deploy(sepoliaFork, sepolia);
        (amoyToken, amoyHook, amoyPool) = _deploy(amoyFork, amoy);

        vm.selectFork(sepoliaFork);
        configureLaneScript.run(sepoliaPool, amoy.chainSelector, amoyToken, amoyPool);
        vm.selectFork(amoyFork);
        configureLaneScript.run(amoyPool, sepolia.chainSelector, sepoliaToken, sepoliaPool);
    }

    // ----------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------

    function _deploy(uint256 fork, Register.NetworkDetails memory network)
        internal
        returns (address token, address hook, address pool)
    {
        vm.selectFork(fork);
        (token, hook, pool) = deployScript.run(
            network.tokenAdminRegistryAddress,
            network.registryModuleOwnerCustomAddress,
            network.rmnProxyAddress,
            network.routerAddress,
            THRESHOLD
        );
    }

    /// @dev Asserts the deployed token/hook/pool state shared by Example08-10.
    function _assertDeployed(
        uint256 fork,
        Register.NetworkDetails memory network,
        address token,
        address hook,
        address pool
    ) internal virtual {
        vm.selectFork(fork);
        assertEq(IERC20(token).balanceOf(broadcaster), PREMINT);

        TokenPool tokenPool = TokenPool(pool);
        assertEq(address(tokenPool.getToken()), token);
        assertEq(address(tokenPool.getAdvancedPoolHooks()), hook, "hook is not attached to the pool");

        _assertRegistered(network, token, pool, broadcaster);
    }
}
