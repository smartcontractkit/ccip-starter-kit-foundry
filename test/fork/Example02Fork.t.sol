// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {BasicMessageReceiver} from "../../src/BasicMessageReceiver.sol";

import "forge-std/console.sol";

contract Example02ForkTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 public sourceFork;
    uint256 public destinationFork;
    address public alice;
    BasicMessageReceiver public basicMessageReceiver;
    IRouterClient public destinationRouter;
    IRouterClient public sourceRouter;
    uint64 public destinationChainSelector;

    BurnMintERC677Helper public sourceCCIPBnMToken;
    BurnMintERC677Helper public destinationCCIPBnMToken;
    IERC20 public sourceLinkToken;

    function setUp() public {
        string memory DESTINATION_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory SOURCE_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

        sourceFork = vm.createFork(SOURCE_RPC_URL);
        destinationFork = vm.createFork(DESTINATION_RPC_URL);

        alice = makeAddr("alice"); // Sender.

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        vm.selectFork(destinationFork);
        Register.NetworkDetails memory destinationNetworkDetails =
            ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        destinationCCIPBnMToken = BurnMintERC677Helper(destinationNetworkDetails.ccipBnMAddress);
        destinationChainSelector = destinationNetworkDetails.chainSelector;
        destinationRouter = IRouterClient(destinationNetworkDetails.routerAddress);

        basicMessageReceiver = new BasicMessageReceiver(address(destinationRouter)); // Receiver

        vm.selectFork(sourceFork);
        Register.NetworkDetails memory sourceNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        sourceCCIPBnMToken = BurnMintERC677Helper(sourceNetworkDetails.ccipBnMAddress);
        sourceLinkToken = IERC20(sourceNetworkDetails.linkAddress);
        sourceRouter = IRouterClient(sourceNetworkDetails.routerAddress);
    }

    function buildSendTokenData()
        public
        returns (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend)
    {
        amountToSend = 100;

        vm.selectFork(sourceFork);

        vm.startPrank(alice);
        sourceCCIPBnMToken.drip(alice);
        sourceCCIPBnMToken.approve(address(sourceRouter), amountToSend);

        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0] = Client.EVMTokenAmount({token: address(sourceCCIPBnMToken), amount: amountToSend});

        vm.stopPrank();
    }

    function test_transferTokensEoaToContractPayFeesInLink() external {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = buildSendTokenData();

        vm.selectFork(destinationFork);
        uint256 receiverContractBalanceBefore = destinationCCIPBnMToken.balanceOf(address(basicMessageReceiver));

        vm.selectFork(sourceFork);
        uint256 aliceBalanceBefore = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(aliceBalanceBefore, 1e18);

        ccipLocalSimulatorFork.requestLinkFromFaucet(alice, 10 ether);

        vm.startPrank(alice);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(basicMessageReceiver),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 100_000})),
            feeToken: address(sourceLinkToken)
        });

        uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
        sourceLinkToken.approve(address(sourceRouter), fees);

        sourceRouter.ccipSend(destinationChainSelector, message);
        vm.stopPrank();

        uint256 aliceBalanceAfter = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(aliceBalanceBefore - amountToSend, aliceBalanceAfter);
        assertEq(sourceLinkToken.balanceOf(alice), 10 ether - fees);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);

        uint256 receiverContractBalanceAfter = destinationCCIPBnMToken.balanceOf(address(basicMessageReceiver));
        assertEq(receiverContractBalanceAfter, receiverContractBalanceBefore + amountToSend);
    }

    function test_transferTokensFromEoaToContractPayFeesInNative() external {
        (Client.EVMTokenAmount[] memory tokensToSendDetails, uint256 amountToSend) = buildSendTokenData();

        vm.selectFork(destinationFork);
        uint256 receiverContractBalanceBefore = destinationCCIPBnMToken.balanceOf(address(basicMessageReceiver));

        vm.selectFork(sourceFork);
        uint256 aliceBalanceBefore = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(aliceBalanceBefore, 1e18);

        ccipLocalSimulatorFork.requestLinkFromFaucet(alice, 10 ether);

        vm.startPrank(alice);
        deal(alice, 5 ether);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(basicMessageReceiver),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 100_000})),
            feeToken: address(0)
        });

        uint256 fees = sourceRouter.getFee(destinationChainSelector, message);

        sourceRouter.ccipSend{value: fees}(destinationChainSelector, message);
        vm.stopPrank();

        uint256 aliceBalanceAfter = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(aliceBalanceBefore - amountToSend, aliceBalanceAfter);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);

        uint256 receiverContractBalanceAfter = destinationCCIPBnMToken.balanceOf(address(basicMessageReceiver));
        assertEq(receiverContractBalanceAfter, receiverContractBalanceBefore + amountToSend);
    }
}
