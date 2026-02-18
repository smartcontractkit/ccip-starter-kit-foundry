// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {BasicMessageSender} from "src/BasicMessageSender.sol";
import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
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
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        address tokenToSend,
        uint256 amount,
        uint32 gasLimit,
        uint16 blockConfirmations,
        address feeTokenAddress
    ) external returns (bytes32 messageId) {
        require(
            blockConfirmations > 0, "blockConfirmations == 0 means default finality; use > 0 for Faster Than Finality"
        );
        require(tokenToSend != address(0), "token cannot be zero");
        require(amount > 0, "amount must be > 0");

        console2.log("[INFO] Example01: Token transfer + ExtraArgsV3 + Faster Than Finality (EOA sender)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Source router:", sourceRouter);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Receiver:", receiver);
        console2.log("[INFO] Token:", tokenToSend);
        console2.log("[INFO] Amount:", amount);
        console2.log("[INFO] Gas limit:", gasLimit);
        console2.log("[INFO] Block confirmations:", blockConfirmations);
        console2.log("[INFO] Fee token:", feeTokenAddress);
        console2.log("[WARN] Use gasLimit 0 if the receiver is an EOA (token-only transfer).");
        console2.log("[WARN] Executor may enforce a minimum block confirmation value and revert if too low.");
        console2.log("[WARN] If requested confirmations exceed chain finality, default finality is used.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        bytes memory extraArgs = extraArgsEncoder.encodeV3Basic(gasLimit, blockConfirmations);

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
