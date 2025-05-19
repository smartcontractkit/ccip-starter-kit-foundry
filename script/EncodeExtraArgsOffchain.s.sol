// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

/// @title EncodeExtraArgsOffchain
/// @notice This contract is not intended to be deployed on-chain, it is simply a helper contract to encode the extraArgs.
///
/// The purpose of extraArgs is to allow compatibility with future CCIP upgrades.
/// To get this benefit, make sure that extraArgs is mutable in production deployments.
/// This allows you to build it offchain and pass it in a call to a function or store it in a variable that you can update on-demand.
/// Read more here: https://docs.chain.link/ccip/best-practices#using-extraargs
contract EncodeExtraArgsOffchain {
    // Below is a simplistic example (same params for all messages) of using storage to allow for new options without
    // upgrading the dapp. Note that extra args are chain family specific (e.g. gasLimit is EVM specific etc.).
    // and will always be backwards compatible i.e. upgrades are opt-in.
    // Offchain we can compute the V1 extraArgs:
    //    Client.EVMExtraArgsV1 memory extraArgs = Client.EVMExtraArgsV1({gasLimit: 300_000});
    //    bytes memory encodedV1ExtraArgs = Client._argsToBytes(extraArgs);
    // Then later compute V2 extraArgs, for example when allowOutOfOrderExecution was added:
    //    Client.GenericExtraArgsV2 memory extraArgs = Client.GenericExtraArgsV2({gasLimit: 300_000, allowOutOfOrderExecution: true});
    //    bytes memory encodedV2ExtraArgs = Client._argsToBytes(extraArgs);
    // and update storage with the new args.
    // If different options are required for different messages, for example different gas limits,
    // one can simply key based on (chainSelector, messageType) instead of only chainSelector.

    function encodeV1(uint256 gasLimit) public pure returns (bytes memory extraArgsBytes) {
        Client.EVMExtraArgsV1 memory extraArgs = Client.EVMExtraArgsV1({gasLimit: gasLimit});
        extraArgsBytes = Client._argsToBytes(extraArgs);
    }

    function encodeV2(uint256 gasLimit, bool allowOutOfOrderExecution)
        public
        pure
        returns (bytes memory extraArgsBytes)
    {
        Client.GenericExtraArgsV2 memory extraArgs =
            Client.GenericExtraArgsV2({gasLimit: gasLimit, allowOutOfOrderExecution: allowOutOfOrderExecution});
        extraArgsBytes = Client._argsToBytes(extraArgs);
    }
}
