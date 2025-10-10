// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from
    "@openzeppelin/contracts@4.8.3/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@openzeppelin/contracts@4.8.3/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {Withdraw} from "./utils/Withdraw.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract BasicTokenSender is Withdraw {
    using SafeERC20 for IERC20;

    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;
    address immutable i_link;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link) {
        i_router = router;
        i_link = link;
    }

    receive() external payable {}

    function send(
        uint64 destinationChainSelector,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails,
        PayFeesIn payFeesIn
    ) external {
        uint256 length = tokensToSendDetails.length;

        for (uint256 i = 0; i < length;) {
            IERC20(tokensToSendDetails[i].token).safeTransferFrom(
                msg.sender, address(this), tokensToSendDetails[i].amount
            );
            IERC20(tokensToSendDetails[i].token).approve(i_router, tokensToSendDetails[i].amount);

            unchecked {
                ++i;
            }
        }

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(Client.GenericExtraArgsV2({gasLimit: 0, allowOutOfOrderExecution: true})),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(destinationChainSelector, message);

        bytes32 messageId;

        if (payFeesIn == PayFeesIn.LINK) {
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(destinationChainSelector, message);
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(destinationChainSelector, message);
        }

        emit MessageSent(messageId);
    }
}
