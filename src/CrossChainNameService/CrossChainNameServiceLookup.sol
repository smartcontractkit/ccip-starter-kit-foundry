// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CrossChainNameServiceLookup {
    mapping(string => address) public lookup;

    address internal immutable i_crossChainNameService;

    error Unauthorized();
    error AlreadyTaken();

    modifier onlyCrossChainNameService() {
        if (msg.sender != i_crossChainNameService) revert Unauthorized();
        _;
    }

    constructor(address crossChainNameService) {
        i_crossChainNameService = crossChainNameService;
    }

    function register(
        string memory _name,
        address _address
    ) external onlyCrossChainNameService {
        if (lookup[_name] != address(0)) revert AlreadyTaken();

        lookup[_name] = _address;
    }
}
