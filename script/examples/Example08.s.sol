// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {BaseERC20} from "@chainlink/contracts-ccip/contracts/tokens/BaseERC20.sol";
import {CrossChainToken} from "@chainlink/contracts-ccip/contracts/tokens/CrossChainToken.sol";
import {AdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/pools/AdvancedPoolHooks.sol";
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/contracts/pools/BurnMintTokenPool.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/interfaces/ITokenAdminRegistry.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/contracts/interfaces/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";
import {AuthorizedCallers} from "@chainlink/contracts/src/v0.8/shared/access/AuthorizedCallers.sol";

contract DeployCCTBurnMintTokenAndPoolWithAdvancedPoolHook is Script {
    string internal constant TOKEN_NAME = "TestToken";
    string internal constant TOKEN_SYMBOL = "TEST";
    uint8 internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_PREMINT = 1_000_000 ether;
    uint256 internal constant TOKEN_MAX_SUPPLY = 100_000_000 ether;

    function run(
        address tokenAdminRegistry,
        address registryModuleOwnerCustom,
        address armProxy,
        address router,
        uint256 thresholdAmountForAdditionalCCVs
    )
        external
        returns (address token, address advancedPoolHook, address pool)
    {
        require(tokenAdminRegistry != address(0), "tokenAdminRegistry cannot be zero");
        require(registryModuleOwnerCustom != address(0), "registryModuleOwnerCustom cannot be zero");
        require(armProxy != address(0), "armProxy cannot be zero");
        require(router != address(0), "router cannot be zero");

        console2.log("[INFO] Example08 (CCT 03): Deploy CrossChainToken + AdvancedPoolHooks + BurnMint pool");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] TokenAdminRegistry:", tokenAdminRegistry);
        console2.log("[INFO] RegistryModuleOwnerCustom:", registryModuleOwnerCustom);
        console2.log("[INFO] ARM proxy:", armProxy);
        console2.log("[INFO] Router:", router);
        console2.log("[INFO] Token name:", TOKEN_NAME);
        console2.log("[INFO] Token symbol:", TOKEN_SYMBOL);
        console2.log("[INFO] Token decimals:", uint256(TOKEN_DECIMALS));
        console2.log("[INFO] Token preMint:", TOKEN_PREMINT);
        console2.log("[INFO] Token maxSupply:", TOKEN_MAX_SUPPLY);
        console2.log("[INFO] Hook thresholdAmountForAdditionalCCVs:", thresholdAmountForAdditionalCCVs);

        vm.startBroadcast();
        (, address broadcaster,) = vm.readCallers();

        // Enable allowlist on the hook and seed it with broadcaster for immediate testing UX.
        address[] memory allowlist = new address[](1);
        allowlist[0] = broadcaster;
        address[] memory authorizedCallers = new address[](0);
        AdvancedPoolHooks advancedPoolHooks = new AdvancedPoolHooks(
            allowlist,
            thresholdAmountForAdditionalCCVs,
            address(0), // policyEngine disabled
            authorizedCallers // authorized callers disabled
        );

        BaseERC20.ConstructorParams memory tokenParams = BaseERC20.ConstructorParams({
            name: TOKEN_NAME,
            symbol: TOKEN_SYMBOL,
            maxSupply: TOKEN_MAX_SUPPLY,
            preMint: TOKEN_PREMINT,
            preMintRecipient: broadcaster,
            decimals: TOKEN_DECIMALS,
            ccipAdmin: broadcaster
        });
        CrossChainToken tokenContract = new CrossChainToken(tokenParams, broadcaster, broadcaster);
        BurnMintTokenPool poolContract = new BurnMintTokenPool(
            IBurnMintERC20(address(tokenContract)), TOKEN_DECIMALS, address(advancedPoolHooks), armProxy, router
        );

        // AdvancedPoolHooks requires the pool to be an authorized caller for preflight/postflight checks.
        address[] memory addedCallers = new address[](1);
        addedCallers[0] = address(poolContract);
        advancedPoolHooks.applyAuthorizedCallerUpdates(
            AuthorizedCallers.AuthorizedCallerArgs({addedCallers: addedCallers, removedCallers: new address[](0)})
        );

        // Token pool needs mint and burn roles on the local token.
        tokenContract.grantMintAndBurnRoles(address(poolContract));

        // Register token admin and attach pool in TokenAdminRegistry (CrossChainToken uses getCCIPAdmin, not owner()).
        RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaGetCCIPAdmin(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).setPool(address(tokenContract), address(poolContract));

        vm.stopBroadcast();

        token = address(tokenContract);
        advancedPoolHook = address(advancedPoolHooks);
        pool = address(poolContract);

        console2.log("[RESULT] Local CrossChainToken deployed:", token);
        console2.log("[RESULT] Local AdvancedPoolHooks deployed:", advancedPoolHook);
        console2.log("[RESULT] Local CCT BurnMint pool deployed:", pool);
        console2.log("[RESULT] Authorized caller added to hook:", pool);
        console2.log("[WARN] Remote chain configuration is not done yet.");
        console2.log("[WARN] Run Example08.run on both chains to link pools and tokens.");
    }
}

contract Example08UpdateAllowlist is Script {
    function run(address advancedPoolHook, address[] calldata removes, address[] calldata adds) external {
        require(advancedPoolHook != address(0), "advancedPoolHook cannot be zero");

        console2.log("[INFO] Example08 (CCT 03): Update AdvancedPoolHooks allowlist");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] AdvancedPoolHooks:", advancedPoolHook);
        console2.log("[INFO] Removes count:", removes.length);
        console2.log("[INFO] Adds count:", adds.length);

        bool allowListEnabled = AdvancedPoolHooks(advancedPoolHook).getAllowListEnabled();
        require(allowListEnabled, "allowlist is disabled on hook");

        vm.startBroadcast();
        AdvancedPoolHooks(advancedPoolHook).applyAllowListUpdates(removes, adds);
        vm.stopBroadcast();

        address[] memory currentAllowList = AdvancedPoolHooks(advancedPoolHook).getAllowList();
        console2.log("[RESULT] Allowlist updated. Current entries:", currentAllowList.length);
        for (uint256 i = 0; i < currentAllowList.length; ++i) {
            console2.log("[RESULT] Allowlist entry:", currentAllowList[i]);
        }
    }
}

contract Example08 is Script {
    function run(address localPool, uint64 remoteChainSelector, address remoteToken, address remotePool) external {
        require(localPool != address(0), "localPool cannot be zero");
        require(remoteChainSelector != 0, "remoteChainSelector cannot be zero");
        require(remoteToken != address(0), "remoteToken cannot be zero");
        require(remotePool != address(0), "remotePool cannot be zero");

        console2.log("[INFO] Example08 (CCT 03): Configure BurnMint pool remote lane");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Local pool:", localPool);
        console2.log("[INFO] Remote chain selector:", remoteChainSelector);
        console2.log("[INFO] Remote token:", remoteToken);
        console2.log("[INFO] Remote pool:", remotePool);

        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);

        RateLimiter.Config memory disabledRateLimiter = RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0});
        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](1);
        chainUpdates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig: disabledRateLimiter,
            inboundRateLimiterConfig: disabledRateLimiter
        });

        bool chainAlreadyConfigured = TokenPool(localPool).isSupportedChain(remoteChainSelector);
        uint64[] memory remoteChainSelectorsToRemove = chainAlreadyConfigured ? new uint64[](1) : new uint64[](0);
        if (chainAlreadyConfigured) {
            remoteChainSelectorsToRemove[0] = remoteChainSelector;
            console2.log("[WARN] Existing config detected for this remote chain selector; replacing it.");
        } else {
            console2.log("[INFO] No existing config for this remote chain selector; adding new one.");
        }

        vm.startBroadcast();
        TokenPool(localPool).applyChainUpdates(remoteChainSelectorsToRemove, chainUpdates);
        vm.stopBroadcast();

        bytes memory configuredRemoteTokenBytes = TokenPool(localPool).getRemoteToken(remoteChainSelector);
        bytes[] memory configuredRemotePools = TokenPool(localPool).getRemotePools(remoteChainSelector);
        address configuredRemoteToken = abi.decode(configuredRemoteTokenBytes, (address));
        address configuredRemotePool = abi.decode(configuredRemotePools[0], (address));

        console2.log("[RESULT] Remote token configured on pool:", configuredRemoteToken);
        console2.log("[RESULT] Remote pool configured on pool:", configuredRemotePool);
        console2.log("[RESULT] BurnMint pool lane setup completed for remote chain selector:", remoteChainSelector);
    }
}
