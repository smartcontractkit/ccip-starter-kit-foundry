// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPolicyEngine} from "@chainlink/policy-management/interfaces/IPolicyEngine.sol";
import {IAdvancedPoolHooks} from "@chainlink/contracts-ccip/contracts/interfaces/IAdvancedPoolHooks.sol";
import {Pool} from "@chainlink/contracts-ccip/contracts/libraries/Pool.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts@5.3.0/access/Ownable2Step.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/// @notice Minimal example policy engine for Example10: rejects transfers whose amount exceeds a cap.
/// @dev Implements the `IPolicyEngine` surface `AdvancedPoolHooks` calls (`attach`, `detach`, `run`).
///      The hook passes its own `preflightCheck`/`postflightCheck` calldata (minus the selector) as
///      `payload.data`, so this engine decodes the transfer amount from the hook call and enforces a
///      simple cap. The remaining interface methods are stubbed out empty, as this engine has a
///      single built-in policy. For production-grade policy engines, use Chainlink ACE
///      (https://chainlink.tech/ace).
contract ExamplePolicyEngine is IPolicyEngine, Ownable2Step {
    error NotAttached(address target);
    error AlreadyAttached(address target);
    error AmountExceedsCap(uint256 amount, uint256 cap);

    event CapUpdated(uint256 oldCap, uint256 newCap);

    uint256 internal s_cap;
    mapping(address target => bool attached) internal s_attached;

    constructor() Ownable(msg.sender) {
        s_cap = 10 ether;
    }

    // ----------------------------------------------------------------
    // Attachment
    // ----------------------------------------------------------------

    function typeAndVersion() external pure override returns (string memory) {
        return "ExamplePolicyEngine 1.0.0";
    }

    function attach() external override {
        if (s_attached[msg.sender]) revert AlreadyAttached(msg.sender);
        s_attached[msg.sender] = true;
        emit TargetAttached(msg.sender);
    }

    function detach() external override {
        if (!s_attached[msg.sender]) revert NotAttached(msg.sender);
        s_attached[msg.sender] = false;
        emit TargetDetached(msg.sender);
    }

    function isAttached(address target) external view returns (bool) {
        return s_attached[target];
    }

    // ----------------------------------------------------------------
    // Built-in policy: reject transfers above the cap
    // ----------------------------------------------------------------

    /// @notice Sets the maximum transfer amount this engine allows.
    function setCap(uint256 newCap) external onlyOwner {
        emit CapUpdated(s_cap, newCap);
        s_cap = newCap;
    }

    function getCap() external view returns (uint256) {
        return s_cap;
    }

    /// @notice Runs the built-in policy: rejects transfers above the cap.
    /// @dev `msg.sender` is the hook that called `run`, and `payload.data` is the hook's
    ///      `preflightCheck`/`postflightCheck` calldata minus the selector. The amount checked is the
    ///      post-fee amount on the source side and the local amount on the destination side, matching
    ///      `AdvancedPoolHooksExtractor`.
    function run(Payload calldata payload) external override {
        _check(payload);
    }

    /// @notice Offchain pre-validation view. The built-in policy has no state changes, so it mirrors `run`.
    function check(Payload calldata payload) external view override {
        _check(payload);
    }

    function _check(Payload calldata payload) internal view {
        if (!s_attached[msg.sender]) revert NotAttached(msg.sender);

        uint256 amount;
        if (payload.selector == IAdvancedPoolHooks.preflightCheck.selector) {
            (,,, uint256 amountPostFee) = abi.decode(payload.data, (Pool.LockOrBurnInV1, bytes4, bytes, uint256));
            amount = amountPostFee;
        } else if (payload.selector == IAdvancedPoolHooks.postflightCheck.selector) {
            (, uint256 localAmount,) = abi.decode(payload.data, (Pool.ReleaseOrMintInV1, uint256, bytes4));
            amount = localAmount;
        } else {
            revert UnsupportedSelector(payload.selector);
        }

        if (amount > s_cap) revert AmountExceedsCap(amount, s_cap);
    }

    // ----------------------------------------------------------------
    // Unused IPolicyEngine surface, stubbed empty (single built-in policy)
    // ----------------------------------------------------------------

    function setExtractor(bytes4, address) external override {}

    function setExtractors(bytes4[] calldata, address) external override {}

    function getExtractor(bytes4) external pure override returns (address) {
        return address(0);
    }

    function setPolicyMapper(address, address) external override {}

    function getPolicyMapper(address) external pure override returns (address) {
        return address(0);
    }

    function addPolicy(address, bytes4, address, bytes32[] calldata) external override {}

    function addPolicyAt(address, bytes4, address, bytes32[] calldata, uint256) external override {}

    function removePolicy(address, bytes4, address) external override {}

    function getPolicies(address, bytes4) external pure override returns (address[] memory) {
        return new address[](0);
    }

    function setPolicyConfiguration(address, uint256, bytes4, bytes calldata) external override {}

    function getPolicyConfigVersion(address) external pure override returns (uint256) {
        return 0;
    }

    function setDefaultPolicyAllow(bool) external override {}

    function setTargetDefaultPolicyAllow(address, bool) external override {}
}
