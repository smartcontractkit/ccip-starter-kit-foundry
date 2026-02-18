// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {BasicMessageSender} from "src/BasicMessageSender.sol";
import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract DeployBasicMessageSender is Script {
    function run(address ccipRouter, address linkToken) external returns (address senderAddress) {
        vm.startBroadcast();

        BasicMessageSender basicMessageSender = new BasicMessageSender(ccipRouter, linkToken);
        senderAddress = address(basicMessageSender);
        console2.log(
            "[RESULT] BasicMessageSender deployed to chain ID:",
            block.chainid,
            "with address:",
            senderAddress
        );

        vm.stopBroadcast();
    }
}

contract Example04 is Script {
    struct Example04Config {
        address basicMessageSender;
        address sourceRouter;
        uint64 destinationChainSelector;
        address receiver;
        string messageText;
        address tokenToSend;
        uint256 amount;
        uint32 gasLimit;
    }

    function _buildMessage(
        address receiver,
        string memory messageText,
        address tokenToSend,
        uint256 amount,
        bytes memory extraArgs
    ) internal pure returns (Client.EVM2AnyMessage memory ccipMessage, Client.EVMTokenAmount[] memory tokenAmounts) {
        tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSend, amount: amount});

        ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(messageText),
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: address(0)
        });
    }

    function _run(Example04Config memory cfg) internal returns (bytes32 messageId) {
        require(cfg.basicMessageSender != address(0), "basicMessageSender cannot be zero");
        require(cfg.sourceRouter != address(0), "sourceRouter cannot be zero");
        require(cfg.receiver != address(0), "receiver cannot be zero");
        require(bytes(cfg.messageText).length > 0, "messageText cannot be empty");
        require(cfg.tokenToSend != address(0), "token cannot be zero");
        require(cfg.amount > 0, "amount must be > 0");
        require(cfg.gasLimit > 0, "gasLimit must be > 0 for contract callback");

        uint16 blockConfirmations = 0;

        console2.log("[INFO] Example04: Programmable token transfer (data + token) + default finality (sender contract)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Sender contract:", cfg.basicMessageSender);
        console2.log("[INFO] Source router:", cfg.sourceRouter);
        console2.log("[INFO] Destination selector:", cfg.destinationChainSelector);
        console2.log("[INFO] Receiver:", cfg.receiver);
        console2.log("[INFO] Message:", cfg.messageText);
        console2.log("[INFO] Token:", cfg.tokenToSend);
        console2.log("[INFO] Amount:", cfg.amount);
        console2.log("[INFO] Gas limit:", cfg.gasLimit);
        console2.log("[INFO] Block confirmations:", blockConfirmations, "(default finality)");
        console2.log("[INFO] Fee token: native");
        console2.log("[INFO] This example funds sender contract with exact quoted fee before send.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        bytes memory extraArgs = extraArgsEncoder.encodeV3Basic(cfg.gasLimit, blockConfirmations);

        (Client.EVM2AnyMessage memory ccipMessage, Client.EVMTokenAmount[] memory tokenAmounts) =
            _buildMessage(cfg.receiver, cfg.messageText, cfg.tokenToSend, cfg.amount, extraArgs);
        uint256 fee = IRouterClient(cfg.sourceRouter).getFee(cfg.destinationChainSelector, ccipMessage);
        console2.log("[INFO] Quoted fee:", fee);
        console2.log("[INFO] Funding sender contract with exact quoted fee (no refund pattern in this example)");

        vm.startBroadcast();
        IERC20(cfg.tokenToSend).approve(cfg.basicMessageSender, cfg.amount);

        (bool funded,) = payable(cfg.basicMessageSender).call{value: fee}("");
        require(funded, "fee funding transfer failed");

        messageId = BasicMessageSender(payable(cfg.basicMessageSender)).send(
            cfg.destinationChainSelector, cfg.receiver, abi.encode(cfg.messageText), tokenAmounts, extraArgs, address(0)
        );
        vm.stopBroadcast();

        console2.log("[RESULT] Monitor message status at https://ccip.chain.link using message ID:");
        console2.logBytes32(messageId);
    }

    function run(
        address basicMessageSender,
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        string calldata messageText,
        address tokenToSend,
        uint256 amount,
        uint32 gasLimit
    ) external returns (bytes32 messageId) {
        Example04Config memory cfg = Example04Config({
            basicMessageSender: basicMessageSender,
            sourceRouter: sourceRouter,
            destinationChainSelector: destinationChainSelector,
            receiver: receiver,
            messageText: messageText,
            tokenToSend: tokenToSend,
            amount: amount,
            gasLimit: gasLimit
        });

        messageId = _run(cfg);
    }
}
