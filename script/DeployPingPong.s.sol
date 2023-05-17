// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {PingPongDemo} from "../src/PingPongDemo.sol";
import {IERC20} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC20.sol";

// forge script ./script/DeployPingPong.s.sol:DeployPingPongStep01 --fork-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast -vvvv
contract DeployPingPongStep01 is Script, Helper {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PingPongDemo pingPongEthereumSepolia = new PingPongDemo(
            routerEthereumSepolia,
            IERC20(linkEthereumSepolia)
        );

        console.log(
            "Ping Pong Ethereum Sepolia Address (Paste it to the next script): ",
            address(pingPongEthereumSepolia)
        );

        vm.stopBroadcast();
    }
}

// forge script ./script/DeployPingPong.s.sol:DeployPingPongStep02 --fork-url $AVALANCHE_FUJI_RPC_URL --broadcast --sig "run(address)" -- <PASS_PING_PONG_ETHEREUM_SEPOLIA_ADDRESS_HERE> -vvvv
contract DeployPingPongStep02 is Script, Helper {
    function run(address pingPongEthereumSepoliaAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PingPongDemo pingPongAvalancheFuji = new PingPongDemo(
            routerAvalancheFuji,
            IERC20(linkAvalancheFuji)
        );

        pingPongAvalancheFuji.setCounterpart(
            chainIdEthereumSepolia,
            pingPongEthereumSepoliaAddress
        );

        console.log(
            "Ping Pong Avalanche Fuji Address (Paste it to the next script): ",
            address(pingPongAvalancheFuji)
        );

        vm.stopBroadcast();
    }
}

// forge script ./script/DeployPingPong.s.sol:DeployPingPongStep03 --fork-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast --sig "run(address,address)" -- <PASS_PING_PONG_ETHEREUM_SEPOLIA_ADDRESS_HERE> <PASS_PING_PONG_AVALANCHE_FUJI_ADDRESS_HERE> -vvvv
contract DeployPingPongStep03 is Script, Helper {
    function run(
        address pingPongEthereumSepoliaAddress,
        address pingPongAvalancheFujiAddress
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PingPongDemo pingPongEthereumSepolia = PingPongDemo(
            pingPongEthereumSepoliaAddress
        );

        pingPongEthereumSepolia.setCounterpart(
            chainIdAvalancheFuji,
            pingPongAvalancheFujiAddress
        );

        vm.stopBroadcast();
    }
}
