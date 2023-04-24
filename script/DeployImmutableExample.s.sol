// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {ImmutableExample} from "../src/ImmutableExample.sol";
import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC20.sol";

contract DeployImmutableExample is Script, Helper {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new ImmutableExample(
            IRouterClient(routerEthereumSepolia),
            IERC20(linkEthereumSepolia)
        );

        vm.stopBroadcast();
    }
}
