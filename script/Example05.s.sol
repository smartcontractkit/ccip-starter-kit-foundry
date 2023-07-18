// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {BasicMessageSender} from "../src/BasicMessageSender.sol";

contract DeployBasicMessageSender is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(source);

        BasicMessageSender basicMessageSender = new BasicMessageSender(
            router,
            link
        );

        console.log(
            "BasicMessageSender contract deployed on ",
            networks[source],
            "with address: ",
            address(basicMessageSender)
        );

        vm.stopBroadcast();
    }
}

contract SendMessage is Script, Helper {
    function run(
        address payable sender,
        SupportedNetworks destination,
        address receiver,
        string memory message,
        BasicMessageSender.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        bytes32 messageId = BasicMessageSender(sender).send(
            destinationChainId,
            receiver,
            message,
            payFeesIn
        );

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
}
