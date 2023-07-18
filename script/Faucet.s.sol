// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";

interface ICCIPToken {
    function drip(address to) external;
}

contract Faucet is Script, Helper {
    function run(SupportedNetworks network) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);
        address senderAddress = vm.addr(senderPrivateKey);

        (address ccipBnm, address ccipLnm) = getDummyTokensFromNetwork(network);

        ICCIPToken(ccipBnm).drip(senderAddress);

        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            ICCIPToken(ccipLnm).drip(senderAddress);
        }

        vm.stopBroadcast();
    }
}
