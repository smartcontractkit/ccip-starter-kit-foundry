// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ICCVNoOpVerifierFork} from "@chainlink/local/src/test/ccip/CCVNoOpVerifier.sol";

/// @notice Fork-test double for a pool-required CCV: a no-op verifier with call counters.
/// @dev Deployed with the same salt on both forks so it exists at the same address on both chains,
///      which is what a pool-required CCV needs: the source OnRamp consults it outbound and the
///      destination OffRamp resolves `getInboundImplementation` on the same address. The counters
///      prove both sides actually consulted it. Like `CCVNoOpVerifier`, it performs no real
///      verification and must only be used on local forks.
contract CountingCCV is ICCVNoOpVerifierFork {
    bytes4 private constant IERC165_INTERFACE_ID = 0x01ffc9a7;

    uint256 public outboundConsultations;
    uint256 public inboundVerifications;

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(ICCVNoOpVerifierFork).interfaceId || interfaceId == IERC165_INTERFACE_ID;
    }

    function getFee(uint64, EVM2AnyMessage memory, bytes memory, bytes4)
        external
        pure
        override
        returns (uint16 feeUSDCents, uint32 gasForVerification, uint32 payloadSizeBytes)
    {
        return (0, 0, 0);
    }

    function forwardToVerifier(MessageV1 calldata, bytes32, address, uint256, bytes calldata)
        external
        override
        returns (bytes memory verifierData)
    {
        ++outboundConsultations;
        return "";
    }

    function verifyMessage(MessageV1 memory, bytes32, bytes memory) external override {
        ++inboundVerifications;
    }

    function getStorageLocations() external pure override returns (string[] memory storageLocations) {
        storageLocations = new string[](1);
        storageLocations[0] = "mock://ccv";
        return storageLocations;
    }

    function getInboundImplementation(bytes calldata) external view override returns (address verifierAddress) {
        return address(this);
    }

    function getOutboundImplementation(uint64, bytes memory) external view override returns (address verifierAddress) {
        return address(this);
    }
}
