// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";

import {OwnerIsCreator} from "chainlink-ccip/contracts/src/v0.8/ccip/OwnerIsCreator.sol";
import {Client} from "chainlink-ccip/contracts/src/v0.8/ccip/models/Client.sol";
import {CCIPReceiver} from "chainlink-ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

import {IERC20} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC20.sol";

/// @title PingPongDemo - A simple ping-pong contract for demonstrating cross-chain communication
contract PingPongDemo is CCIPReceiver, OwnerIsCreator {
    event Ping(uint256 pingPongCount);
    event Pong(uint256 pingPongCount);

    // The chain ID of the counterpart ping pong contract
    uint64 private s_counterpartChainId;
    // The contract address of the counterpart ping pong contract
    address private s_counterpartAddress;

    // Pause ping-ponging
    bool private s_isPaused;
    IERC20 private s_feeToken;

    constructor(address router, IERC20 feeToken) CCIPReceiver(router) {
        s_isPaused = false;
        s_feeToken = feeToken;
        s_feeToken.approve(address(router), 2 ** 256 - 1);
    }

    function setCounterpart(
        uint64 counterpartChainId,
        address counterpartAddress
    ) external onlyOwner {
        s_counterpartChainId = counterpartChainId;
        s_counterpartAddress = counterpartAddress;
    }

    function startPingPong() external onlyOwner {
        s_isPaused = false;
        _respond(1);
    }

    function _respond(uint256 pingPongCount) private {
        if (pingPongCount & 1 == 1) {
            emit Ping(pingPongCount);
        } else {
            emit Pong(pingPongCount);
        }

        bytes memory data = abi.encode(pingPongCount);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_counterpartAddress),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            feeToken: address(s_feeToken)
        });
        IRouterClient(getRouter()).ccipSend(s_counterpartChainId, message);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        uint256 pingPongCount = abi.decode(message.data, (uint256));
        if (!s_isPaused) {
            _respond(pingPongCount + 1);
        }
    }

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    function getCounterpartChainId() external view returns (uint64) {
        return s_counterpartChainId;
    }

    function setCounterpartChainId(uint64 chainId) external onlyOwner {
        s_counterpartChainId = chainId;
    }

    function getCounterpartAddress() external view returns (address) {
        return s_counterpartAddress;
    }

    function setCounterpartAddress(address addr) external onlyOwner {
        s_counterpartAddress = addr;
    }

    function isPaused() external view returns (bool) {
        return s_isPaused;
    }

    function setPaused(bool pause) external onlyOwner {
        s_isPaused = pause;
    }
}
