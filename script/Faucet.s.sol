// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";

interface BurnMintERC20WithDrip {
    // Gives one full token to any given address.
    function drip(address to) external;
}

contract Faucet is Script {
    function run(address ccipBnM) external {
        vm.startBroadcast();

        (, address broadcaster,) = vm.readCallers();
        BurnMintERC20WithDrip(ccipBnM).drip(broadcaster);
        console2.log("[INFO] Minting 1 CCIP-BnM token (", ccipBnM, ") to address:", broadcaster);

        vm.stopBroadcast();
    }
}
