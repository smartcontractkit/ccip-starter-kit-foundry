// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICrossChainNameServiceLookup {
    function register(string memory _name, address _address) external;
}
