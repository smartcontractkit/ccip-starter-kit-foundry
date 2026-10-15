// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {CCIPLocalRouter} from "@chainlink/local/src/ccip/CCIPLocalRouter.sol";

/// @notice Shared setup for tests that run the book's example scripts against the Chainlink Local no-fork simulator.
/// @dev The example scripts wrap their calls in `vm.startBroadcast()` (no argument), so inside a test the transaction
///      sender is `DEFAULT_SENDER`. That account is exposed as `broadcaster` and must hold the tokens/ETH the script spends.
abstract contract LocalSimulatorTest is Test {
    CCIPLocalSimulator internal simulator;
    CCIPLocalRouter internal router;
    LinkToken internal link;
    BurnMintERC677Helper internal ccipBnM;
    uint64 internal chainSelector;
    address internal broadcaster = DEFAULT_SENDER;

    function setUp() public virtual {
        simulator = new CCIPLocalSimulator();
        (uint64 selector, IRouterClient sourceRouter,,, LinkToken linkToken, BurnMintERC677Helper bnm,) =
            simulator.configuration();
        chainSelector = selector;
        router = CCIPLocalRouter(address(sourceRouter));
        link = linkToken;
        ccipBnM = bnm;
    }
}
