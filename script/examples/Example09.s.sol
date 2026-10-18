// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";

contract Example09SetPoolCCVConfig is Script {
    function run(
        address advancedPoolHook,
        uint64 remoteChainSelector,
        address[] calldata outboundCCVs,
        address[] calldata thresholdOutboundCCVs,
        address[] calldata inboundCCVs,
        address[] calldata thresholdInboundCCVs
    ) external {
        require(advancedPoolHook != address(0), "advancedPoolHook cannot be zero");
        require(remoteChainSelector != 0, "remoteChainSelector cannot be zero");

        console2.log("[INFO] Example09 (CCT 04): Set pool-based CCV requirements on AdvancedPoolHooks");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] AdvancedPoolHooks:", advancedPoolHook);
        console2.log("[INFO] Remote chain selector:", remoteChainSelector);
        console2.log("[INFO] Outbound CCVs count:", outboundCCVs.length);
        for (uint256 i = 0; i < outboundCCVs.length; ++i) {
            console2.log("[INFO] Outbound CCV:", outboundCCVs[i]);
        }
        console2.log("[INFO] Threshold outbound CCVs count:", thresholdOutboundCCVs.length);
        for (uint256 i = 0; i < thresholdOutboundCCVs.length; ++i) {
            console2.log("[INFO] Threshold outbound CCV:", thresholdOutboundCCVs[i]);
        }
        console2.log("[INFO] Inbound CCVs count:", inboundCCVs.length);
        for (uint256 i = 0; i < inboundCCVs.length; ++i) {
            console2.log("[INFO] Inbound CCV:", inboundCCVs[i]);
        }
        console2.log("[INFO] Threshold inbound CCVs count:", thresholdInboundCCVs.length);
        for (uint256 i = 0; i < thresholdInboundCCVs.length; ++i) {
            console2.log("[INFO] Threshold inbound CCV:", thresholdInboundCCVs[i]);
        }

        AdvancedPoolHooks.CCVConfigArg[] memory ccvConfigArgs = new AdvancedPoolHooks.CCVConfigArg[](1);
        ccvConfigArgs[0] = AdvancedPoolHooks.CCVConfigArg({
            remoteChainSelector: remoteChainSelector,
            outboundCCVs: outboundCCVs,
            thresholdOutboundCCVs: thresholdOutboundCCVs,
            inboundCCVs: inboundCCVs,
            thresholdInboundCCVs: thresholdInboundCCVs
        });

        vm.startBroadcast();
        AdvancedPoolHooks(advancedPoolHook).applyCCVConfigUpdates(ccvConfigArgs);
        vm.stopBroadcast();

        AdvancedPoolHooks.CCVConfig memory storedConfig =
            AdvancedPoolHooks(advancedPoolHook).getCCVConfig(remoteChainSelector);
        console2.log("[RESULT] CCV config stored for remote chain selector:", remoteChainSelector);
        console2.log("[RESULT] Outbound CCVs stored:", storedConfig.outboundCCVs.length);
        console2.log("[RESULT] Threshold outbound CCVs stored:", storedConfig.thresholdOutboundCCVs.length);
        console2.log("[RESULT] Inbound CCVs stored:", storedConfig.inboundCCVs.length);
        console2.log("[RESULT] Threshold inbound CCVs stored:", storedConfig.thresholdInboundCCVs.length);
        console2.log("[WARN] A pool-required CCV must exist at the same address on both chains.");
        console2.log("[WARN] Re-run this script with empty lists to clear the config for this lane.");
    }
}

contract Example09SetThresholdAmount is Script {
    function run(address advancedPoolHook, uint256 thresholdAmount) external {
        require(advancedPoolHook != address(0), "advancedPoolHook cannot be zero");

        console2.log("[INFO] Example09 (CCT 04): Set threshold amount for additional CCVs");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] AdvancedPoolHooks:", advancedPoolHook);
        console2.log("[INFO] New threshold amount:", thresholdAmount);

        vm.startBroadcast();
        AdvancedPoolHooks(advancedPoolHook).setThresholdAmount(thresholdAmount);
        vm.stopBroadcast();

        console2.log("[RESULT] Threshold amount is now:", AdvancedPoolHooks(advancedPoolHook).getThresholdAmount());
        console2.log("[WARN] Threshold CCVs are required for transfers at or above the threshold amount.");
    }
}
