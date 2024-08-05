// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulator, IRouterClient, LinkToken} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {MyNFT} from "../../src/cross-chain-nft-minter/MyNFT.sol";
import {DestinationMinter} from "../../src/cross-chain-nft-minter/DestinationMinter.sol";
import {SourceMinter} from "../../src/cross-chain-nft-minter/SourceMinter.sol";

contract Example07Test is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    MyNFT public myNFT;
    DestinationMinter public destinationMinter;
    SourceMinter public sourceMinter;

    address public alice;
    uint64 public destinationChainSelector;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            ,
            LinkToken link,
            ,

        ) = ccipLocalSimulator.configuration();

        myNFT = new MyNFT();
        destinationMinter = new DestinationMinter(
            address(destinationRouter),
            address(myNFT)
        );
        myNFT.transferOwnership(address(destinationMinter));

        sourceMinter = new SourceMinter(address(sourceRouter), address(link));

        alice = makeAddr("alice");
        destinationChainSelector = chainSelector;
    }

    function test_executeReceivedMessageAsFunctionCall() external {
        ccipLocalSimulator.requestLinkFromFaucet(
            address(sourceMinter),
            5 ether
        );

        vm.startPrank(alice);
        sourceMinter.mint(
            destinationChainSelector,
            address(destinationMinter),
            SourceMinter.PayFeesIn.LINK
        );
        vm.stopPrank();

        assertEq(myNFT.balanceOf(alice), 1);
    }
}
