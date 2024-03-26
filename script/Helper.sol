// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA, // 0
        OPTIMISM_GOERLI, // 1
        AVALANCHE_FUJI, // 2
        ARBITRUM_SEPOLIA, // 3
        POLYGON_MUMBAI, // 4
        BNB_CHAIN_TESTNET, // 5
        BASE_GOERLI, // 6
        OPTIMISM_SEPOLIA, // 7
        BASE_SEPOLIA // 8
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
    uint64 constant chainIdArbitrumSepolia = 3478487238524512106;
    uint64 constant chainIdPolygonMumbai = 12532609583862916517;
    uint64 constant chainIdBnbChainTestnet = 13264668187771770619;
    uint64 constant chainIdBaseGoerli = 5790810961207155433;
    uint64 constant chainIdOptimismSepolia = 5224473277236331295;
    uint64 constant chainIdBaseSepolia = 10344971235874465080;

    // Router addresses
    address constant routerEthereumSepolia =
        0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant routerOptimismGoerli =
        0xcc5a0B910D9E9504A7561934bed294c51285a78D;
    address constant routerAvalancheFuji =
        0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address constant routerArbitrumSepolia =
        0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant routerPolygonMumbai =
        0x1035CabC275068e0F4b745A29CEDf38E13aF41b1;
    address constant routerBnbChainTestnet =
        0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f;
    address constant routerBaseGoerli =
        0x80AF2F44ed0469018922c9F483dc5A909862fdc2;
    address constant routerOptimismSepolia =
        0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
    address constant routerBaseSepolia =
        0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkOptimismGoerli =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
    address constant linkAvalancheFuji =
        0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant linkArbitrumSepolia =
        0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    address constant linkPolygonMumbai =
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant linkBnbChainTestnet =
        0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    address constant linkBaseGoerli =
        0xD886E2286Fd1073df82462ea1822119600Af80b6;
    address constant linkOptimismSepolia =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address constant linkBaseSepolia =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410;

    // Wrapped native addresses
    address constant wethEthereumSepolia =
        0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wethOptimismGoerli =
        0x4200000000000000000000000000000000000006;
    address constant wavaxAvalancheFuji =
        0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address constant wethArbitrumSepolia =
        0xE591bf0A0CF924A0674d7792db046B23CEbF5f34;
    address constant wmaticPolygonMumbai =
        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address constant wbnbBnbChainTestnet =
        0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant wethBaseGoerli =
        0x4200000000000000000000000000000000000006;
    address constant wethOptimismSepolia =
        0x4200000000000000000000000000000000000006;
    address constant wethBaseSepolia =
        0x4200000000000000000000000000000000000006;

    // CCIP-BnM addresses
    address constant ccipBnMEthereumSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMOptimismGoerli =
        0xaBfE9D11A2f1D61990D1d253EC98B5Da00304F16;
    address constant ccipBnMArbitrumSepolia =
        0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant ccipBnMAvalancheFuji =
        0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address constant ccipBnMPolygonMumbai =
        0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40;
    address constant ccipBnMBnbChainTestnet =
        0xbFA2ACd33ED6EEc0ed3Cc06bF1ac38d22b36B9e9;
    address constant ccipBnMBaseGoerli =
        0xbf9036529123DE264bFA0FC7362fE25B650D4B16;
    address constant ccipBnMOptimismSepolia =
        0x8aF4204e30565DF93352fE8E1De78925F6664dA7;
    address constant ccipBnMBaseSepolia =
        0x88A2d74F47a237a62e7A51cdDa67270CE381555e;

    // CCIP-LnM addresses
    address constant ccipLnMEthereumSepolia =
        0x466D489b6d36E7E3b824ef491C225F5830E81cC1;
    address constant clCcipLnMOptimismGoerli =
        0x835833d556299CdEC623e7980e7369145b037591;
    address constant clCcipLnMArbitrumSepolia =
        0x139E99f0ab4084E14e6bb7DacA289a91a2d92927;
    address constant clCcipLnMAvalancheFuji =
        0x70F5c5C40b873EA597776DA2C21929A8282A3b35;
    address constant clCcipLnMPolygonMumbai =
        0xc1c76a8c5bFDE1Be034bbcD930c668726E7C1987;
    address constant clCcipLnMBnbChainTestnet =
        0x79a4Fc27f69323660f5Bfc12dEe21c3cC14f5901;
    address constant clCcipLnMBaseGoerli =
        0x73ed16c1a61b098fd6924CCE5cC6a9A30348D944;
    address constant clCcipLnMOptimismSepolia =
        0x044a6B4b561af69D2319A2f4be5Ec327a6975D0a;
    address constant clCcipLnMBaseSepolia =
        0xA98FA8A008371b9408195e52734b1768c0d1Cb5c;

    // USDC addresses
    address constant usdcOptimismGoerli =
        0xe05606174bac4A6364B31bd0eCA4bf4dD368f8C6;
    address constant usdcAvalancheFuji =
        0x5425890298aed601595a70AB815c96711a31Bc65;
    address constant usdcPolygonMumbai =
        0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97;
    address constant usdcBaseGoerli =
        0xF175520C52418dfE19C8098071a252da48Cd1C19;
    address constant usdcOptimismSepolia =
        0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
    address constant usdcBaseSepolia =
        0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    // GHO Addresses
    address constant ghoEthereumSepolia =
        0xc4bF5CbDaBE595361438F8c6a187bDc330539c60;
    address constant ghoArbitrumSepolia =
        0xb13Cfa6f8B2Eed2C37fB00fF0c1A59807C585810;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.OPTIMISM_GOERLI] = "Optimism Goerli";
        networks[SupportedNetworks.AVALANCHE_FUJI] = "Avalanche Fuji";
        networks[SupportedNetworks.ARBITRUM_SEPOLIA] = "Arbitrum Sepolia";
        networks[SupportedNetworks.POLYGON_MUMBAI] = "Polygon Mumbai";
        networks[SupportedNetworks.BNB_CHAIN_TESTNET] = "BNB Chain Testnet";
        networks[SupportedNetworks.BASE_GOERLI] = "Base Goerli";
        networks[SupportedNetworks.OPTIMISM_SEPOLIA] = "Optimism Sepolia";
        networks[SupportedNetworks.BASE_SEPOLIA] = "Base Sepolia";
    }

    function getDummyTokensFromNetwork(
        SupportedNetworks network
    ) internal pure returns (address ccipBnM, address ccipLnM) {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (ccipBnMEthereumSepolia, ccipLnMEthereumSepolia);
        } else if (network == SupportedNetworks.OPTIMISM_GOERLI) {
            return (ccipBnMOptimismGoerli, clCcipLnMOptimismGoerli);
        } else if (network == SupportedNetworks.ARBITRUM_SEPOLIA) {
            return (ccipBnMArbitrumSepolia, clCcipLnMArbitrumSepolia);
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (ccipBnMAvalancheFuji, clCcipLnMAvalancheFuji);
        } else if (network == SupportedNetworks.POLYGON_MUMBAI) {
            return (ccipBnMPolygonMumbai, clCcipLnMPolygonMumbai);
        } else if (network == SupportedNetworks.BNB_CHAIN_TESTNET) {
            return (ccipBnMBnbChainTestnet, clCcipLnMBnbChainTestnet);
        } else if (network == SupportedNetworks.BASE_GOERLI) {
            return (ccipBnMBaseGoerli, clCcipLnMBaseGoerli);
        } else if (network == SupportedNetworks.OPTIMISM_SEPOLIA) {
            return (ccipBnMOptimismSepolia, clCcipLnMOptimismSepolia);
        } else if (network == SupportedNetworks.BASE_GOERLI) {
            return (ccipBnMBaseSepolia, clCcipLnMBaseSepolia);
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
        } else if (network == SupportedNetworks.ARBITRUM_SEPOLIA) {
            return (
                routerArbitrumSepolia,
                linkArbitrumSepolia,
                wethArbitrumSepolia,
                chainIdArbitrumSepolia
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
        } else if (network == SupportedNetworks.BNB_CHAIN_TESTNET) {
            return (
                routerBnbChainTestnet,
                linkBnbChainTestnet,
                wbnbBnbChainTestnet,
                chainIdBnbChainTestnet
            );
        } else if (network == SupportedNetworks.BASE_GOERLI) {
            return (
                routerBaseGoerli,
                linkBaseGoerli,
                wethBaseGoerli,
                chainIdBaseGoerli
            );
        } else if (network == SupportedNetworks.OPTIMISM_SEPOLIA) {
            return (
                routerOptimismSepolia,
                linkOptimismSepolia,
                wethOptimismSepolia,
                chainIdOptimismSepolia
            );
        } else if (network == SupportedNetworks.BASE_SEPOLIA) {
            return (
                routerBaseSepolia,
                linkBaseSepolia,
                wethBaseSepolia,
                chainIdBaseSepolia
            );
        }
    }
}
