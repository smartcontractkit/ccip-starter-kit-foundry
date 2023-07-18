// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA,
        OPTIMISM_GOERLI,
        AVALANCHE_FUJI,
        ARBITRUM_GOERLI,
        POLYGON_MUMBAI
    }

    mapping(SupportedNetworks enumValue => string humanReadableName)
        public networks;

    enum PayFeesIn {
        Native,
        LINK
    }

    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    uint64 constant chainIdOptimismGoerli = 2664363617261496610;
    uint64 constant chainIdAvalancheFuji = 14767482510784806043;
    uint64 constant chainIdArbitrumTestnet = 6101244977088475029;
    uint64 constant chainIdPolygonMumbai = 12532609583862916517;

    // Router addresses
    address constant routerEthereumSepolia =
        0xD0daae2231E9CB96b94C8512223533293C3693Bf;
    address constant routerOptimismGoerli =
        0xEB52E9Ae4A9Fb37172978642d4C141ef53876f26;
    address constant routerAvalancheFuji =
        0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;
    address constant routerArbitrumTestnet =
        0x88E492127709447A5ABEFdaB8788a15B4567589E;
    address constant routerPolygonMumbai =
        0x70499c328e1E2a3c41108bd3730F6670a44595D1;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkOptimismGoerli =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
    address constant linkAvalancheFuji =
        0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant linkArbitrumTestnet =
        0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;
    address constant linkPolygonMumbai =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // Wrapped native addresses
    address constant wethEthereumSepolia =
        0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wethOptimismGoerli =
        0x4200000000000000000000000000000000000006;
    address constant wavaxAvalancheFuji =
        0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address constant wethArbitrumTestnet =
        0x32d5D5978905d9c6c2D4C417F0E06Fe768a4FB5a;
    address constant wmaticPolygonMumbai =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

    // CCIP-BnM addresses
    address constant ccipBnMEthereumSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMOptimismGoerli =
        0xaBfE9D11A2f1D61990D1d253EC98B5Da00304F16;
    address constant ccipBnMArbitrumTestnet =
        0x0579b4c1C8AcbfF13c6253f1B10d66896Bf399Ef;
    address constant ccipBnMAvalancheFuji =
        0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address constant ccipBnMPolygonMumbai =
        0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40;

    // CCIP-LnM addresses
    address constant ccipLnMEthereumSepolia =
        0x466D489b6d36E7E3b824ef491C225F5830E81cC1;
    address constant clCcipLnMOptimismGoerli =
        0x835833d556299CdEC623e7980e7369145b037591;
    address constant clCcipLnMArbitrumTestnet =
        0x0E14dBe2c8e1121902208be173A3fb91Bb125CDB;
    address constant clCcipLnMAvalancheFuji =
        0x70F5c5C40b873EA597776DA2C21929A8282A3b35;
    address constant clCcipLnMPolygonMumbai =
        0xc1c76a8c5bFDE1Be034bbcD930c668726E7C1987;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.OPTIMISM_GOERLI] = "Optimism Goerli";
        networks[SupportedNetworks.AVALANCHE_FUJI] = "Avalanche Fuji";
        networks[SupportedNetworks.ARBITRUM_GOERLI] = "Arbitrum Goerli";
        networks[SupportedNetworks.POLYGON_MUMBAI] = "Polygon Mumbai";
    }

    function getDummyTokensFromNetwork(
        SupportedNetworks network
    ) internal pure returns (address ccipBnM, address ccipLnM) {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (ccipBnMEthereumSepolia, ccipLnMEthereumSepolia);
        } else if (network == SupportedNetworks.OPTIMISM_GOERLI) {
            return (ccipBnMOptimismGoerli, clCcipLnMOptimismGoerli);
        } else if (network == SupportedNetworks.ARBITRUM_GOERLI) {
            return (ccipBnMArbitrumTestnet, clCcipLnMArbitrumTestnet);
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (ccipBnMAvalancheFuji, clCcipLnMAvalancheFuji);
        } else if (network == SupportedNetworks.POLYGON_MUMBAI) {
            return (ccipBnMPolygonMumbai, clCcipLnMPolygonMumbai);
        }
    }

    function getConfigFromNetwork(
        SupportedNetworks network
    )
        internal
        pure
        returns (
            address router,
            address linkToken,
            address wrappedNative,
            uint64 chainId
        )
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (
                routerEthereumSepolia,
                linkEthereumSepolia,
                wethEthereumSepolia,
                chainIdEthereumSepolia
            );
        } else if (network == SupportedNetworks.OPTIMISM_GOERLI) {
            return (
                routerOptimismGoerli,
                linkOptimismGoerli,
                wethOptimismGoerli,
                chainIdOptimismGoerli
            );
        } else if (network == SupportedNetworks.ARBITRUM_GOERLI) {
            return (
                routerArbitrumTestnet,
                linkArbitrumTestnet,
                wethArbitrumTestnet,
                chainIdArbitrumTestnet
            );
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (
                routerAvalancheFuji,
                linkAvalancheFuji,
                wavaxAvalancheFuji,
                chainIdAvalancheFuji
            );
        } else if (network == SupportedNetworks.POLYGON_MUMBAI) {
            return (
                routerPolygonMumbai,
                linkPolygonMumbai,
                wmaticPolygonMumbai,
                chainIdPolygonMumbai
            );
        }
    }
}
