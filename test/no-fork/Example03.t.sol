// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {BasicTokenSender} from "../../src/BasicTokenSender.sol";

contract Example03Test is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    BasicTokenSender public basicTokenSender;
    address public alice;
    address public bob;

    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (uint64 chainSelector, IRouterClient sourceRouter,,, LinkToken link, BurnMintERC677Helper ccipBnM,) =
            ccipLocalSimulator.configuration();

        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;

        basicTokenSender = new BasicTokenSender(address(sourceRouter), address(link));

        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function prepareScenario()
        public
        returns (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend)
    {
        vm.startPrank(alice);

        ccipBnMToken.drip(alice);

        amountToSend = 100;
        ccipBnMToken.approve(address(basicTokenSender), amountToSend);

        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
            Client.EVMTokenAmount({token: address(ccipBnMToken), amount: amountToSend});
        tokensToSendDetails[0] = tokenToSendDetails;

        vm.stopPrank();
    }

    function test_transferTokensFromSmartContractAndPayFeesInLink() external {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = prepareScenario();

        uint256 balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobBefore = ccipBnMToken.balanceOf(bob);

        vm.startPrank(alice);
        ccipLocalSimulator.requestLinkFromFaucet(address(basicTokenSender), 5 ether);
        basicTokenSender.send(destinationChainSelector, bob, tokensToSendDetails, BasicTokenSender.PayFeesIn.LINK);
        vm.stopPrank();

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobAfter = ccipBnMToken.balanceOf(bob);

        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }

    function test_transferTokensFromSmartContractAndPayFeesInNative() external {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = prepareScenario();

        uint256 balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobBefore = ccipBnMToken.balanceOf(bob);

        vm.startPrank(alice);
        deal(address(basicTokenSender), 5 ether);
        basicTokenSender.send(destinationChainSelector, bob, tokensToSendDetails, BasicTokenSender.PayFeesIn.Native);
        vm.stopPrank();

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfBobAfter = ccipBnMToken.balanceOf(bob);

        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }
}
