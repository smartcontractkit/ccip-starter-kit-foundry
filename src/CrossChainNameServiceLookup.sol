// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {OwnerIsCreator} from "chainlink-ccip/contracts/src/v0.8/ccip/OwnerIsCreator.sol";

/**
 * EDUCATIONAL EXAMPLE, DO NOT USE IN PRODUCTION
 */
contract CrossChainNameServiceLookup is OwnerIsCreator {
    mapping(string => address) public lookup;

    address internal s_crossChainNameService;

    event Registered(string indexed _name, address indexed _address);

    error Unauthorized();
    error AlreadyTaken();

    modifier onlyCrossChainNameService() {
        if (msg.sender != s_crossChainNameService) revert Unauthorized();
        _;
    }

    /**
     * @notice Sets the address of the Cross Chain Name Service entity
     * This entity is either CrossChainNameServiceRegister or CrossChainNameServiceReceiver contract,
     * depends on the chain this lookup contract lives
     * @param crossChainNameService - address of the Cross Chain Name Service entity - Register or Receiver
     * @dev Only Owner can call
     */
    function setCrossChainNameServiceAddress(
        address crossChainNameService
    ) external onlyOwner {
        s_crossChainNameService = crossChainNameService;
    }

    function register(
        string memory _name,
        address _address
    ) external onlyCrossChainNameService {
        if (lookup[_name] != address(0)) revert AlreadyTaken();

        lookup[_name] = _address;
    }
}
