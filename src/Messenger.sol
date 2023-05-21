// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

import {OwnerIsCreator} from "chainlink-ccip/contracts/src/v0.8/ccip/OwnerIsCreator.sol";
import {Client} from "chainlink-ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "chainlink-ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

import {IERC20} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC20.sol";

/// @title - A simple messenger contract for sending/receiving string messages across chains
contract MessengerDemo is CCIPReceiver, OwnerIsCreator {
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex);
    error MessageIdNotExist(bytes32 messageId);
    error NothingToWithdraw();
    error FailedToWithdrawEth(address owner, address target, uint256 value);
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        string message,
        uint256 fees
    );

    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        string message
    );

    struct Message {
        uint64 sourceChainSelector;
        address sender;
        string message;
    }

    // keep track of received messages
    bytes32[] public receivedMessages;
    mapping(bytes32 => Message) public messageDetail;

    constructor(address router) CCIPReceiver(router) {}

    /// @notice sends data to receiver on dest chain. Assumes address(this) has sufficient native asset.
    function sendMessage(
        uint64 destinationChainSelector,
        address receiver,
        string calldata message
    ) external returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(message),
            tokenAmounts: new Client.EVMTokenAmount[](0), // empty array indicating we won't send tokens
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(0) // We leave the feeToken empty indicating we'll pay raw native.
        });
        IRouterClient router = IRouterClient(this.getRouter());
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            message,
            fees
        );
        return messageId;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        bytes32 messageId = any2EvmMessage.messageId;
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector;
        address sender = abi.decode(any2EvmMessage.sender, (address));
        string memory message = abi.decode(any2EvmMessage.data, (string));
        receivedMessages.push(messageId);
        Message memory detail = Message(sourceChainSelector, sender, message);
        messageDetail[messageId] = detail;

        emit MessageReceived(messageId, sourceChainSelector, sender, message);
    }

    function getNumberOfReceivedMessages()
        external
        view
        returns (uint256 number)
    {
        return receivedMessages.length;
    }

    function getReceivedMessageDetails(
        bytes32 messageId
    )
        external
        view
        returns (
            uint64 sourceChainSelector,
            address sender,
            string memory message
        )
    {
        Message memory detail = messageDetail[messageId];
        if (detail.sender == address(0)) revert MessageIdNotExist(messageId);
        return (detail.sourceChainSelector, detail.sender, detail.message);
    }

    function getReceivedMessageAt(
        uint256 index
    )
        external
        view
        returns (
            bytes32 messageId,
            uint64 sourceChainSelector,
            address sender,
            string memory message
        )
    {
        if (index >= receivedMessages.length)
            revert IndexOutOfBound(index, receivedMessages.length - 1);
        messageId = receivedMessages[index];
        Message memory detail = messageDetail[messageId];
        return (
            messageId,
            detail.sourceChainSelector,
            detail.sender,
            detail.message
        );
    }

    function withdraw(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }
}
