// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Helper {
    // Chain IDs
    uint64 constant chainIdEthereumSepolia = 11155111;
    uint64 constant chainIdOptimismGoerli = 420;
    uint64 constant chainIdAvalancheFuji = 43113;
    uint64 constant chainIdArbitrumTestnet = 421613;

    // Router addresses
    address constant routerEthereumSepolia =
        0x0A36795B3006f50088c11ea45b960A1b0406f03b;
    address constant routerOptimismGoerli =
        0xEC6d1eC94D518be47DA1cb35F5d43286558d8B62;
    address constant routerAvalancheFuji =
        0xb352E636F4093e4F5A4aC903064881491926aaa9;
    address constant routerArbitrumTestnet =
        0xa75cCA5b404ec6F4BB6EC4853D177FE7057085c8;

    // Link addresses (can be used as fee)
    address constant linkEthereumSepolia =
        0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant linkOptimismGoerli =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
    address constant linkAvalancheFuji =
        0xdc2CC710e42857672E7907CF474a69B63B93089f;
    address constant linkArbitrumTestnet =
        0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;

    // Wrapped native addresses
    address constant wethEthereumSepolia =
        0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;
    address constant wethOptimismGoerli =
        0x4200000000000000000000000000000000000006;
    address constant wavaxAvalancheFuji =
        0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address constant wethArbitrumTestnet =
        0x32d5D5978905d9c6c2D4C417F0E06Fe768a4FB5a;
}
