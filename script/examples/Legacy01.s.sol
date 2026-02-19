// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract Legacy01 is Script {
    function run(
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        address tokenToSend,
        uint256 amount,
        uint256 gasLimit,
        address feeTokenAddress
    ) external returns (bytes32 messageId) {
        require(sourceRouter != address(0), "sourceRouter cannot be zero");
        require(receiver != address(0), "receiver cannot be zero");
        require(tokenToSend != address(0), "token cannot be zero");
        require(amount > 0, "amount must be > 0");

        console2.log("[INFO] Legacy01: ExtraArgsV1 token transfer (EOA sender)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Source router:", sourceRouter);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Receiver:", receiver);
        console2.log("[INFO] Token:", tokenToSend);
        console2.log("[INFO] Amount:", amount);
        console2.log("[INFO] Gas limit:", gasLimit);
        console2.log("[INFO] Fee token:", feeTokenAddress);
        console2.log("[WARN] Use gasLimit 0 if receiver is an EOA.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        bytes memory extraArgs = extraArgsEncoder.encodeV1(gasLimit);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSend, amount: amount});

        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: feeTokenAddress
        });

        uint256 fee = IRouterClient(sourceRouter).getFee(destinationChainSelector, ccipMessage);
        console2.log("[INFO] Quoted fee:", fee);

        vm.startBroadcast();
        IERC20(tokenToSend).approve(sourceRouter, amount);
        if (feeTokenAddress == address(0)) {
            console2.log("[INFO] Sending message, paying CCIP fee in native token");
            messageId = IRouterClient(sourceRouter).ccipSend{value: fee}(destinationChainSelector, ccipMessage);
        } else {
            console2.log("[INFO] Sending message, paying CCIP fee in LINK");
            IERC20(feeTokenAddress).approve(sourceRouter, fee);
            messageId = IRouterClient(sourceRouter).ccipSend(destinationChainSelector, ccipMessage);
        }
        vm.stopBroadcast();

        console2.log("[RESULT] Monitor message status at https://ccip.chain.link using message ID:");
        console2.logBytes32(messageId);
    }
}
