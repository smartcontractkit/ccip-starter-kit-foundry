// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {ICommitStore} from "../interfaces/ICommitStore.sol";
import {IAFN} from "../interfaces/IAFN.sol";
import {IPool} from "../interfaces/pools/IPool.sol";
import {IEVM2EVMOffRamp} from "../interfaces/offRamp/IEVM2EVMOffRamp.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IAny2EVMMessageReceiver} from "../interfaces/IAny2EVMMessageReceiver.sol";

import {Client} from "../models/Client.sol";
import {Internal} from "../models/Internal.sol";
import {OCR2Base} from "../ocr/OCR2Base.sol";
import {AggregateRateLimiter} from "../AggregateRateLimiter.sol";
import {EnumerableMapAddresses} from "../../libraries/internal/EnumerableMapAddresses.sol";

import {IERC20} from "../../vendor/IERC20.sol";
import {Address} from "../../vendor/Address.sol";
import {ERC165Checker} from "../../vendor/ERC165Checker.sol";
import {Pausable} from "../../vendor/Pausable.sol";

/// @notice EVM2EVMOffRamp enables OCR networks to execute multiple messages
/// in an OffRamp in a single transaction.
contract EVM2EVMOffRamp is IEVM2EVMOffRamp, Pausable, AggregateRateLimiter, TypeAndVersionInterface, OCR2Base {
  using Address for address;
  using ERC165Checker for address;
  using EnumerableMapAddresses for EnumerableMapAddresses.AddressToAddressMap;

  error InvalidTokenPoolConfig();
  error PoolAlreadyAdded();
  error PoolDoesNotExist();
  error TokenPoolMismatch();

  event PoolAdded(address token, address pool);
  event PoolRemoved(address token, address pool);

  // STATIC CONFIG
  // solhint-disable-next-line chainlink-solidity/all-caps-constant-storage-variables
  string public constant override typeAndVersion = "EVM2EVMOffRamp 1.0.0";
  // Commit store address on the destination chain
  address internal immutable i_commitStore;
  // Chain ID of the source chain
  uint64 internal immutable i_sourceChainId;
  // Chain ID of this chain
  uint64 internal immutable i_chainId;
  // OnRamp address on the source chain
  address internal immutable i_onRamp;
  // metadataHash is a prefix for a message hash preimage to ensure uniqueness.
  bytes32 internal immutable i_metadataHash;

  // DYNAMIC CONFIG
  DynamicConfig internal s_dynamicConfig;
  // source token => token pool
  EnumerableMapAddresses.AddressToAddressMap private s_poolsBySourceToken;
  // dest token => token pool
  EnumerableMapAddresses.AddressToAddressMap private s_poolsByDestToken;

  // STATE
  mapping(address => uint64) internal s_senderNonce;
  // A mapping of sequence numbers to execution state.
  // This makes sure we never execute a message twice.
  mapping(uint64 => Internal.MessageExecutionState) internal s_executedMessages;

  /// @notice The `tokens` and `pools` passed to this constructor depend on which chain this contract
  /// is being deployed to. Mappings of source token => destination pool is maintained on the destination
  /// chain. Therefore, when being deployed as an inheriting OffRamp, `tokens` should represent source chain tokens,
  /// `pools` destinations chain pools. When being deployed as an inheriting OnRamp, `tokens` and `pools`
  /// should both be source chain.
  constructor(
    StaticConfig memory staticConfig,
    DynamicConfig memory dynamicConfig,
    IERC20[] memory sourceTokens,
    IPool[] memory pools,
    RateLimiterConfig memory rateLimiterConfig
  ) OCR2Base() Pausable() AggregateRateLimiter(rateLimiterConfig) {
    if (sourceTokens.length != pools.length) revert InvalidTokenPoolConfig();
    if (staticConfig.onRamp == address(0) || staticConfig.commitStore == address(0)) revert ZeroAddressNotAllowed();

    i_commitStore = staticConfig.commitStore;
    i_sourceChainId = staticConfig.sourceChainId;
    i_chainId = staticConfig.chainId;
    i_onRamp = staticConfig.onRamp;

    i_metadataHash = _metadataHash(Internal.EVM_2_EVM_MESSAGE_HASH);

    // Set new tokens and pools
    for (uint256 i = 0; i < sourceTokens.length; ++i) {
      s_poolsBySourceToken.set(address(sourceTokens[i]), address(pools[i]));
      s_poolsByDestToken.set(address(pools[i].getToken()), address(pools[i]));
    }

    _setDynamicConfig(dynamicConfig);
  }

  // ================================================================
  // |                          Messaging                           |
  // ================================================================

  /// @inheritdoc IEVM2EVMOffRamp
  function getExecutionState(uint64 sequenceNumber) public view returns (Internal.MessageExecutionState) {
    return s_executedMessages[sequenceNumber];
  }

  /// @inheritdoc IEVM2EVMOffRamp
  function getSenderNonce(address sender) public view override returns (uint64 nonce) {
    return s_senderNonce[sender];
  }

  /// @inheritdoc IEVM2EVMOffRamp
  function manuallyExecute(Internal.ExecutionReport memory report) external override {
    _execute(report, true);
  }

  /// @notice Entrypoint for execution, called by the OCR network
  /// @dev Expects an encoded ExecutionReport
  function _report(bytes memory report) internal override {
    _execute(abi.decode(report, (Internal.ExecutionReport)), false);
  }

  /// @notice Executes a report, executing each message in order.
  /// @param report The execution report containing the messages and proofs.
  /// @param manualExecution A boolean value indication whether this function is called
  /// from the DON (false) or manually (true).
  function _execute(Internal.ExecutionReport memory report, bool manualExecution) internal whenNotPaused whenHealthy {
    uint256 numMsgs = report.encodedMessages.length;
    if (numMsgs == 0) revert EmptyReport();

    bytes32[] memory hashedLeaves = new bytes32[](numMsgs);
    Internal.EVM2EVMMessage[] memory decodedMessages = new Internal.EVM2EVMMessage[](numMsgs);

    for (uint256 i = 0; i < numMsgs; ++i) {
      Internal.EVM2EVMMessage memory decodedMessage = abi.decode(report.encodedMessages[i], (Internal.EVM2EVMMessage));
      // We do this hash here instead of in _verifyMessages to avoid two separate loops
      // over the same data, which increases gas cost
      hashedLeaves[i] = Internal._hash(decodedMessage, i_metadataHash);
      decodedMessages[i] = decodedMessage;
    }

    // SECURITY CRITICAL CHECK
    uint256 timestampCommitted = ICommitStore(i_commitStore).verify(hashedLeaves, report.proofs, report.proofFlagBits);
    if (timestampCommitted <= 0) revert RootNotCommitted();

    // Execute messages
    for (uint256 i = 0; i < numMsgs; ++i) {
      Internal.EVM2EVMMessage memory message = decodedMessages[i];
      Internal.MessageExecutionState originalState = getExecutionState(message.sequenceNumber);
      // Two valid cases here, we either have never touched this message before, or we tried to execute
      // and failed. This check protects against reentry and re-execution because the other states are
      // IN_PROGRESS and SUCCESS, both should not be allowed to execute.
      if (
        !(originalState == Internal.MessageExecutionState.UNTOUCHED ||
          originalState == Internal.MessageExecutionState.FAILURE)
      ) revert AlreadyExecuted(message.sequenceNumber);

      if (manualExecution) {
        bool isOldCommitReport = (block.timestamp - timestampCommitted) >
          s_dynamicConfig.permissionLessExecutionThresholdSeconds;
        // Manually execution is fine if we previously failed or if the commit report is just too old
        // Acceptable state transitions: FAILURE->SUCCESS, UNTOUCHED->SUCCESS, FAILURE->FAILURE
        if (!(isOldCommitReport || originalState == Internal.MessageExecutionState.FAILURE))
          revert ManualExecutionNotYetEnabled();
      } else {
        // DON can only execute a message once
        // Acceptable state transitions: UNTOUCHED->SUCCESS, UNTOUCHED->FAILURE
        if (originalState != Internal.MessageExecutionState.UNTOUCHED) revert AlreadyAttempted(message.sequenceNumber);
      }

      // If this is the first time executing this message we take the fee
      if (originalState == Internal.MessageExecutionState.UNTOUCHED) {
        // UNTOUCHED messages MUST be executed in order always.
        if (s_senderNonce[message.sender] + 1 != message.nonce) {
          // We skip the message if the nonce is incorrect
          emit SkippedIncorrectNonce(message.nonce, message.sender);
          continue;
        }
      }

      _isWellFormed(message);

      s_executedMessages[message.sequenceNumber] = Internal.MessageExecutionState.IN_PROGRESS;
      Internal.MessageExecutionState newState = _trialExecute(message, manualExecution);
      s_executedMessages[message.sequenceNumber] = newState;

      if (manualExecution) {
        // Nonce changes per state transition:
        // FAILURE->SUCCESS: no nonce bump unless strict
        // UNTOUCHED->SUCCESS: nonce bump
        // FAILURE->FAILURE: no nonce bump
        if (
          (message.strict &&
            originalState == Internal.MessageExecutionState.FAILURE &&
            newState == Internal.MessageExecutionState.SUCCESS) ||
          (originalState == Internal.MessageExecutionState.UNTOUCHED &&
            newState == Internal.MessageExecutionState.SUCCESS)
        ) {
          s_senderNonce[message.sender]++;
        }
      } else {
        // Nonce changes per state transition:
        // UNTOUCHED->SUCCESS: nonce bump
        // UNTOUCHED->FAILURE: nonce bump unless strict
        if (!(message.strict && newState == Internal.MessageExecutionState.FAILURE)) {
          s_senderNonce[message.sender]++;
        }
      }

      emit ExecutionStateChanged(message.sequenceNumber, message.messageId, newState);
    }
  }

  /// @notice Does basic message validation. Should never fail.
  /// @param message The message to be validated.
  /// @dev reverts on validation failures.
  function _isWellFormed(Internal.EVM2EVMMessage memory message) private view {
    if (message.sourceChainId != i_sourceChainId) revert InvalidSourceChain(message.sourceChainId);
    if (message.tokenAmounts.length > uint256(s_dynamicConfig.maxTokensLength))
      revert UnsupportedNumberOfTokens(message.sequenceNumber);
    if (message.data.length > uint256(s_dynamicConfig.maxDataSize))
      revert MessageTooLarge(uint256(s_dynamicConfig.maxDataSize), message.data.length);
  }

  /// @notice Try executing a message.
  /// @param message Client.Any2EVMMessage memory message.
  /// @param manualExecution bool to indicate manual instead of DON execution.
  /// @return the new state of the message, being either SUCCESS or FAILURE.
  function _trialExecute(Internal.EVM2EVMMessage memory message, bool manualExecution)
    internal
    returns (Internal.MessageExecutionState)
  {
    try this.executeSingleMessage(message, manualExecution) {} catch (bytes memory err) {
      if (IEVM2EVMOffRamp.ReceiverError.selector == bytes4(err)) {
        return Internal.MessageExecutionState.FAILURE;
      } else {
        revert ExecutionError(err);
      }
    }
    return Internal.MessageExecutionState.SUCCESS;
  }

  /// @notice Execute a single message.
  /// @param message The message that will be executed.
  /// @param manualExecution bool to indicate manual instead of DON execution.
  /// @dev this can only be called by the contract itself. It is part of
  /// the Execute call, as we can only try/catch on external calls.
  function executeSingleMessage(Internal.EVM2EVMMessage memory message, bool manualExecution) external {
    if (msg.sender != address(this)) revert CanOnlySelfCall();
    Client.EVMTokenAmount[] memory destTokenAmounts = new Client.EVMTokenAmount[](0);
    if (message.tokenAmounts.length > 0) {
      destTokenAmounts = _releaseOrMintTokens(message.tokenAmounts, message.receiver);
    }
    if (
      !message.receiver.isContract() || !message.receiver.supportsInterface(type(IAny2EVMMessageReceiver).interfaceId)
    ) return;
    if (
      !IRouter(s_dynamicConfig.router).routeMessage(
        Internal._toAny2EVMMessage(message, destTokenAmounts),
        manualExecution,
        message.gasLimit,
        message.receiver
      )
    ) revert ReceiverError();
  }

  /// @notice creates a unique hash to be used in message hashing.
  function _metadataHash(bytes32 prefix) internal view returns (bytes32) {
    return keccak256(abi.encode(prefix, i_sourceChainId, i_chainId, i_onRamp));
  }

  // ================================================================
  // |                           Config                             |
  // ================================================================

  /// @inheritdoc IEVM2EVMOffRamp
  function getStaticConfig() external view override returns (StaticConfig memory) {
    return
      IEVM2EVMOffRamp.StaticConfig({
        commitStore: i_commitStore,
        chainId: i_chainId,
        sourceChainId: i_sourceChainId,
        onRamp: i_onRamp
      });
  }

  /// @inheritdoc IEVM2EVMOffRamp
  function getDynamicConfig() external view override returns (DynamicConfig memory) {
    return s_dynamicConfig;
  }

  /// @inheritdoc IEVM2EVMOffRamp
  function setDynamicConfig(DynamicConfig memory config) external override onlyOwner {
    _setDynamicConfig(config);
  }

  /// @notice Internal version of setDynamicConfig to allow for reuse in the constructor.
  function _setDynamicConfig(DynamicConfig memory dynamicConfig) private {
    if (dynamicConfig.router == address(0) || dynamicConfig.afn == address(0))
      revert InvalidOffRampConfig(dynamicConfig);

    s_dynamicConfig = dynamicConfig;

    emit ConfigSet(
      IEVM2EVMOffRamp.StaticConfig({
        commitStore: i_commitStore,
        chainId: i_chainId,
        sourceChainId: i_sourceChainId,
        onRamp: i_onRamp
      }),
      dynamicConfig
    );
  }

  // ================================================================
  // |                      Tokens and pools                        |
  // ================================================================

  /// @notice Get all supported source tokens
  /// @return sourceTokens of supported source tokens
  function getSupportedTokens() public view returns (IERC20[] memory sourceTokens) {
    sourceTokens = new IERC20[](s_poolsBySourceToken.length());
    for (uint256 i = 0; i < sourceTokens.length; ++i) {
      (address token, ) = s_poolsBySourceToken.at(i);
      sourceTokens[i] = IERC20(token);
    }
  }

  /// @notice Get a token pool by its source token
  /// @param sourceToken token
  /// @return Token Pool
  function getPoolBySourceToken(IERC20 sourceToken) public view returns (IPool) {
    (bool success, address pool) = s_poolsBySourceToken.tryGet(address(sourceToken));
    if (!success) revert UnsupportedToken(sourceToken);
    return IPool(pool);
  }

  /// @notice Get the destination token from the pool based on a given source token.
  /// @param sourceToken The source token
  /// @return the destination token
  function getDestinationToken(IERC20 sourceToken) public view returns (IERC20) {
    (bool success, address pool) = s_poolsBySourceToken.tryGet(address(sourceToken));
    if (!success) revert PoolDoesNotExist();
    return IPool(pool).getToken();
  }

  /// @notice Get a token pool by its dest token
  /// @param destToken token
  /// @return Token Pool
  function getPoolByDestToken(IERC20 destToken) public view returns (IPool) {
    (bool success, address pool) = s_poolsByDestToken.tryGet(address(destToken));
    if (!success) revert UnsupportedToken(destToken);
    return IPool(pool);
  }

  /// @notice Get all configured destination tokens
  /// @return destTokens Array of configured destination tokens
  function getDestinationTokens() external view returns (IERC20[] memory destTokens) {
    destTokens = new IERC20[](s_poolsByDestToken.length());
    for (uint256 i = 0; i < destTokens.length; ++i) {
      (address token, ) = s_poolsByDestToken.at(i);
      destTokens[i] = IERC20(token);
    }
  }

  function applyPoolUpdates(Internal.PoolUpdate[] memory removes, Internal.PoolUpdate[] memory adds) public onlyOwner {
    for (uint256 i = 0; i < removes.length; ++i) {
      address token = removes[i].token;
      address pool = removes[i].pool;

      // Check if the pool exists
      if (!s_poolsBySourceToken.contains(token)) revert PoolDoesNotExist();
      // Sanity check
      if (s_poolsBySourceToken.get(token) != pool) revert TokenPoolMismatch();

      s_poolsBySourceToken.remove(token);
      s_poolsByDestToken.remove(address(IPool(pool).getToken()));

      emit PoolRemoved(token, pool);
    }

    for (uint256 i = 0; i < adds.length; ++i) {
      address token = adds[i].token;
      address pool = adds[i].pool;

      if (token == address(0) || pool == address(0)) revert InvalidTokenPoolConfig();
      // Check if the pool is already set
      if (s_poolsBySourceToken.contains(token)) revert PoolAlreadyAdded();

      // Set the s_pools with new config values
      s_poolsBySourceToken.set(token, pool);
      s_poolsByDestToken.set(address(IPool(pool).getToken()), pool);

      emit PoolAdded(token, pool);
    }
  }

  /// @notice Uses the pool to release or mint tokens and send them to the given receiver address.
  /// @param pool The pool to release/mint tokens from.
  /// @param amount The number of tokens to release/mint.
  /// @param receiver The address that will receive the tokens.
  function _releaseOrMintToken(
    IPool pool,
    uint256 amount,
    address receiver
  ) internal {
    pool.releaseOrMint(receiver, amount);
  }

  /// @notice Uses pools to release or mint a number of different tokens to a receiver address.
  /// @param sourceTokenAmounts List of tokens and amount values to be released/minted.
  /// @param receiver The address that will receive the tokens.
  function _releaseOrMintTokens(Client.EVMTokenAmount[] memory sourceTokenAmounts, address receiver)
    internal
    returns (Client.EVMTokenAmount[] memory)
  {
    Client.EVMTokenAmount[] memory destTokenAmounts = new Client.EVMTokenAmount[](sourceTokenAmounts.length);
    for (uint256 i = 0; i < sourceTokenAmounts.length; ++i) {
      IPool pool = getPoolBySourceToken(IERC20(sourceTokenAmounts[i].token));
      _releaseOrMintToken(pool, sourceTokenAmounts[i].amount, receiver);
      destTokenAmounts[i].token = address(pool.getToken());
      destTokenAmounts[i].amount = sourceTokenAmounts[i].amount;
    }
    _removeTokens(destTokenAmounts);
    return destTokenAmounts;
  }

  // ================================================================
  // |                        Access and AFN                        |
  // ================================================================

  /// @notice Reverts as this contract should not access CCIP messages
  function ccipReceive(Client.Any2EVMMessage calldata) external pure {
    // solhint-disable-next-line reason-string
    revert();
  }

  /// @notice Support querying whether health checker is healthy.
  function isAFNHealthy() external view returns (bool) {
    return !IAFN(s_dynamicConfig.afn).badSignalReceived();
  }

  /// @notice Ensure that the AFN has not emitted a bad signal, and that the latest heartbeat is not stale.
  modifier whenHealthy() {
    if (IAFN(s_dynamicConfig.afn).badSignalReceived()) revert BadAFNSignal();
    _;
  }

  /// @notice Pause the contract
  /// @dev only callable by the owner
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract
  /// @dev only callable by the owner
  function unpause() external onlyOwner {
    _unpause();
  }
}
