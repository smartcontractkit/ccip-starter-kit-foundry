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
import {BasicMessageReceiver} from "../../src/BasicMessageReceiver.sol";

contract Example02Test is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    BasicMessageReceiver public basicMessageReceiver;
    address public alice;

    IRouterClient public router;
    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;
    LinkToken public linkToken;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            ,
            LinkToken link,
            BurnMintERC677Helper ccipBnM,
        ) = ccipLocalSimulator.configuration();

        router = sourceRouter;
        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
        linkToken = link;

        basicMessageReceiver = new BasicMessageReceiver(address(destinationRouter));

        alice = makeAddr("alice");
    }

    function test_TransferTokensFromEoaToSmartContract() external {
        ccipLocalSimulator.requestLinkFromFaucet(alice, 5 ether);
        ccipBnMToken.drip(alice);
        uint256 balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfReceiverBefore = ccipBnMToken.balanceOf(address(basicMessageReceiver));
        assertEq(balanceOfAliceBefore, 1 ether);

        vm.startPrank(alice);

        uint256 amount = 100;
        ccipBnMToken.approve(address(router), amount);

        Client.EVMTokenAmount[] memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
            Client.EVMTokenAmount({token: address(ccipBnMToken), amount: amount});

        tokensToSendDetails[0] = tokenToSendDetails;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(basicMessageReceiver),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken: address(linkToken)
        });

        uint256 fees = router.getFee(destinationChainSelector, message);
        linkToken.approve(address(router), fees);

        router.ccipSend(destinationChainSelector, message);

        vm.stopPrank();

        uint256 balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        uint256 balanceOfReceiverAfter = ccipBnMToken.balanceOf(address(basicMessageReceiver));
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amount);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amount);
    }
}
