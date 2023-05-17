// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "chainlink-ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC165} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC165.sol";

import {ICrossChainNameServiceLookup} from "./ICrossChainNameServiceLookup.sol";

/**
 * EDUCATIONAL EXAMPLE, DO NOT USE IN PRODUCTION
 */
contract CrossChainNameServiceReceiver is IAny2EVMMessageReceiver, IERC165 {
    IRouterClient public immutable i_router;
    ICrossChainNameServiceLookup public immutable i_lookup;
    uint64 public immutable i_sourceChainId;

    error InvalidRouter(address router);
    error InvalidSourceChain(uint64 chainId);

    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }

    modifier onlyFromSourceChain(uint64 chainId) {
        if (chainId != i_sourceChainId) revert InvalidSourceChain(chainId);
        _;
    }

    constructor(address router, address lookup, uint64 sourceChainId) {
        i_router = IRouterClient(router);
        i_lookup = ICrossChainNameServiceLookup(lookup);
        i_sourceChainId = sourceChainId;
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external override onlyRouter onlyFromSourceChain(message.sourceChainSelector) {
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
}
