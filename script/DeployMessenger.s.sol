// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {MessengerDemo} from "../src/Messenger.sol";

//Example Sepolia:  forge script ./script/DeployMessenger.s.sol:DeployMessenger -vvv --broadcast  --rpc-url ethereumSepolia  --sig "run(uint8)" -- 0
// Example Fuji: forge script ./script/DeployMessenger.s.sol:DeployMessenger -vvv --broadcast  --rpc-url avalancheFuji  --sig "run(uint8)" -- 2

contract DeployMessenger is Script, Helper {
    function run(SupportedNetworks network) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        (address router, , , ) = getConfigFromNetwork(network);
        vm.startBroadcast(deployerPrivateKey);

        MessengerDemo messenger = new MessengerDemo(router);

        console.log("Messenger address: ", address(messenger));

        vm.stopBroadcast();
    }
}
