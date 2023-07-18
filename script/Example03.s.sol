// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {BasicTokenSender} from "../src/BasicTokenSender.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract DeployBasicTokenSender is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (address router, address linkToken, , ) = getConfigFromNetwork(source);

        BasicTokenSender basicTokenSender = new BasicTokenSender(
            router,
            linkToken
        );

        console.log(
            "Basic Token Sender deployed on ",
            networks[source],
            "with address: ",
            address(basicTokenSender)
        );

        vm.stopBroadcast();
    }
}

contract SendBatch is Script, Helper {
    function run(
        SupportedNetworks destination,
        address payable basicTokenSenderAddres,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails,
        BasicTokenSender.PayFeesIn payFeesIn
    ) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        BasicTokenSender(basicTokenSenderAddres).send(
            destinationChainId,
            receiver,
            tokensToSendDetails,
            payFeesIn
        );

        vm.stopBroadcast();
    }
}
