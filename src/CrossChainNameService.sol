// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IRouterClient} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "chainlink-ccip/contracts/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "chainlink-ccip/contracts/src/v0.8/ccip/models/Client.sol";
import {IERC165} from "chainlink-ccip/contracts/src/v0.8/vendor/IERC165.sol";

interface ICrossChainNameServiceLookup {
    function register(string memory _name, address _address) external;
}

contract CrossChainNameServiceRegister {
    IRouterClient private immutable i_router;
    ICrossChainNameServiceLookup private immutable i_lookup;
    address private immutable i_ccnsReceiverOptimismGoerli;
    address private immutable i_ccnsReceiverAvalancheFuji;

    uint64 constant OPTIMISM_GOERLI_CHAIN_ID = 420;
    uint64 constant AVALANCHE_FUJI_CHAIN_ID = 43113;

    error InvalidRouter(address router);

    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }

    constructor(
        address router,
        address lookup,
        address ccnsReceiverOptimismGoerli,
        address ccnsReceiverAvalancheFuji
    ) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = IRouterClient(router);
        i_lookup = ICrossChainNameServiceLookup(lookup);
        i_ccnsReceiverOptimismGoerli = ccnsReceiverOptimismGoerli;
        i_ccnsReceiverAvalancheFuji = ccnsReceiverAvalancheFuji;
    }

    function register(string memory _name) external {
        bytes memory data = abi.encode(_name, msg.sender);

        // Sepolia -> Optimism Goerli

        Client.EVM2AnyMessage memory messageToOptimismGoerli = Client
            .EVM2AnyMessage({
                receiver: abi.encode(i_ccnsReceiverOptimismGoerli),
                data: data,
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                ),
                feeToken: address(0) // We leave the feeToken empty indicating we'll pay raw native.
            });

        i_router.ccipSend{
            value: i_router.getFee(
                OPTIMISM_GOERLI_CHAIN_ID,
                messageToOptimismGoerli
            )
        }(OPTIMISM_GOERLI_CHAIN_ID, messageToOptimismGoerli);

        // Sepolia -> Avalanche Fuji

        Client.EVM2AnyMessage memory messageToAvalancheFuji = Client
            .EVM2AnyMessage({
                receiver: abi.encode(i_ccnsReceiverAvalancheFuji),
                data: data,
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                ),
                feeToken: address(0) // We leave the feeToken empty indicating we'll pay raw native.
            });

        i_router.ccipSend{
            value: i_router.getFee(
                AVALANCHE_FUJI_CHAIN_ID,
                messageToAvalancheFuji
            )
        }(AVALANCHE_FUJI_CHAIN_ID, messageToAvalancheFuji);
    }

    function getRouterAddress() external view returns (address) {
        return address(i_router);
    }
}

/**
 * @notice CCIP Showcase Project, DO NOT USE IN PRODUCTION
 */
contract CrossChainNameServiceReceiver is IAny2EVMMessageReceiver, IERC165 {
    IRouterClient private immutable i_router;
    ICrossChainNameServiceLookup private immutable i_lookup;
    // uint256 private commitReveal = 1;

    uint64 constant SEPOLIA_CHAIN_ID = 11155111;

    error InvalidRouter(address router);
    error InvalidSourceChain(uint64 chainId);

    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }

    modifier onlyFromSepolia(uint64 chainId) {
        if (chainId != SEPOLIA_CHAIN_ID) revert InvalidSourceChain(chainId);
        _;
    }

    constructor(address router, address lookup) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = IRouterClient(router);
        i_lookup = ICrossChainNameServiceLookup(lookup);
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external override onlyRouter onlyFromSepolia(message.sourceChainId) {
        // commitReveal = 1;
        (string memory _name, address _address) = abi.decode(
            message.data,
            (string, address)
        );

        i_lookup.register(_name, _address);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getRouterAddress() external view returns (address) {
        return address(i_router);
    }
}

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
