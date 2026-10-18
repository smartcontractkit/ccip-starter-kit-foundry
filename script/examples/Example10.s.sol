// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";
import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";

import {ExamplePolicyEngine} from "../../src/ExamplePolicyEngine.sol";

contract Example10AttachPolicyEngine is Script {
    function run(address advancedPoolHook, address policyEngine) external {
        require(advancedPoolHook != address(0), "advancedPoolHook cannot be zero");
        require(policyEngine != address(0), "policyEngine cannot be zero");

        console2.log("[INFO] Example10 (CCT 05): Attach a policy engine to AdvancedPoolHooks");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] AdvancedPoolHooks:", advancedPoolHook);
        console2.log("[INFO] Policy engine:", policyEngine);

        vm.startBroadcast();
        AdvancedPoolHooks(advancedPoolHook).setPolicyEngine(policyEngine);
        vm.stopBroadcast();

        console2.log("[RESULT] Policy engine attached:", AdvancedPoolHooks(advancedPoolHook).getPolicyEngine());
        console2.log("[WARN] The engine must accept the hook as an attached target (see IPolicyEngine.attach).");
    }
}

contract Example10DetachPolicyEngine is Script {
    function run(address advancedPoolHook) external {
        require(advancedPoolHook != address(0), "advancedPoolHook cannot be zero");

        console2.log("[INFO] Example10 (CCT 05): Detach the policy engine from AdvancedPoolHooks");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] AdvancedPoolHooks:", advancedPoolHook);

        vm.startBroadcast();
        AdvancedPoolHooks(advancedPoolHook).setPolicyEngine(address(0));
        vm.stopBroadcast();

        console2.log("[RESULT] Policy engine is now:", AdvancedPoolHooks(advancedPoolHook).getPolicyEngine());
    }
}

/// @notice Deploys the minimal example engine from `src/ExamplePolicyEngine.sol`.
/// @dev For production-grade policy engines, use Chainlink ACE (https://chainlink.tech/ace).
contract Example10DeployExamplePolicyEngine is Script {
    function run() external returns (address policyEngine) {
        console2.log("[INFO] Example10 (CCT 05): Deploy the minimal example policy engine");
        console2.log("[INFO] Source chain ID:", block.chainid);

        vm.startBroadcast();
        ExamplePolicyEngine engine = new ExamplePolicyEngine();
        vm.stopBroadcast();

        policyEngine = address(engine);
        console2.log("[RESULT] Example policy engine deployed:", policyEngine);
        console2.log("[WARN] This engine is example code, not audited, not for production. Use Chainlink ACE instead.");
    }
}
