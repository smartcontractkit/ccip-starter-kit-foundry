// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA, // 0
        AVALANCHE_FUJI, // 1
        ARBITRUM_SEPOLIA, // 2
        POLYGON_AMOY, // 3
        BNB_CHAIN_TESTNET, // 4
        OPTIMISM_SEPOLIA, // 5
        BASE_SEPOLIA, // 6
        WEMIX_TESTNET, // 7
        KROMA_SEPOLIA_TESTNET, // 8
        METIS_SEPOLIA, // 9
        ZKSYNC_SEPOLIA, // 10
        SCROLL_SEPOLIA // 11
    }

    mapping(SupportedNetworks enumValue => string humanReadableName)
        public networks;

    enum PayFeesIn {
        Native, // 0
        LINK // 1
    }

    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    uint64 constant chainIdAvalancheFuji = 14767482510784806043;
    uint64 constant chainIdArbitrumSepolia = 3478487238524512106;
    uint64 constant chainIdPolygonAmoy = 16281711391670634445;
    uint64 constant chainIdBnbChainTestnet = 13264668187771770619;
    uint64 constant chainIdOptimismSepolia = 5224473277236331295;
    uint64 constant chainIdBaseSepolia = 10344971235874465080;
    uint64 constant chainIdWemixTestnet = 9284632837123596123;
    uint64 constant chainIdKromaSepoliaTestnet = 5990477251245693094;
    uint64 constant chainIdMetisSepolia = 3777822886988675105;
    uint64 constant chainIdZksyncSepolia = 6898391096552792247;
    uint64 constant chainIdScrollSepolia = 2279865765895943307;

    // Router addresses
    address constant routerEthereumSepolia =
        0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant routerAvalancheFuji =
        0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address constant routerArbitrumSepolia =
        0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant routerPolygonAmoy =
        0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2;
    address constant routerBnbChainTestnet =
        0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f;
    address constant routerOptimismSepolia =
        0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
    address constant routerBaseSepolia =
        0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
    address constant routerWemixTestnet = 
        0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant routerKromaSepoliaTestnet =
        0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant routerMetisSepolia =
        0xaCdaBa07ECad81dc634458b98673931DD9d3Bc14;
    address constant routerZksyncSepolia =
        0xA1fdA8aa9A8C4b945C45aD30647b01f07D7A0B16;
    address constant routerScrollSepolia =
        0x6aF501292f2A33C81B9156203C9A66Ba0d8E3D21;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkAvalancheFuji =
        0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant linkArbitrumSepolia =
        0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    address constant linkPolygonAmoy =
        0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;
    address constant linkBnbChainTestnet =
        0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    address constant linkOptimismSepolia =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address constant linkBaseSepolia =
        0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address constant linkWemixTestnet =
        0x3580c7A817cCD41f7e02143BFa411D4EeAE78093;
    address constant linkKromaSepoliaTestnet =
        0xa75cCA5b404ec6F4BB6EC4853D177FE7057085c8;
    address constant linkMetisSepolia =
        0x9870D6a0e05F867EAAe696e106741843F7fD116D;
    address constant linkZksyncSepolia =
        0x23A1aFD896c8c8876AF46aDc38521f4432658d1e;
    address constant linkScrollSepolia =
        0x7273ebbB21F8D8AcF2bC12E71a08937712E9E40c;

    // Wrapped native addresses
    address constant wethEthereumSepolia =
        0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wavaxAvalancheFuji =
        0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address constant wethArbitrumSepolia =
        0xE591bf0A0CF924A0674d7792db046B23CEbF5f34;
    address constant wmaticPolygonAmoy =
        0x360ad4f9a9A8EFe9A8DCB5f461c4Cc1047E1Dcf9;
    address constant wbnbBnbChainTestnet =
        0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant wethOptimismSepolia =
        0x4200000000000000000000000000000000000006;
    address constant wethBaseSepolia =
        0x4200000000000000000000000000000000000006;
    address constant wwemixWemixTestnet =
        0xbE3686643c05f00eC46e73da594c78098F7a9Ae7;
    address constant wethKromaSepoliaTestnet = 
        0x4200000000000000000000000000000000000001;
    address constant wethMetisSepolia =
        0x5c48e07062aC4E2Cf4b9A768a711Aef18e8fbdA0;
    address constant wethZksyncSepolia =
        0x4317b2eCD41851173175005783322D29E9bAee9E;
    address constant wethScrollSepolia =
        0x5300000000000000000000000000000000000004;

    // CCIP-BnM addresses
    address constant ccipBnMEthereumSepolia =
        0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMArbitrumSepolia =
        0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant ccipBnMAvalancheFuji =
        0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address constant ccipBnMPolygonAmoy =
        0xcab0EF91Bee323d1A617c0a027eE753aFd6997E4;
    address constant ccipBnMBnbChainTestnet =
        0xbFA2ACd33ED6EEc0ed3Cc06bF1ac38d22b36B9e9;
    address constant ccipBnMOptimismSepolia =
        0x8aF4204e30565DF93352fE8E1De78925F6664dA7;
    address constant ccipBnMBaseSepolia =
        0x88A2d74F47a237a62e7A51cdDa67270CE381555e;
    address constant ccipBnMWemixTestnet =
        0xF4E4057FbBc86915F4b2d63EEFFe641C03294ffc;
    address constant ccipBnMKromaSepoliaTestnet = 
        0x6AC3e353D1DDda24d5A5416024d6E436b8817A4e;
    address constant ccipBnMMetisSepolia =
        0x20Aa09AAb761e2E600d65c6929A9fd1E59821D3f;
    address constant ccipBnMScrollSepolia =
        0x231d45b53C905c3d6201318156BDC725c9c3B9B1;

    // CCIP-LnM addresses
    address constant ccipLnMEthereumSepolia =
        0x466D489b6d36E7E3b824ef491C225F5830E81cC1;
    address constant clCcipLnMArbitrumSepolia =
        0x139E99f0ab4084E14e6bb7DacA289a91a2d92927;
    address constant clCcipLnMAvalancheFuji =
        0x70F5c5C40b873EA597776DA2C21929A8282A3b35;
    address constant clCcipLnMPolygonAmoy =
        0x3d357fb52253e86c8Ee0f80F5FfE438fD9503FF2;
    address constant clCcipLnMBnbChainTestnet =
        0x79a4Fc27f69323660f5Bfc12dEe21c3cC14f5901;
    address constant clCcipLnMOptimismSepolia =
        0x044a6B4b561af69D2319A2f4be5Ec327a6975D0a;
    address constant clCcipLnMBaseSepolia =
        0xA98FA8A008371b9408195e52734b1768c0d1Cb5c;
    address constant clCcipLnMWemixTestnet =
        0xcb342aE3D65E3fEDF8F912B0432e2B8F88514d5D;
    address constant clCcipLnMKromaSepoliaTestnet = 
        0x835fcBB6770E1246CfCf52F83cDcec3177d0bb6b;
    address constant clCcipLnMMetisSepolia =
        0x705b364CadE0e515577F2646529e3A417473a155;

    // USDC addresses
    address constant usdcAvalancheFuji =
        0x5425890298aed601595a70AB815c96711a31Bc65;
    address constant usdcPolygonAmoy =
        0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;
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
        networks[SupportedNetworks.AVALANCHE_FUJI] = "Avalanche Fuji";
        networks[SupportedNetworks.ARBITRUM_SEPOLIA] = "Arbitrum Sepolia";
        networks[SupportedNetworks.POLYGON_AMOY] = "Polygon Amoy";
        networks[SupportedNetworks.BNB_CHAIN_TESTNET] = "BNB Chain Testnet";
        networks[SupportedNetworks.OPTIMISM_SEPOLIA] = "Optimism Sepolia";
        networks[SupportedNetworks.BASE_SEPOLIA] = "Base Sepolia";
        networks[SupportedNetworks.WEMIX_TESTNET] = "Wemix Testnet";
        networks[SupportedNetworks.KROMA_SEPOLIA_TESTNET] = "Kroma Sepolia Testnet";
        networks[SupportedNetworks.METIS_SEPOLIA] = "Metis Sepolia";
        networks[SupportedNetworks.ZKSYNC_SEPOLIA] = "zkSync Sepolia";
        networks[SupportedNetworks.SCROLL_SEPOLIA] = "Scroll Sepolia";
    }

    function getDummyTokensFromNetwork(
        SupportedNetworks network
    ) internal pure returns (address ccipBnM, address ccipLnM) {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (ccipBnMEthereumSepolia, ccipLnMEthereumSepolia);
        } else if (network == SupportedNetworks.ARBITRUM_SEPOLIA) {
            return (ccipBnMArbitrumSepolia, clCcipLnMArbitrumSepolia);
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (ccipBnMAvalancheFuji, clCcipLnMAvalancheFuji);
        } else if (network == SupportedNetworks.POLYGON_AMOY) {
            return (ccipBnMPolygonAmoy, clCcipLnMPolygonAmoy);
        } else if (network == SupportedNetworks.BNB_CHAIN_TESTNET) {
            return (ccipBnMBnbChainTestnet, clCcipLnMBnbChainTestnet);
        } else if (network == SupportedNetworks.OPTIMISM_SEPOLIA) {
            return (ccipBnMOptimismSepolia, clCcipLnMOptimismSepolia);
        } else if (network == SupportedNetworks.WEMIX_TESTNET) {
            return (ccipBnMWemixTestnet, clCcipLnMWemixTestnet);
        } else if (network == SupportedNetworks.KROMA_SEPOLIA_TESTNET) {
            return (ccipBnMKromaSepoliaTestnet, clCcipLnMKromaSepoliaTestnet);
        } else if (network == SupportedNetworks.METIS_SEPOLIA) {
            return (ccipBnMMetisSepolia, clCcipLnMMetisSepolia);
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
        } else if (network == SupportedNetworks.POLYGON_AMOY) {
            return (
                routerPolygonAmoy,
                linkPolygonAmoy,
                wmaticPolygonAmoy,
                chainIdPolygonAmoy
            );
        } else if (network == SupportedNetworks.BNB_CHAIN_TESTNET) {
            return (
                routerBnbChainTestnet,
                linkBnbChainTestnet,
                wbnbBnbChainTestnet,
                chainIdBnbChainTestnet
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
        } else if (network == SupportedNetworks.WEMIX_TESTNET) {
            return (
                routerWemixTestnet,
                linkWemixTestnet,
                wwemixWemixTestnet,
                chainIdWemixTestnet
            );
        } else if (network == SupportedNetworks.KROMA_SEPOLIA_TESTNET) {
            return (
                routerKromaSepoliaTestnet,
                linkKromaSepoliaTestnet,
                wethKromaSepoliaTestnet,
                chainIdKromaSepoliaTestnet
            );
        } else if (network == SupportedNetworks.METIS_SEPOLIA) {
            return (
                routerMetisSepolia,
                linkMetisSepolia,
                wethMetisSepolia,
                chainIdMetisSepolia
            );
        } else if (network == SupportedNetworks.ZKSYNC_SEPOLIA) {
            return (
                routerZksyncSepolia,
                linkZksyncSepolia,
                wethZksyncSepolia,
                chainIdZksyncSepolia
            );
        } else if (network == SupportedNetworks.SCROLL_SEPOLIA) {
            return (
                routerScrollSepolia,
                linkScrollSepolia,
                wethScrollSepolia,
                chainIdScrollSepolia
            );
        }
    }
}
