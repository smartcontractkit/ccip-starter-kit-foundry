// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Helper {
    // Supported Networks
    enum SupportedNetworks {
        ETHEREUM_SEPOLIA, // 0
        AVALANCHE_FUJI, // 1
        ARBITRUM_SEPOLIA, // 2
        POLYGON_MUMBAI, // 3
        BNB_CHAIN_TESTNET, // 4
        OPTIMISM_SEPOLIA, // 5
        BASE_SEPOLIA, // 6
        WEMIX_TESTNET, // 7
        KROMA_SEPOLIA_TESTNET, // 8
        METIS_SEPOLIA, // 9
        ZKSYNC_SEPOLIA, // 10
        SCROLL_SEPOLIA, // 11
        ZIRCUIT_SEPOLIA, // 12
        XLAYER_SEPOLIA, // 13
        POLYGON_ZKEVM_SEPOLIA, // 14
        POLKADOT_ASTAR_SHIBUYA, // 15
        MANTLE_SEPOLIA, // 16
        SONEIUM_MINATO_SEPOLIA, // 17
        BSQUARED_TESTNET, // 18
        BOB_SEPOLIA, // 19
        WORLDCHAIN_SEPOLIA, // 20
        SHIBARIUM_TESTNET, // 21
        BITLAYER_TESTNET, // 22
        FANTOM_SONIC_TESTNET, // 23
        CORN_TESTNET, // 24
        HASHKEY_SEPOLIA, // 25
        INK_SEPOLIA // 26

    }

    mapping(SupportedNetworks enumValue => string humanReadableName) public networks;

    enum PayFeesIn {
        Native,
        LINK
    }

    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    uint64 constant chainIdAvalancheFuji = 14767482510784806043;
    uint64 constant chainIdArbitrumSepolia = 3478487238524512106;
    uint64 constant chainIdPolygonMumbai = 12532609583862916517;
    uint64 constant chainIdBnbChainTestnet = 13264668187771770619;
    uint64 constant chainIdOptimismSepolia = 5224473277236331295;
    uint64 constant chainIdBaseSepolia = 10344971235874465080;
    uint64 constant chainIdWemixTestnet = 9284632837123596123;
    uint64 constant chainIdKromaSepoliaTestnet = 5990477251245693094;
    uint64 constant chainIdMetisSepolia = 3777822886988675105;
    uint64 constant chainIdZksyncSepolia = 6898391096552792247;
    uint64 constant chainIdScrollSepolia = 2279865765895943307;
    uint64 constant chainIdZircuitSepolia = 4562743618362911021;
    uint64 constant chainIdXlayerSepolia = 2066098519157881736;
    uint64 constant chainIdPolygonZkevmSepolia = 1654667687261492630;
    uint64 constant chainIdPolkadotAstarShibuya = 6955638871347136141;
    uint64 constant chainIdMantleSepolia = 8236463271206331221;
    uint64 constant chainIdSoneiumMinatoSepolia = 686603546605904534;
    uint64 constant chainIdBsquaredTestnet = 1948510578179542068;
    uint64 constant chainIdBobSepolia = 5535534526963509396;
    uint64 constant chainIdWorldchainSepolia = 5299555114858065850;
    uint64 constant chainIdShibariumTestnet = 17833296867764334567;
    uint64 constant chainIdBitlayerTestnet = 3789623672476206327; // https://github.com/smartcontractkit/reference-data-directory-ccip-prod-testnet/blob/SHIP-3965/bitlayer-testnet-deployment/bitcoin-testnet-bitlayer-1/ccip/metadata.json
    uint64 constant chainIdFantomSonicTestnet = 3676871237479449268;
    uint64 constant chainIdCornTestnet = 1467427327723633929; // https://github.com/smartcontractkit/reference-data-directory-ccip-prod-testnet/blob/corn-testnet-chain/ethereum-testnet-sepolia-corn-1/ccip/metadata.json
    uint64 constant chainIdHashkeySepolia = 4356164186791070119;
    uint64 constant chainIdInkSepolia = 9763904284804119144;

    // Router addresses
    address constant routerEthereumSepolia = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address constant routerAvalancheFuji = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address constant routerArbitrumSepolia = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
    address constant routerPolygonMumbai = 0x1035CabC275068e0F4b745A29CEDf38E13aF41b1;
    address constant routerBnbChainTestnet = 0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f;
    address constant routerOptimismSepolia = 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
    address constant routerBaseSepolia = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
    address constant routerWemixTestnet = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant routerKromaSepoliaTestnet = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant routerMetisSepolia = 0xaCdaBa07ECad81dc634458b98673931DD9d3Bc14;
    address constant routerZksyncSepolia = 0xA1fdA8aa9A8C4b945C45aD30647b01f07D7A0B16;
    address constant routerScrollSepolia = 0x6aF501292f2A33C81B9156203C9A66Ba0d8E3D21;
    address constant routerZircuitSepolia = 0x20bC4Ec73C6aE9Dc71f79Eb8470c542f71441bf5;
    address constant routerXlayerSepolia = 0xc5F5330C4793AF46872a9eC15b76a007A96a4152;
    address constant routerPolygonZkevmSepolia = 0x91A7f913EEF5E3058AD1Bf8842C294f7219C7271;
    address constant routerPolkadotAstarShibuya = 0x22aE550d87eBf775E0c1fDc8881121c8A51F5903;
    address constant routerMantleSepolia = 0xFd33fd627017fEf041445FC19a2B6521C9778f86;
    address constant routerSoneiumMinatoSepolia = 0x443a1bce545d56E2c3f20ED32eA588395FFce0f4;
    address constant routerBsquaredTestnet = 0x34A49Eb641daF64d61be00Aa7F759f8225351101;
    address constant routerBobSepolia = 0x7808184405d6Cbc663764003dE21617fa640bc82;
    address constant routerWorldchainSepolia = 0x47693fc188b2c30078F142eadc2C009E8D786E8d;
    address constant routerShibariumTestnet = 0x449E234FEDF3F907b9E9Dd6BAf1ddc36664097E5;
    address constant routerBitlayerTestnet = 0x3dfbe078277609D34c8ef015c61f23A9BeDE61BB; // TODO
    address constant routerFantomSonicTestnet = 0x2fBd4659774D468Db5ca5bacE37869905d8EfA34;
    address constant routerCornTestnet = 0x9981250f56d4d0Fa9736343659B4890ebbb94110;
    address constant routerHashkeySepolia = 0x1360c71dd2458B6d4A5Ad5946d9011BafA0435d7;
    address constant routerInkSepolia = 0x17fCda531D8E43B4e2a2A2492FBcd4507a1685A1;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkAvalancheFuji = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address constant linkArbitrumSepolia = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    address constant linkPolygonMumbai = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant linkBnbChainTestnet = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06;
    address constant linkOptimismSepolia = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address constant linkBaseSepolia = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
    address constant linkWemixTestnet = 0x3580c7A817cCD41f7e02143BFa411D4EeAE78093;
    address constant linkKromaSepoliaTestnet = 0xa75cCA5b404ec6F4BB6EC4853D177FE7057085c8;
    address constant linkMetisSepolia = 0x9870D6a0e05F867EAAe696e106741843F7fD116D;
    address constant linkZksyncSepolia = 0x23A1aFD896c8c8876AF46aDc38521f4432658d1e;
    address constant linkScrollSepolia = 0x7273ebbB21F8D8AcF2bC12E71a08937712E9E40c;
    address constant linkZircuitSepolia = 0xDEE94506570cA186BC1e3516fCf4fd719C312cCD;
    address constant linkXlayerSepolia = 0x724593f6FCb0De4E6902d4C55D7C74DaA2AF0E55;
    address constant linkPolygonZkevmSepolia = 0x5576815a38A3706f37bf815b261cCc7cCA77e975;
    address constant linkPolkadotAstarShibuya = 0xe74037112db8807B3B4B3895F5790e5bc1866a29;
    address constant linkMantleSepolia = 0x22bdEdEa0beBdD7CfFC95bA53826E55afFE9DE04;
    address constant linkSoneiumMinatoSepolia = 0x7ea13478Ea3961A0e8b538cb05a9DF0477c79Cd2;
    address constant linkBsquaredTestnet = 0x436a1907D9e6a65E6db73015F08f9C66F6B63E45;
    address constant linkBobSepolia = 0xcd2AfB2933391E35e8682cbaaF75d9CA7339b183;
    address constant linkWorldchainSepolia = 0xC82Ea35634BcE95C394B6BC00626f827bB0F4801;
    address constant linkShibariumTestnet = 0x44637eEfD71A090990f89faEC7022fc74B2969aD; 
    address constant linkBitlayerTestnet = 0x2A5bACb2440BC17D53B7b9Be73512dDf92265e48; // TODO
    address constant linkFantomSonicTestnet = 0x61876F0429726D7777B46f663e1C9ab75d08Fc56;
    address constant linkCornTestnet = 0x996EfAb6011896Be832969D91E9bc1b3983cfdA1;
    address constant linkHashkeySepolia = 0x8418c4d7e8e17ab90232DC72150730E6c4b84F57;
    address constant linkInkSepolia = 0x3423C922911956b1Ccbc2b5d4f38216a6f4299b4;

    // Wrapped native addresses
    address constant wethEthereumSepolia = 0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wavaxAvalancheFuji = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address constant wethArbitrumSepolia = 0xE591bf0A0CF924A0674d7792db046B23CEbF5f34;
    address constant wmaticPolygonMumbai = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    address constant wbnbBnbChainTestnet = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant wethOptimismSepolia = 0x4200000000000000000000000000000000000006;
    address constant wethBaseSepolia = 0x4200000000000000000000000000000000000006;
    address constant wwemixWemixTestnet = 0xbE3686643c05f00eC46e73da594c78098F7a9Ae7;
    address constant wethKromaSepoliaTestnet = 0x4200000000000000000000000000000000000001;
    address constant wethMetisSepolia = 0x5c48e07062aC4E2Cf4b9A768a711Aef18e8fbdA0;
    address constant wethZksyncSepolia = 0x4317b2eCD41851173175005783322D29E9bAee9E;
    address constant wethScrollSepolia = 0x5300000000000000000000000000000000000004;
    address constant wethZircuitSepolia = 0x4200000000000000000000000000000000000006;
    address constant wokbXlayerSepolia = 0xa7b9C3a116b20bEDDdBE4d90ff97157f67F0bD97;
    address constant wethPolygonZkevmSepolia = 0x1CE28d5C81B229c77C5651feB49c4C489f8c52C4;
    address constant wsbyPolkadotAstarShibuya = 0xbd5F3751856E11f3e80dBdA567Ef91Eb7e874791;
    address constant wmntMantleSepolia = 0x19f5557E23e9914A18239990f6C70D68FDF0deD5;
    address constant wethSoneiumMinatoSepolia = 0x4200000000000000000000000000000000000006;
    address constant wbtcBsquaredTestnet = 0x4200000000000000000000000000000000000006;
    address constant wethBobSepolia = 0x4200000000000000000000000000000000000006;
    address constant wethWorldchainSepolia = 0x4200000000000000000000000000000000000006;
    address constant wboneShibariumTestnet = 0x41c3F37587EBcD46C0F85eF43E38BcfE1E70Ab56; 
    address constant wbtcBitlayerTestnet = 0x3e57d6946f893314324C975AA9CEBBdF3232967E; // TODO double check 
    address constant wethFantomSonicTestnet = 0x917FE4b784d1895187Df169aeCc687C03ba12662;
    address constant wbtcCornTestnet = 0x1cAa492a1B39D4867253FC27C4fBEE7b0DbAf575;
    address constant whskHashkeySepolia = address(0); // TODO
    address constant wethInkSepolia = 0x4200000000000000000000000000000000000006;

    // CCIP-BnM addresses
    address constant ccipBnMEthereumSepolia = 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05;
    address constant ccipBnMArbitrumSepolia = 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
    address constant ccipBnMAvalancheFuji = 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address constant ccipBnMPolygonMumbai = 0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40;
    address constant ccipBnMBnbChainTestnet = 0xbFA2ACd33ED6EEc0ed3Cc06bF1ac38d22b36B9e9;
    address constant ccipBnMOptimismSepolia = 0x8aF4204e30565DF93352fE8E1De78925F6664dA7;
    address constant ccipBnMBaseSepolia = 0x88A2d74F47a237a62e7A51cdDa67270CE381555e;
    address constant ccipBnMWemixTestnet = 0xF4E4057FbBc86915F4b2d63EEFFe641C03294ffc;
    address constant ccipBnMKromaSepoliaTestnet = 0x6AC3e353D1DDda24d5A5416024d6E436b8817A4e;
    address constant ccipBnMMetisSepolia = 0x20Aa09AAb761e2E600d65c6929A9fd1E59821D3f;
    address constant ccipBnMScrollSepolia = 0x231d45b53C905c3d6201318156BDC725c9c3B9B1;
    address constant ccipBnMZircuitSepolia = 0xB6eC69D477F8FAeDCE1c6d322a7842D1b4D1B08e;
    address constant ccipBnMPolkadotAstarShibuya = 0xc49ec0eB4beb48B8Da4cceC51AA9A5bD0D0A4c43;
    address constant ccipBnMMantleSepolia = 0xEA8cA8AE1c54faB8D185FC1fd7C2d70Bee8a417e;
    address constant ccipBnMBsquaredTestnet = 0x0643fD73C261eC4B369C3a8C5c0eC8c57485E32d;
    address constant ccipBnMBobSepolia = 0x3B7d0d0CeC08eBF8dad58aCCa4719791378b2329;
    address constant ccipBnMWorldchainSepolia = 0x8fdE0C794fDA5a7A303Ce216f79B9695a7714EcB;
    address constant ccipBnMShibariumTestnet = 0x81249b4bD91A8706eE67a2f422DB82258D4947ad; 
    address constant ccipBnMBitlayerTestnet = address(0); // TODO obtain
    address constant ccipBnMSoneiumMinatoSepolia = address(0); // TODO obtain
    address constant ccipBnMFantomSonicTestnet = 0x230c46b9a7c8929A80863bDe89082B372a4c7A99;
    address constant ccipBnMCornTestnet = 0x996EfAb6011896Be832969D91E9bc1b3983cfdA1;
    address constant ccipBnMHashkeySepolia = 0xB0F91Ce2ECAa3555D4b1fD4489bD9a207a7844f0;
    address constant ccipBnMInkSepolia = 0x414dbe1d58dd9BA7C84f7Fc0e4f82bc858675d37;

    // CCIP-LnM addresses
    address constant ccipLnMEthereumSepolia = 0x466D489b6d36E7E3b824ef491C225F5830E81cC1;
    address constant clCcipLnMArbitrumSepolia = 0x139E99f0ab4084E14e6bb7DacA289a91a2d92927;
    address constant clCcipLnMAvalancheFuji = 0x70F5c5C40b873EA597776DA2C21929A8282A3b35;
    address constant clCcipLnMPolygonMumbai = 0xc1c76a8c5bFDE1Be034bbcD930c668726E7C1987;
    address constant clCcipLnMBnbChainTestnet = 0x79a4Fc27f69323660f5Bfc12dEe21c3cC14f5901;
    address constant clCcipLnMOptimismSepolia = 0x044a6B4b561af69D2319A2f4be5Ec327a6975D0a;
    address constant clCcipLnMBaseSepolia = 0xA98FA8A008371b9408195e52734b1768c0d1Cb5c;
    address constant clCcipLnMWemixTestnet = 0xcb342aE3D65E3fEDF8F912B0432e2B8F88514d5D;
    address constant clCcipLnMKromaSepoliaTestnet = 0x835fcBB6770E1246CfCf52F83cDcec3177d0bb6b;
    address constant clCcipLnMMetisSepolia = 0x705b364CadE0e515577F2646529e3A417473a155;
    address constant clCcipLnMZircuitSepolia = 0x3210D3244B29535724e19159288323d86287195c;
    address constant clCcipLnMPolkadotAstarShibuya = 0xB9d4e1141E67ECFedC8A8139b5229b7FF2BF16F5;
    address constant clCcipLnMMantleSepolia = address(0); // TODO
    address constant clCcipLnMMantleSepoliaShibuya = 0xCdeE7708A96479f6D029741144f458B7FA807A6C;

    // USDC addresses
    address constant usdcAvalancheFuji = 0x5425890298aed601595a70AB815c96711a31Bc65;
    address constant usdcPolygonMumbai = 0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97;
    address constant usdcOptimismSepolia = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
    address constant usdcBaseSepolia = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    // GHO Addresses
    address constant ghoEthereumSepolia = 0xc4bF5CbDaBE595361438F8c6a187bDc330539c60;
    address constant ghoArbitrumSepolia = 0xb13Cfa6f8B2Eed2C37fB00fF0c1A59807C585810;

    constructor() {
        networks[SupportedNetworks.ETHEREUM_SEPOLIA] = "Ethereum Sepolia";
        networks[SupportedNetworks.AVALANCHE_FUJI] = "Avalanche Fuji";
        networks[SupportedNetworks.ARBITRUM_SEPOLIA] = "Arbitrum Sepolia";
        networks[SupportedNetworks.POLYGON_MUMBAI] = "Polygon Mumbai";
        networks[SupportedNetworks.BNB_CHAIN_TESTNET] = "BNB Chain Testnet";
        networks[SupportedNetworks.OPTIMISM_SEPOLIA] = "Optimism Sepolia";
        networks[SupportedNetworks.BASE_SEPOLIA] = "Base Sepolia";
        networks[SupportedNetworks.WEMIX_TESTNET] = "Wemix Testnet";
        networks[SupportedNetworks.KROMA_SEPOLIA_TESTNET] = "Kroma Sepolia Testnet";
        networks[SupportedNetworks.METIS_SEPOLIA] = "Metis Sepolia";
        networks[SupportedNetworks.ZKSYNC_SEPOLIA] = "zkSync Sepolia";
        networks[SupportedNetworks.SCROLL_SEPOLIA] = "Scroll Sepolia";
        networks[SupportedNetworks.ZIRCUIT_SEPOLIA] = "Zircuit Sepolia";
        networks[SupportedNetworks.XLAYER_SEPOLIA] = "Xlayer Sepolia";
        networks[SupportedNetworks.POLYGON_ZKEVM_SEPOLIA] = "Polygon ZKEVM Sepolia";
        networks[SupportedNetworks.POLKADOT_ASTAR_SHIBUYA] = "Polkadot Astar Shibuya";
        networks[SupportedNetworks.MANTLE_SEPOLIA] = "Mantle Sepolia";
        networks[SupportedNetworks.SONEIUM_MINATO_SEPOLIA] = "Soneium Minato Sepolia";
        networks[SupportedNetworks.BSQUARED_TESTNET] = "B-Squared Testnet";
        networks[SupportedNetworks.BOB_SEPOLIA] = "BoB Sepolia";
        networks[SupportedNetworks.WORLDCHAIN_SEPOLIA] = "World Chain Sepolia";
        networks[SupportedNetworks.SHIBARIUM_TESTNET] = "Shibarium Testnet";
        networks[SupportedNetworks.BITLAYER_TESTNET] = "Bitlayer Testnet";
        networks[SupportedNetworks.FANTOM_SONIC_TESTNET] = "Fantom Sonic Testnet";
        networks[SupportedNetworks.CORN_TESTNET] = "Corn Testnet";
        networks[SupportedNetworks.HASHKEY_SEPOLIA] = "Hashkey Sepolia";
        networks[SupportedNetworks.INK_SEPOLIA] = "Ink Sepolia";
    }

    function getDummyTokensFromNetwork(SupportedNetworks network)
        internal
        pure
        returns (address ccipBnM, address ccipLnM)
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (ccipBnMEthereumSepolia, ccipLnMEthereumSepolia);
        } else if (network == SupportedNetworks.ARBITRUM_SEPOLIA) {
            return (ccipBnMArbitrumSepolia, clCcipLnMArbitrumSepolia);
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (ccipBnMAvalancheFuji, clCcipLnMAvalancheFuji);
        } else if (network == SupportedNetworks.POLYGON_MUMBAI) {
            return (ccipBnMPolygonMumbai, clCcipLnMPolygonMumbai);
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
        } else if (network == SupportedNetworks.ZIRCUIT_SEPOLIA) {
            return (ccipBnMZircuitSepolia, clCcipLnMZircuitSepolia);
        } else if (network == SupportedNetworks.POLKADOT_ASTAR_SHIBUYA) {
            return (ccipBnMPolkadotAstarShibuya, clCcipLnMPolkadotAstarShibuya);
        } else if (network == SupportedNetworks.MANTLE_SEPOLIA) {
            return (ccipBnMMantleSepolia, clCcipLnMMantleSepolia);
        } else if (network == SupportedNetworks.BSQUARED_TESTNET) {
            return (ccipBnMBsquaredTestnet, address(0));
        } else if (network == SupportedNetworks.BOB_SEPOLIA) {
            return (ccipBnMBobSepolia, address(0));
        } else if (network == SupportedNetworks.WORLDCHAIN_SEPOLIA) {
            return (ccipBnMWorldchainSepolia, address(0));
        } else if (network == SupportedNetworks.SHIBARIUM_TESTNET) {
            return (ccipBnMShibariumTestnet, address(0));
        } else if (network == SupportedNetworks.BITLAYER_TESTNET) {
            return (ccipBnMBitlayerTestnet, address(0));
        } else if (network == SupportedNetworks.SONEIUM_MINATO_SEPOLIA) {
            return (ccipBnMSoneiumMinatoSepolia, address(0));
        } else if (network == SupportedNetworks.FANTOM_SONIC_TESTNET) {
            return (ccipBnMFantomSonicTestnet, address(0));
        } else if (network == SupportedNetworks.CORN_TESTNET) {
            return (ccipBnMCornTestnet, address(0));
        } else if (network == SupportedNetworks.HASHKEY_SEPOLIA) {
            return (ccipBnMHashkeySepolia, address(0));
        } else if (network == SupportedNetworks.INK_SEPOLIA) {
            return (ccipBnMInkSepolia, address(0));
        }
    }

    function getConfigFromNetwork(SupportedNetworks network)
        internal
        pure
        returns (address router, address linkToken, address wrappedNative, uint64 chainId)
    {
        if (network == SupportedNetworks.ETHEREUM_SEPOLIA) {
            return (routerEthereumSepolia, linkEthereumSepolia, wethEthereumSepolia, chainIdEthereumSepolia);
        } else if (network == SupportedNetworks.ARBITRUM_SEPOLIA) {
            return (routerArbitrumSepolia, linkArbitrumSepolia, wethArbitrumSepolia, chainIdArbitrumSepolia);
        } else if (network == SupportedNetworks.AVALANCHE_FUJI) {
            return (routerAvalancheFuji, linkAvalancheFuji, wavaxAvalancheFuji, chainIdAvalancheFuji);
        } else if (network == SupportedNetworks.POLYGON_MUMBAI) {
            return (routerPolygonMumbai, linkPolygonMumbai, wmaticPolygonMumbai, chainIdPolygonMumbai);
        } else if (network == SupportedNetworks.BNB_CHAIN_TESTNET) {
            return (routerBnbChainTestnet, linkBnbChainTestnet, wbnbBnbChainTestnet, chainIdBnbChainTestnet);
        } else if (network == SupportedNetworks.OPTIMISM_SEPOLIA) {
            return (routerOptimismSepolia, linkOptimismSepolia, wethOptimismSepolia, chainIdOptimismSepolia);
        } else if (network == SupportedNetworks.BASE_SEPOLIA) {
            return (routerBaseSepolia, linkBaseSepolia, wethBaseSepolia, chainIdBaseSepolia);
        } else if (network == SupportedNetworks.WEMIX_TESTNET) {
            return (routerWemixTestnet, linkWemixTestnet, wwemixWemixTestnet, chainIdWemixTestnet);
        } else if (network == SupportedNetworks.KROMA_SEPOLIA_TESTNET) {
            return (
                routerKromaSepoliaTestnet, linkKromaSepoliaTestnet, wethKromaSepoliaTestnet, chainIdKromaSepoliaTestnet
            );
        } else if (network == SupportedNetworks.METIS_SEPOLIA) {
            return (routerMetisSepolia, linkMetisSepolia, wethMetisSepolia, chainIdMetisSepolia);
        } else if (network == SupportedNetworks.ZKSYNC_SEPOLIA) {
            return (routerZksyncSepolia, linkZksyncSepolia, wethZksyncSepolia, chainIdZksyncSepolia);
        } else if (network == SupportedNetworks.SCROLL_SEPOLIA) {
            return (routerScrollSepolia, linkScrollSepolia, wethScrollSepolia, chainIdScrollSepolia);
        } else if (network == SupportedNetworks.ZIRCUIT_SEPOLIA) {
            return (routerZircuitSepolia, linkZircuitSepolia, wethZircuitSepolia, chainIdZircuitSepolia);
        } else if (network == SupportedNetworks.XLAYER_SEPOLIA) {
            return (routerXlayerSepolia, linkXlayerSepolia, wokbXlayerSepolia, chainIdXlayerSepolia);
        } else if (network == SupportedNetworks.POLYGON_ZKEVM_SEPOLIA) {
            return (
                routerPolygonZkevmSepolia, linkPolygonZkevmSepolia, wethPolygonZkevmSepolia, chainIdPolygonZkevmSepolia
            );
        } else if (network == SupportedNetworks.POLKADOT_ASTAR_SHIBUYA) {
            return (
                routerPolkadotAstarShibuya,
                linkPolkadotAstarShibuya,
                wsbyPolkadotAstarShibuya,
                chainIdPolkadotAstarShibuya
            );
        } else if (network == SupportedNetworks.MANTLE_SEPOLIA) {
            return (routerMantleSepolia, linkMantleSepolia, wmntMantleSepolia, chainIdMantleSepolia);
        } else if (network == SupportedNetworks.SONEIUM_MINATO_SEPOLIA) {
            return (
                routerSoneiumMinatoSepolia,
                linkSoneiumMinatoSepolia,
                wethSoneiumMinatoSepolia,
                chainIdSoneiumMinatoSepolia
            );
        } else if (network == SupportedNetworks.BSQUARED_TESTNET) {
            return (routerBsquaredTestnet, linkBsquaredTestnet, wbtcBsquaredTestnet, chainIdBsquaredTestnet);
        } else if (network == SupportedNetworks.BOB_SEPOLIA) {
            return (routerBobSepolia, linkBobSepolia, wethBobSepolia, chainIdBobSepolia);
        } else if (network == SupportedNetworks.WORLDCHAIN_SEPOLIA) {
            return (routerWorldchainSepolia, linkWorldchainSepolia, wethWorldchainSepolia, chainIdWorldchainSepolia);
        } else if (network == SupportedNetworks.SHIBARIUM_TESTNET) {
            return (routerShibariumTestnet, linkShibariumTestnet, wboneShibariumTestnet, chainIdShibariumTestnet);
        } else if (network == SupportedNetworks.BITLAYER_TESTNET){
            return (routerBitlayerTestnet, linkBitlayerTestnet, wbtcBitlayerTestnet, chainIdBitlayerTestnet);
        } else if (network == SupportedNetworks.FANTOM_SONIC_TESTNET){
            return (routerFantomSonicTestnet, linkFantomSonicTestnet, wethFantomSonicTestnet, chainIdFantomSonicTestnet);
        } else if (network == SupportedNetworks.CORN_TESTNET){
            return (routerCornTestnet, linkCornTestnet, wbtcCornTestnet, chainIdCornTestnet);
        } else if (network == SupportedNetworks.HASHKEY_SEPOLIA){
            return (routerHashkeySepolia, linkHashkeySepolia, whskHashkeySepolia, chainIdHashkeySepolia);
        } else if (network == SupportedNetworks.INK_SEPOLIA){
            return (routerInkSepolia, linkInkSepolia, wethInkSepolia, chainIdInkSepolia);
        }
    }
}
