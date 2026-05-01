// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {BaseERC20} from "@chainlink/contracts-ccip/contracts/tokens/BaseERC20.sol";
import {CrossChainToken} from "@chainlink/contracts-ccip/contracts/tokens/CrossChainToken.sol";
import {LockReleaseTokenPool} from "@chainlink/contracts-ccip/contracts/pools/LockReleaseTokenPool.sol";
import {ERC20LockBox} from "@chainlink/contracts-ccip/contracts/pools/ERC20LockBox.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/interfaces/ITokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from
    "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";

import {AuthorizedCallers} from "@chainlink/contracts/src/v0.8/shared/access/AuthorizedCallers.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract DeployCCTLockReleaseTokenAndPool is Script {
    string internal constant TOKEN_NAME = "TestToken";
    string internal constant TOKEN_SYMBOL = "TEST";
    uint8 internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_PREMINT = 1_000_000 ether;
    uint256 internal constant TOKEN_MAX_SUPPLY = 100_000_000 ether;

    function run(address tokenAdminRegistry, address registryModuleOwnerCustom, address armProxy, address router)
        external
        returns (address token, address lockBox, address pool)
    {
        require(tokenAdminRegistry != address(0), "tokenAdminRegistry cannot be zero");
        require(registryModuleOwnerCustom != address(0), "registryModuleOwnerCustom cannot be zero");
        require(armProxy != address(0), "armProxy cannot be zero");
        require(router != address(0), "router cannot be zero");

        console2.log("[INFO] Example07 (CCT 02): Deploy LockRelease token + lock box + pool");
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
        ERC20LockBox lockBoxContract = new ERC20LockBox(address(tokenContract));
        LockReleaseTokenPool poolContract = new LockReleaseTokenPool(
            IERC20(address(tokenContract)),
            TOKEN_DECIMALS,
            address(0), // No advanced pool hook in CCT 02
            armProxy,
            router,
            address(lockBoxContract)
        );

        address[] memory addedCallers = new address[](1);
        addedCallers[0] = address(poolContract);
        lockBoxContract.applyAuthorizedCallerUpdates(
            AuthorizedCallers.AuthorizedCallerArgs({addedCallers: addedCallers, removedCallers: new address[](0)})
        );

        // Register token admin and attach pool in TokenAdminRegistry (CrossChainToken uses getCCIPAdmin, not owner()).
        RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaGetCCIPAdmin(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).setPool(address(tokenContract), address(poolContract));

        vm.stopBroadcast();

        token = address(tokenContract);
        lockBox = address(lockBoxContract);
        pool = address(poolContract);

        console2.log("[RESULT] Local CrossChainToken (LockRelease flow) deployed:", token);
        console2.log("[RESULT] Local CCT lock box deployed:", lockBox);
        console2.log("[RESULT] Local CCT LockRelease pool deployed:", pool);
        console2.log("[WARN] Remote chain configuration is not done yet.");
        console2.log("[WARN] Run Example07.run on both chains to link pools and tokens.");
    }
}

contract FundCCTLockBoxLiquidity is Script {
    function run(address token, address lockBox, uint256 amount) external {
        require(token != address(0), "token cannot be zero");
        require(lockBox != address(0), "lockBox cannot be zero");
        require(amount > 0, "amount must be > 0");

        console2.log("[INFO] Example07 (CCT 02): Fund lock box liquidity");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Token:", token);
        console2.log("[INFO] Lock box:", lockBox);
        console2.log("[INFO] Amount:", amount);

        vm.startBroadcast();
        bool success = IERC20(token).transfer(lockBox, amount);
        require(success, "lockBox funding failed");
        vm.stopBroadcast();

        uint256 lockBoxBalance = IERC20(token).balanceOf(lockBox);
        console2.log("[RESULT] Lock box funded. Current lock box balance:", lockBoxBalance);
    }
}

contract Example07 is Script {
    function run(address localPool, uint64 remoteChainSelector, address remoteToken, address remotePool) external {
        require(localPool != address(0), "localPool cannot be zero");
        require(remoteChainSelector != 0, "remoteChainSelector cannot be zero");
        require(remoteToken != address(0), "remoteToken cannot be zero");
        require(remotePool != address(0), "remotePool cannot be zero");

        console2.log("[INFO] Example07 (CCT 02): Configure LockRelease pool remote lane");
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
        console2.log("[RESULT] LockRelease pool lane setup completed for remote chain selector:", remoteChainSelector);
    }
}
