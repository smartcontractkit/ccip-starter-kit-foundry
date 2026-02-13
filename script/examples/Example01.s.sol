// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {BasicMessageSender} from "src/BasicMessageSender.sol";
import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract DeployBasicMessageSender is Script {
    function run(address ccipRouter, address linkToken) external {
        vm.startBroadcast();

        BasicMessageSender basicMessageSender = new BasicMessageSender(ccipRouter, linkToken);
        console2.log(
            "Basic Message Sender deployed to Chain ID: ",
            block.chainid,
            ", with address: ",
            address(basicMessageSender)
        );

        vm.stopBroadcast();
    }
}

contract Example01 is Script {
    function run(
        address payable basicMessageSender,
        uint64 destinationChainSelector,
        address receiver,
        address tokenToSend,
        uint256 amount
    ) external {
        console2.log(
            "Test scenario 1: Sending CCIP-BnM tokens to EOA, paying fees in native, ExtraArgsV1, gas limit 200_000"
        );

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        uint256 gasLimit = 200_000;
        bytes memory extraArgs = extraArgsEncoder.encodeV1(gasLimit); // Legacy

        Client.EVMTokenAmount[] memory tokensToSend = new Client.EVMTokenAmount[](1);
        tokensToSend[0] = Client.EVMTokenAmount({token: tokenToSend, amount: amount});

        vm.startBroadcast();

        IERC20(tokenToSend).approve(basicMessageSender, amount);

        // Fund sender contract
        (bool sent,) = basicMessageSender.call{value: 0.1 ether}("");
        require(sent, "Funding failed");

        bytes32 messageId = BasicMessageSender(basicMessageSender).send(
            destinationChainSelector, receiver, "", tokensToSend, extraArgs, address(0)
        );

        console2.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console2.logBytes32(messageId);

        // // Refund leftover, must be called by BasicMessageSender deployer
        // BasicMessageSender(basicMessageSender).withdraw(msg.sender);

        vm.stopBroadcast();
    }
}
