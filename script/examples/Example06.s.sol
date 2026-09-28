// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {EncodeExtraArgsOffchain} from "../EncodeExtraArgsOffchain.s.sol";

import {BaseERC20} from "@chainlink/contracts-ccip/contracts/tokens/BaseERC20.sol";
import {CrossChainToken} from "@chainlink/contracts-ccip/contracts/tokens/CrossChainToken.sol";
import {BurnMintTokenPool} from "@chainlink/contracts-ccip/contracts/pools/BurnMintTokenPool.sol";
import {TokenPool} from "@chainlink/contracts-ccip/contracts/pools/TokenPool.sol";
import {ITokenAdminRegistry} from "@chainlink/contracts-ccip/contracts/interfaces/ITokenAdminRegistry.sol";
import {IBurnMintERC20} from "@chainlink/contracts-ccip/contracts/interfaces/IBurnMintERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {
    RegistryModuleOwnerCustom
} from "@chainlink/contracts-ccip/contracts/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink/contracts-ccip/contracts/libraries/RateLimiter.sol";
import {OnRamp} from "@chainlink/contracts-ccip/contracts/onRamp/OnRamp.sol";
import {
    ICrossChainVerifierResolver
} from "@chainlink/contracts-ccip/contracts/interfaces/ICrossChainVerifierResolver.sol";
import {FinalityCodec} from "@chainlink/contracts-ccip/contracts/libraries/FinalityCodec.sol";
import {IPoolV2} from "@chainlink/contracts-ccip/contracts/interfaces/IPoolV2.sol";
import {IERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/IERC20.sol";

contract DeployCCTBurnMintTokenAndPool is Script {
    string internal constant TOKEN_NAME = "TestToken";
    string internal constant TOKEN_SYMBOL = "TEST";
    uint8 internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_PREMINT = 1_000_000 ether;
    uint256 internal constant TOKEN_MAX_SUPPLY = 100_000_000 ether;

    function run(address tokenAdminRegistry, address registryModuleOwnerCustom, address armProxy, address router)
        external
        returns (address token, address pool)
    {
        require(tokenAdminRegistry != address(0), "tokenAdminRegistry cannot be zero");
        require(registryModuleOwnerCustom != address(0), "registryModuleOwnerCustom cannot be zero");
        require(armProxy != address(0), "armProxy cannot be zero");
        require(router != address(0), "router cannot be zero");

        console2.log("[INFO] Example06 (CCT 01): Deploy CrossChainToken + BurnMint pool");
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

        BurnMintTokenPool poolContract = new BurnMintTokenPool(
            IBurnMintERC20(address(tokenContract)),
            TOKEN_DECIMALS,
            address(0), // No advanced pool hook in CCT 01
            armProxy,
            router
        );

        // Token pool needs mint and burn roles on the local token.
        tokenContract.grantMintAndBurnRoles(address(poolContract));

        // Register token admin and attach pool in TokenAdminRegistry (CrossChainToken uses getCCIPAdmin, not owner()).
        RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaGetCCIPAdmin(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(address(tokenContract));
        ITokenAdminRegistry(tokenAdminRegistry).setPool(address(tokenContract), address(poolContract));

        vm.stopBroadcast();

        token = address(tokenContract);
        pool = address(poolContract);

        console2.log("[RESULT] Local CrossChainToken deployed:", token);
        console2.log("[RESULT] Local CCT BurnMint pool deployed:", pool);
        console2.log("[WARN] Remote chain configuration is not done yet.");
        console2.log("[WARN] Run Example06.run on both chains to link pools and tokens.");
    }
}

contract Example06 is Script {
    function run(address localPool, uint64 remoteChainSelector, address remoteToken, address remotePool) external {
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

/// @notice Sets `TokenPool` allowed finality (`FinalityCodec` bytes4). Use `FinalityCodec._encodeBlockDepth(depth)` for a depth-only policy; `bytes4(0)` waits for full finality.
contract Example06SetPoolAllowedFinalityConfig is Script {
    function run(address localPool, bytes4 allowedFinality) external returns (bytes4 updatedAllowedFinality) {
        require(localPool != address(0), "localPool cannot be zero");

        console2.log("[INFO] Example06 (CCT 01): Set pool allowed finality config");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Local pool:", localPool);
        console2.logBytes4(TokenPool(localPool).getAllowedFinalityConfig());
        console2.logBytes4(allowedFinality);

        vm.startBroadcast();
        TokenPool(localPool).setAllowedFinalityConfig(allowedFinality);
        vm.stopBroadcast();

        updatedAllowedFinality = TokenPool(localPool).getAllowedFinalityConfig();
        console2.logBytes4(updatedAllowedFinality);
    }
}

contract Example06GetPoolAllowedFinalityConfig is Script {
    function run(address localPool) external view returns (bytes4 allowedFinality) {
        require(localPool != address(0), "localPool cannot be zero");

        allowedFinality = TokenPool(localPool).getAllowedFinalityConfig();

        console2.log("[INFO] Example06 (CCT 01): Read pool allowed finality config");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Local pool:", localPool);
        console2.logBytes4(allowedFinality);
    }
}

contract SendCCTTokenWithExtraArgsV3DefaultFinality is Script {
    function run(
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        address tokenToSend,
        uint256 amount,
        uint32 gasLimit,
        address feeTokenAddress
    ) external returns (bytes32 messageId) {
        require(sourceRouter != address(0), "sourceRouter cannot be zero");
        require(receiver != address(0), "receiver cannot be zero");
        require(tokenToSend != address(0), "token cannot be zero");
        require(amount > 0, "amount must be > 0");

        uint16 blockConfirmations = 0; // Default finality

        console2.log("[INFO] CCT sender: ExtraArgsV3 token transfer (default finality)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Source router:", sourceRouter);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Receiver:", receiver);
        console2.log("[INFO] Token:", tokenToSend);
        console2.log("[INFO] Amount:", amount);
        console2.log("[INFO] Gas limit:", gasLimit);
        console2.log("[INFO] Block confirmations:", blockConfirmations);
        console2.log("[INFO] Fee token:", feeTokenAddress);
        console2.log("[WARN] blockConfirmations = 0 means default finality.");
        console2.log("[WARN] Use gasLimit 0 if receiver is an EOA.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        bytes memory extraArgs = extraArgsEncoder.encodeV3Basic(gasLimit, blockConfirmations);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSend, amount: amount});

        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: feeTokenAddress
        });

        uint256 fee = IRouterClient(sourceRouter).getFee(destinationChainSelector, ccipMessage);
        console2.log("[INFO] Quoted fee:", fee);

        vm.startBroadcast();
        IERC20(tokenToSend).approve(sourceRouter, amount);
        if (feeTokenAddress == address(0)) {
            console2.log("[INFO] Sending message, paying CCIP fee in native token");
            messageId = IRouterClient(sourceRouter).ccipSend{value: fee}(destinationChainSelector, ccipMessage);
        } else {
            console2.log("[INFO] Sending message, paying CCIP fee in LINK");
            IERC20(feeTokenAddress).approve(sourceRouter, fee);
            messageId = IRouterClient(sourceRouter).ccipSend(destinationChainSelector, ccipMessage);
        }
        vm.stopBroadcast();

        console2.log("[RESULT] Monitor message status at https://ccip.chain.link using message ID:");
        console2.logBytes32(messageId);
    }
}

contract SendCCTTokenWithExtraArgsV3CustomFinality is Script {
    function run(
        address sourceRouter,
        uint64 destinationChainSelector,
        address receiver,
        address tokenToSend,
        uint256 amount,
        uint32 gasLimit,
        uint16 blockConfirmations,
        address feeTokenAddress
    ) external returns (bytes32 messageId) {
        require(sourceRouter != address(0), "sourceRouter cannot be zero");
        require(receiver != address(0), "receiver cannot be zero");
        require(tokenToSend != address(0), "token cannot be zero");
        require(amount > 0, "amount must be > 0");
        require(blockConfirmations > 0, "blockConfirmations must be > 0 in custom-finality sender");

        console2.log("[INFO] CCT sender: ExtraArgsV3 token transfer (custom finality)");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Source router:", sourceRouter);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Receiver:", receiver);
        console2.log("[INFO] Token:", tokenToSend);
        console2.log("[INFO] Amount:", amount);
        console2.log("[INFO] Gas limit:", gasLimit);
        console2.log("[INFO] Block confirmations:", blockConfirmations);
        console2.log("[INFO] Fee token:", feeTokenAddress);
        console2.log("[WARN] This can revert if pool/executor min confirmations are higher than requested.");
        console2.log("[WARN] Use gasLimit 0 if receiver is an EOA.");

        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        bytes memory extraArgs = extraArgsEncoder.encodeV3Basic(gasLimit, blockConfirmations);

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSend, amount: amount});

        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: feeTokenAddress
        });

        uint256 fee = IRouterClient(sourceRouter).getFee(destinationChainSelector, ccipMessage);
        console2.log("[INFO] Quoted fee:", fee);

        vm.startBroadcast();
        IERC20(tokenToSend).approve(sourceRouter, amount);
        if (feeTokenAddress == address(0)) {
            console2.log("[INFO] Sending message, paying CCIP fee in native token");
            messageId = IRouterClient(sourceRouter).ccipSend{value: fee}(destinationChainSelector, ccipMessage);
        } else {
            console2.log("[INFO] Sending message, paying CCIP fee in LINK");
            IERC20(feeTokenAddress).approve(sourceRouter, fee);
            messageId = IRouterClient(sourceRouter).ccipSend(destinationChainSelector, ccipMessage);
        }
        vm.stopBroadcast();

        console2.log("[RESULT] Monitor message status at https://ccip.chain.link using message ID:");
        console2.logBytes32(messageId);
    }
}

/// @notice Minimal view interfaces so the pre-flight below stays readable.
interface IRouterOnRampView {
    function getOnRamp(uint64 destChainSelector) external view returns (address);
}

interface IAllowedFinalityView {
    function getAllowedFinalityConfig() external view returns (bytes4);
}

interface ITypeAndVersionView {
    function typeAndVersion() external view returns (string memory);
}

interface IPoolInterfaceView {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @notice Tiny helper so the pre-flight can quote a fee inside a `try/catch`.
/// @dev A rejected finality request reverts inside `getFee`. Script contracts cannot use
/// `try this.foo()` (Foundry forbids relying on a script's own address), so the quote lives here.
contract FinalityQuoter {
    function quote(address router, uint64 dest, address token, uint16 depth) external returns (uint256) {
        EncodeExtraArgsOffchain extraArgsEncoder = new EncodeExtraArgsOffchain();
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: token, amount: 1 ether});
        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(uint160(0xB0B))),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgsEncoder.encodeV3Basic(0, depth),
            feeToken: address(0)
        });
        return IRouterClient(router).getFee(dest, ccipMessage);
    }
}

/// @notice Read-only pre-flight for a standard token-only Faster Than Finality transfer.
/// @dev Quotes a sample 1e18-unit transfer; actual fees depend on amount and message details.
/// Nothing here broadcasts a transaction, and a successful quote does not guarantee a send.
contract Example06CheckFinalityGates is Script {
    function run(address sourceRouter, uint64 destinationChainSelector, address tokenToSend, uint16 blockConfirmations)
        external
    {
        require(sourceRouter != address(0), "sourceRouter cannot be zero");
        require(tokenToSend != address(0), "token cannot be zero");
        require(blockConfirmations > 0, "blockConfirmations must be greater than zero");

        console2.log("[INFO] Example06 (CCT 01): Faster Than Finality pre-flight");
        console2.log("[INFO] Source chain ID:", block.chainid);
        console2.log("[INFO] Destination selector:", destinationChainSelector);
        console2.log("[INFO] Token:", tokenToSend);
        console2.log("[INFO] Requested blockConfirmations:", blockConfirmations);

        address onRamp = IRouterOnRampView(sourceRouter).getOnRamp(destinationChainSelector);
        require(onRamp != address(0), "no OnRamp for that destination selector on this router");
        console2.log("[INFO] OnRamp:", onRamp);
        string memory onRampVersion = ITypeAndVersionView(onRamp).typeAndVersion();
        console2.log("[INFO] OnRamp version:", onRampVersion);
        require(keccak256(bytes(onRampVersion)) == keccak256(bytes("OnRamp 2.0.0")), "expected a CCIP 2.0 router");

        OnRamp.DestChainConfig memory destConfig = OnRamp(onRamp).getDestChainConfig(destinationChainSelector);

        // --- Layer 1: the token pool (the token issuer's FTF switch) ---
        address pool = address(OnRamp(onRamp).getPoolBySourceToken(destinationChainSelector, IERC20(tokenToSend)));
        require(pool != address(0), "token has no pool registered in the TokenAdminRegistry for this lane");
        console2.log("[GATE] Token pool:", pool);
        _reportPool(pool, blockConfirmations);

        // --- Layer 2: the executor ---
        console2.log("[GATE] Executor:", destConfig.defaultExecutor);
        _report(IAllowedFinalityView(destConfig.defaultExecutor).getAllowedFinalityConfig(), blockConfirmations);

        // --- Layer 3: every CCV on the lane ---
        _reportCCVs("lane-mandated CCV", destConfig.laneMandatedCCVs, destinationChainSelector, blockConfirmations);
        _reportCCVs("default CCV", destConfig.defaultCCVs, destinationChainSelector, blockConfirmations);

        // --- The cost of speed ---
        console2.log("[FEE] Quoting the same 1-token transfer twice...");
        FinalityQuoter quoter = new FinalityQuoter();
        uint256 slowFee;
        bool slowQuoted;
        try quoter.quote(sourceRouter, destinationChainSelector, tokenToSend, 0) returns (uint256 quoted) {
            slowFee = quoted;
            slowQuoted = true;
            console2.log("[FEE] blockConfirmations=0 (full finality), wei:", slowFee);
        } catch {
            console2.log("[FAIL] Full-finality sample quote reverted; check token registration and lane configuration.");
        }

        // A rejected FTF request reverts inside getFee, so keep the pre-flight alive to explain why.
        try quoter.quote(sourceRouter, destinationChainSelector, tokenToSend, blockConfirmations) returns (
            uint256 fastFee
        ) {
            console2.log("[FEE] blockConfirmations set (FTF),        wei:", fastFee);
            if (slowQuoted && fastFee > slowFee) {
                console2.log("[FEE] FTF premium (wei):", fastFee - slowFee);
            } else if (slowQuoted) {
                console2.log("[FEE] No premium for this sample transfer.");
            }
        } catch {
            console2.log("[FAIL] getFee REVERTED for this blockConfirmations value.");
            console2.log("[FAIL] One of the gates above does not permit it. Raise the depth, or run");
            console2.log("[FAIL] If you own the pool, use Example06SetPoolAllowedFinalityConfig to opt in.");
        }
        console2.log("[WARN] A fee quote does not prove ccipSend will succeed; review every gate above.");
    }

    /// @notice Reports the source token pool's FTF posture.
    /// @dev A pool that does not advertise `IPoolV2` cannot carry an FTF request at all. Critically,
    /// `getFee` does NOT catch this -- it falls back to the FeeQuoter and will happily quote an FTF
    /// request that `ccipSend` then rejects with `OnRamp.FTFNotSupportedOnPoolV1`. So check the
    /// interface, not just the fee.
    function _reportPool(address pool, uint16 requestedDepth) internal view {
        bool isV2;
        try IPoolInterfaceView(pool).supportsInterface(type(IPoolV2).interfaceId) returns (bool ok) {
            isV2 = ok;
        } catch {
            isV2 = false;
        }
        if (!isV2) {
            console2.log("       -> POOL IS NOT IPoolV2. FTF is impossible through this pool.");
            console2.log("       -> WARNING: getFee may still QUOTE an FTF request (it falls back to");
            console2.log("       -> the FeeQuoter), but ccipSend reverts with FTFNotSupportedOnPoolV1.");
            console2.log("       -> Only blockConfirmations = 0 will actually send.");
            return;
        }
        try IAllowedFinalityView(pool).getAllowedFinalityConfig() returns (bytes4 allowed) {
            _report(allowed, requestedDepth);
        } catch {
            console2.log(
                "       -> pool advertises IPoolV2 but getAllowedFinalityConfig() reverted; check it manually."
            );
        }
    }

    /// @notice Decodes one `allowedFinality` value into plain language.
    function _report(bytes4 allowedFinality, uint16 requestedDepth) internal pure {
        console2.log("       allowedFinality:", vm.toString(abi.encodePacked(allowedFinality)));
        if (allowedFinality == FinalityCodec.WAIT_FOR_FINALITY_FLAG) {
            console2.log("       -> FTF DISABLED here (full finality only). Any blockConfirmations > 0 will revert.");
            return;
        }
        uint16 minDepth = uint16(uint32(allowedFinality));
        bool safeAllowed = (uint32(allowedFinality) & uint32(FinalityCodec.WAIT_FOR_SAFE_FLAG)) != 0;
        console2.log("       -> min block depth allowed:", minDepth);
        // The upper 16 bits are the flag space. `safe`/chain-native fast-confirmation modes live here
        // and are reserved for future protocol use -- see FinalityCodec.
        console2.log("       -> 'wait for safe' flag allowed:", safeAllowed);
        if (minDepth == 0) {
            console2.log("       -> WARNING: no depth allowed, so a depth request reverts here.");
        } else if (requestedDepth < minDepth) {
            console2.log("       -> WARNING: requested depth is BELOW this floor; the send will revert.");
        }
    }

    function _reportCCVs(string memory label, address[] memory ccvs, uint64 dest, uint16 requestedDepth) internal view {
        for (uint256 i = 0; i < ccvs.length; ++i) {
            (address effective, bytes4 allowed, bool ok) = _resolveCCV(ccvs[i], dest);
            console2.log("[GATE]", label);
            console2.log("       configured:", ccvs[i]);
            console2.log("       effective verifier:", effective);
            if (ok) {
                _report(allowed, requestedDepth);
            } else {
                console2.log("       -> could not read allowedFinalityConfig (custom CCV?); check it manually.");
            }
        }
    }

    /// @dev A lane CCV can be a resolver that points at the real verifier per destination chain, so read
    /// the CCV directly first and fall back to resolving it.
    function _resolveCCV(address ccv, uint64 dest) internal view returns (address effective, bytes4 allowed, bool ok) {
        try IAllowedFinalityView(ccv).getAllowedFinalityConfig() returns (bytes4 direct) {
            return (ccv, direct, true);
        } catch {
            try ICrossChainVerifierResolver(ccv).getOutboundImplementation(dest, "") returns (address impl) {
                if (impl != address(0)) {
                    try IAllowedFinalityView(impl).getAllowedFinalityConfig() returns (bytes4 resolved) {
                        return (impl, resolved, true);
                    } catch {}
                }
                return (impl, bytes4(0), false);
            } catch {
                return (ccv, bytes4(0), false);
            }
        }
    }
}
