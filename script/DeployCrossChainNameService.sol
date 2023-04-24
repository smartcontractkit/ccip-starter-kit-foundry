// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {Helper} from "./Helper.sol";
import {CrossChainNameServiceLookup} from "../src/CrossChainNameServiceLookup.sol";
import {CrossChainNameServiceRegister} from "../src/CrossChainNameServiceRegister.sol";
import {CrossChainNameServiceReceiver} from "../src/CrossChainNameServiceReceiver.sol";

contract DeployCrossChainNameServiceSourceChain is Script, Helper {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossChainNameServiceLookup lookupEthereumSepolia = new CrossChainNameServiceLookup();

        CrossChainNameServiceRegister register = new CrossChainNameServiceRegister(
                routerEthereumSepolia,
                address(lookupEthereumSepolia)
            );

        lookupEthereumSepolia.setCrossChainNameServiceAddress(
            address(register)
        );

        vm.stopBroadcast();
    }
}

// RUN ON THE NEW DESTINATION CHAIN
contract DeployCrossChainNameServiceDestinationChain01 is Script, Helper {
    function run(address router) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossChainNameServiceLookup lookup = new CrossChainNameServiceLookup();

        CrossChainNameServiceReceiver receiver = new CrossChainNameServiceReceiver(
                router,
                address(lookup),
                chainIdEthereumSepolia
            );

        lookup.setCrossChainNameServiceAddress(address(receiver));

        vm.stopBroadcast();
    }
}

// RUN ON ETHEREUM SEPOLIA
contract DeployCrossChainNameServiceDestinationChain02 is Script, Helper {
    function run(
        address registerEthereumSepoliaAddress,
        uint64 destinationChainId,
        address destinationCcnsReceiverAddress,
        bool strict,
        uint256 gasLimit
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        CrossChainNameServiceRegister registerEthereumSepolia = CrossChainNameServiceRegister(
                registerEthereumSepoliaAddress
            );

        registerEthereumSepolia.enableChain(
            destinationChainId,
            destinationCcnsReceiverAddress,
            strict,
            gasLimit
        );

        vm.stopBroadcast();
    }
}
