// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "chainlink-ccip/contracts/src/v0.8/ccip/models/Client.sol";
import {IERC165} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC165.sol";

import {ICrossChainNameServiceLookup} from "./ICrossChainNameServiceLookup.sol";

contract CrossChainNameServiceReceiver is IAny2EVMMessageReceiver, IERC165 {
    IRouterClient private immutable i_router;
    ICrossChainNameServiceLookup private immutable i_lookup;
    // uint256 private commitReveal = 1;

    uint64 constant SEPOLIA_CHAIN_ID = 11155111;

    error InvalidRouter(address router);
    error InvalidSourceChain(uint64 chainId);

    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }

    modifier onlyFromSepolia(uint64 chainId) {
        if (chainId != SEPOLIA_CHAIN_ID) revert InvalidSourceChain(chainId);
        _;
    }

    constructor(address router, address lookup) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = IRouterClient(router);
        i_lookup = ICrossChainNameServiceLookup(lookup);
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external override onlyRouter onlyFromSepolia(message.sourceChainId) {
        // commitReveal = 1;
        (string memory _name, address _address) = abi.decode(
            message.data,
            (string, address)
        );

        i_lookup.register(_name, _address);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getRouterAddress() external view returns (address) {
        return address(i_router);
    }
}
