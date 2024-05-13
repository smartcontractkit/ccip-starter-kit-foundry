// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract CCIPTokenTransfer is Script, Helper {
    function run(
        SupportedNetworks source,
        SupportedNetworks destination,
        address receiver,
        address tokenToSend,
        uint256 amount,
        PayFeesIn payFeesIn
    ) external returns (bytes32 messageId) {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (address sourceRouter, address linkToken, , ) = getConfigFromNetwork(
            source
        );
        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        IERC20(tokenToSend).approve(sourceRouter, amount);

        Client.EVMTokenAmount[]
            memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails = Client
            .EVMTokenAmount({token: tokenToSend, amount: amount});

        tokensToSendDetails[0] = tokenToSendDetails;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: payFeesIn == PayFeesIn.LINK ? linkToken : address(0)
        });

        uint256 fees = IRouterClient(sourceRouter).getFee(
            destinationChainId,
            message
        );

        if (payFeesIn == PayFeesIn.LINK) {
            IERC20(linkToken).approve(sourceRouter, fees);
            messageId = IRouterClient(sourceRouter).ccipSend(
                destinationChainId,
                message
            );
        } else {
            messageId = IRouterClient(sourceRouter).ccipSend{value: fees}(
                destinationChainId,
                message
            );
        }

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
}
