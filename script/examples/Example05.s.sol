// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract Example05 is Script {
    function run(
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        string calldata messageText,
        uint32 gasLimit,
        uint16 blockConfirmations,
        address feeTokenAddress
    ) external returns (bytes32 messageId) {
        require(sourceRouter != address(0), "sourceRouter cannot be zero");
        require(receiver != address(0), "receiver cannot be zero");
        require(bytes(messageText).length > 0, "messageText cannot be empty");
        require(gasLimit > 0, "gasLimit must be > 0 for contract callback");

        console2.log("[INFO] Example05: ExtraArgsV3 no-execution-tag (manual execution path)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Source router:", sourceRouter);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Receiver:", receiver);
        console2.log("[INFO] Message:", messageText);
        console2.log("[INFO] Gas limit:", gasLimit);
        console2.log("[INFO] Block confirmations:", blockConfirmations);
        console2.log("[INFO] Fee token:", feeTokenAddress);
        console2.log("[INFO] Executor tag: NO_EXECUTION_ADDRESS (disable automatic execution)");
        console2.log("[WARN] Message delivery stays pending until manually executed.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        address noExecutionAddress = extraArgsEncoder.getNoExecutionAddress();
        bytes memory extraArgs = extraArgsEncoder.encodeV3(
            gasLimit, blockConfirmations, new address[](0), new bytes[](0), noExecutionAddress, "", "", ""
        );

        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(messageText),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: extraArgs,
            feeToken: feeTokenAddress
        });

        uint256 fee = IRouterClient(sourceRouter).getFee(destinationChainSelector, ccipMessage);
        console2.log("[INFO] Quoted fee:", fee);

        vm.startBroadcast();
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
