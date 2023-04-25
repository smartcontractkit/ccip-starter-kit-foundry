// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "chainlink-ccip/contracts/src/v0.8/ccip/test/onRamp/EVM2EVMOnRampSetup.t.sol";
import "chainlink-ccip/contracts/src/v0.8/ccip/models/Client.sol";

import {CrossChainNameServiceLookup} from "../src/CrossChainNameServiceLookup.sol";
import {CrossChainNameServiceRegister} from "../src/CrossChainNameServiceRegister.sol";
import {CrossChainNameServiceReceiver} from "../src/CrossChainNameServiceReceiver.sol";

contract CrossChainNameServiceTest is EVM2EVMOnRampSetup {
    // Source Chain:
    CrossChainNameServiceLookup sourceChainLookup;
    CrossChainNameServiceRegister sourceChainRegister;

    // Destination Chain:
    CrossChainNameServiceLookup destinationChainLookup;
    CrossChainNameServiceReceiver destinationChainReceiver;

    address alice;

    function setUp() public virtual override {
        alice = makeAddr("alice");

        EVM2EVMOnRampSetup.setUp();

        sourceChainLookup = new CrossChainNameServiceLookup();
        sourceChainRegister = new CrossChainNameServiceRegister(
            address(s_sourceRouter),
            address(sourceChainLookup)
        );

        destinationChainLookup = new CrossChainNameServiceLookup();
        destinationChainReceiver = new CrossChainNameServiceReceiver(
            address(s_sourceRouter),
            address(destinationChainLookup),
            SOURCE_CHAIN_ID
        );

        deal(address(sourceChainRegister), 100 ether);

        changePrank(sourceChainLookup.owner());
        sourceChainLookup.setCrossChainNameServiceAddress(
            address(sourceChainRegister)
        );

        changePrank(sourceChainRegister.owner());
        sourceChainRegister.enableChain(
            DEST_CHAIN_ID,
            address(destinationChainReceiver),
            false,
            GAS_LIMIT
        );

        changePrank(destinationChainLookup.owner());
        destinationChainLookup.setCrossChainNameServiceAddress(
            address(destinationChainReceiver)
        );

        assertTrue(
            ERC165Checker.supportsInterface(
                address(destinationChainReceiver),
                type(IAny2EVMMessageReceiver).interfaceId
            )
        );
    }

    function testRegister() external {
        changePrank(alice);
        sourceChainRegister.register("alice.ccns");

        address aliceccnsSource = sourceChainLookup.lookup("alice.ccns");
        assertEq(alice, aliceccnsSource);

        changePrank(address(s_sourceRouter));
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(""),
            sourceChainId: SOURCE_CHAIN_ID,
            sender: abi.encode(sourceChainRegister),
            data: abi.encode("alice.ccns", alice),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        destinationChainReceiver.ccipReceive(message);

        address aliceccnsDestination = destinationChainLookup.lookup(
            "alice.ccns"
        );
        assertEq(alice, aliceccnsDestination);
    }
}
