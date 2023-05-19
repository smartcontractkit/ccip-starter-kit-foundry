// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Helper {
    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 16015286601757825753;
    uint64 constant chainIdOptimismGoerli = 2664363617261496610;
    uint64 constant chainIdAvalancheFuji = 14767482510784806043;
    uint64 constant chainIdArbitrumTestnet = 6101244977088475029;
    uint64 constant chainIdPolygonMumbai = 12532609583862916517;

    // Router addresses
    address constant routerEthereumSepolia =
        0xA5bD184D05C7535C8A022905558974752e646a88;
    address constant routerOptimismGoerli =
        0x6a9CCB433615CaAF0EF20a9f7F04e339Dca8f219;
    address constant routerAvalancheFuji =
        0x9b45eda197971e5fC1eBA5B51E6c8b3B9f2578Cc;
    address constant routerArbitrumTestnet =
        0xf9B7595D64a380fFa605A1d11BFf5cd629FB7189;
    address constant routerPolygonMumbai =
        0x8a710bBd77661D168D5A6725bD2E514ba1bFf59d;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkOptimismGoerli =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
    address constant linkAvalancheFuji =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
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
}
