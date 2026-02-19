// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {FactoryBurnMintERC20} from
    "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/TokenPoolFactory/FactoryBurnMintERC20.sol";
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/contracts/pools/BurnMintTokenPool.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/interfaces/ITokenAdminRegistry.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/contracts/interfaces/IBurnMintERC20.sol";
import {RegistryModuleOwnerCustom} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";

contract DeployCCTBurnMintTokenAndPool is Script {
    string internal constant TOKEN_NAME = "TestToken";
    string internal constant TOKEN_SYMBOL = "TEST";
    uint8 internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_PREMINT = 1_000_000 ether;
    uint256 internal constant TOKEN_MAX_SUPPLY = 100_000_000 ether;

    function run(
        address tokenAdminRegistry,
        address registryModuleOwnerCustom,
        address armProxy,
        address router
    ) external returns (address token, address pool) {
        require(tokenAdminRegistry != address(0), "tokenAdminRegistry cannot be zero");
        require(registryModuleOwnerCustom != address(0), "registryModuleOwnerCustom cannot be zero");
        require(armProxy != address(0), "armProxy cannot be zero");
        require(router != address(0), "router cannot be zero");

        console2.log("[INFO] Example06 (CCT 01): Deploy BurnMint token + BurnMint pool");
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

        vm.startBroadcast();
        (, address broadcaster,) = vm.readCallers();

        FactoryBurnMintERC20 tokenContract = new FactoryBurnMintERC20(
            TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_MAX_SUPPLY, TOKEN_PREMINT, broadcaster
        );
        BurnMintTokenPool poolContract = new BurnMintTokenPool(
            IBurnMintERC20(address(tokenContract)),
            TOKEN_DECIMALS,
            address(0), // No advanced pool hook in CCT 01
            armProxy,
            router
        );

        // Token pool needs mint and burn roles on the local token.
        tokenContract.grantMintAndBurnRoles(address(poolContract));

        // Register token admin and attach pool in TokenAdminRegistry.
        RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaOwner(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).setPool(address(tokenContract), address(poolContract));

        vm.stopBroadcast();

        token = address(tokenContract);
        pool = address(poolContract);

        console2.log("[RESULT] Local CCT BurnMint token deployed:", token);
        console2.log("[RESULT] Local CCT BurnMint pool deployed:", pool);
        console2.log("[WARN] Remote chain configuration is not done yet.");
        console2.log("[WARN] Run Example06.run on both chains to link pools and tokens.");
    }
}

contract Example06 is Script {
    function run(
        address localPool,
        uint64 remoteChainSelector,
        address remoteToken,
        address remotePool
    ) external {
        require(localPool != address(0), "localPool cannot be zero");
        require(remoteChainSelector != 0, "remoteChainSelector cannot be zero");
        require(remoteToken != address(0), "remoteToken cannot be zero");
        require(remotePool != address(0), "remotePool cannot be zero");

        console2.log("[INFO] Example06 (CCT 01): Configure BurnMint pool remote lane");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Local pool:", localPool);
        console2.log("[INFO] Remote chain selector:", remoteChainSelector);
        console2.log("[INFO] Remote token:", remoteToken);
        console2.log("[INFO] Remote pool:", remotePool);

        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);

        RateLimiter.Config memory disabledRateLimiter =
            RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0});
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
