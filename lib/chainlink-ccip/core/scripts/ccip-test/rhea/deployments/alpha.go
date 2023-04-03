package deployments

import (
	"math/big"

	gethcommon "github.com/ethereum/go-ethereum/common"

	"github.com/smartcontractkit/chainlink/core/scripts/ccip-test/rhea"
)

var AlphaChains = map[rhea.Chain]rhea.EvmDeploymentConfig{
	rhea.AvaxFuji:       {ChainConfig: Alpha_AvaxFuji},
	rhea.OptimismGoerli: {ChainConfig: Alpha_OptimismGoerli},
	rhea.Sepolia:        {ChainConfig: Alpha_Sepolia},
}

var AlphaChainMapping = map[rhea.Chain]map[rhea.Chain]rhea.EvmDeploymentConfig{
	rhea.Sepolia: {
		rhea.AvaxFuji:       Alpha_SepoliaToAvaxFuji,
		rhea.OptimismGoerli: Alpha_SepoliaToOptimismGoerli,
	},
	rhea.AvaxFuji: {
		rhea.Sepolia:        Alpha_AvaxFujiToSepolia,
		rhea.OptimismGoerli: Alpha_AvaxFujiToOptimismGoerli,
	},
	rhea.OptimismGoerli: {
		rhea.Sepolia:  Alpha_OptimismGoerliToSepolia,
		rhea.AvaxFuji: Alpha_OptimismGoerliToAvaxFuji,
	},
}

var Alpha_OptimismGoerli = rhea.EVMChainConfig{
	ChainId: 420,
	GasSettings: rhea.EVMGasSettings{
		EIP1559: true,
	},
	SupportedTokens: map[rhea.Token]rhea.EVMBridgedToken{
		rhea.LINK: {
			Token:                gethcommon.HexToAddress("0xdc2CC710e42857672E7907CF474a69B63B93089f"),
			Pool:                 gethcommon.HexToAddress("0x0dc2038243ac2dbf5c68277673ee221f8e616743"),
			Price:                big.NewInt(1),
			PriceFeedsAggregator: gethcommon.HexToAddress("0x53AFfFfA77006432146b667C67FA77b5D405793b"),
			TokenPoolType:        rhea.LockRelease,
		},
		rhea.WETH: {
			Token:                gethcommon.HexToAddress("0x4200000000000000000000000000000000000006"),
			Pool:                 gethcommon.HexToAddress("0x363c3a63ab17affcfbb4ed88d08bde29672ef59b"),
			Price:                big.NewInt(1500),
			PriceFeedsAggregator: gethcommon.HexToAddress("0x95Fd25C1238ED3274A53250927B568aF3D80E654"),
			TokenPoolType:        rhea.LockRelease,
		},
	},
	FeeTokens:     []rhea.Token{rhea.LINK, rhea.WETH},
	WrappedNative: rhea.WETH,
	Router:        gethcommon.HexToAddress("0x012c1cb7a6f54dc0bcb6cc8955f54ddf5f178084"),
	Afn:           gethcommon.HexToAddress("0x89f2a6cc7c7ae55409546f1cc7c58c94d745e884"),
	PriceRegistry: gethcommon.HexToAddress("0xf0046682ec5a3427cb37fe3e3d2dafea8eb409b4"),
	Confirmations: 4,
}

var Alpha_Sepolia = rhea.EVMChainConfig{
	ChainId: 11155111,
	GasSettings: rhea.EVMGasSettings{
		EIP1559: false,
	},
	SupportedTokens: map[rhea.Token]rhea.EVMBridgedToken{
		rhea.LINK: {
			Token:                gethcommon.HexToAddress("0x779877A7B0D9E8603169DdbD7836e478b4624789"),
			Pool:                 gethcommon.HexToAddress("0xf8667be9b0f2d71d14f67d2eea4e5cc07998a4cc"),
			Price:                big.NewInt(10),
			PriceFeedsAggregator: gethcommon.HexToAddress("0xc59E3633BAAC79493d908e63626716e204A45EdF"),
			TokenPoolType:        rhea.LockRelease,
		},
		rhea.WETH: {
			Token:                gethcommon.HexToAddress("0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534"),
			Pool:                 gethcommon.HexToAddress("0x31cd40c8b194be175365190b0e03069c6d912237"),
			Price:                big.NewInt(1500),
			PriceFeedsAggregator: gethcommon.HexToAddress("0x719E22E3D4b690E5d96cCb40619180B5427F14AE"),
			TokenPoolType:        rhea.LockRelease,
		},
	},
	FeeTokens:     []rhea.Token{rhea.LINK, rhea.WETH},
	WrappedNative: rhea.WETH,
	Router:        gethcommon.HexToAddress("0x8e56b840df6b01d9220a3f3f557aadf3a8024b9d"),
	Afn:           gethcommon.HexToAddress("0x7a9ee62198b1c3a8f24c5003a078e1195cabdbd5"),
	PriceRegistry: gethcommon.HexToAddress("0x2052e5e0e6bcdace1bfb133af111a2ca05c0bb37"),
	Confirmations: 4,
}

var Alpha_AvaxFuji = rhea.EVMChainConfig{
	ChainId: 43113,
	GasSettings: rhea.EVMGasSettings{
		EIP1559: false,
	},
	SupportedTokens: map[rhea.Token]rhea.EVMBridgedToken{
		rhea.LINK: {
			Token:                gethcommon.HexToAddress("0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846"),
			Pool:                 gethcommon.HexToAddress("0xfe01bbad74159b184f5a7351cdd3faddc68ceb89"),
			Price:                big.NewInt(10),
			PriceFeedsAggregator: gethcommon.HexToAddress("0x34C4c526902d88a3Aa98DB8a9b802603EB1E3470"),
			TokenPoolType:        rhea.LockRelease,
		},
		rhea.WAVAX: {
			Token:                gethcommon.HexToAddress("0xd00ae08403B9bbb9124bB305C09058E32C39A48c"),
			Pool:                 gethcommon.HexToAddress("0xdffa0515ec7b58fa75b4dc7b3de29cb71ff72656"),
			Price:                big.NewInt(25),
			PriceFeedsAggregator: gethcommon.HexToAddress("0x6C2441920404835155f33d88faf0545B895871b1"),
			TokenPoolType:        rhea.LockRelease,
		},
	},
	FeeTokens:     []rhea.Token{rhea.LINK, rhea.WAVAX},
	WrappedNative: rhea.WAVAX,
	Router:        gethcommon.HexToAddress("0x3356246ced3cd50085e0acc1b081a4d138f7b9e0"),
	Afn:           gethcommon.HexToAddress("0x4a6450b7c6d7adfeca673d13d9d1c6ef3c2f69b5"),
	PriceRegistry: gethcommon.HexToAddress("0x3859c817b9795cb82ced4b1447dc23310e98ce1d"),
	Confirmations: 1,
}

// Lanes
var Alpha_OptimismGoerliToAvaxFuji = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_OptimismGoerli,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0x3a9eb812a299196f2b4e05c62cbeb959c7beab59"),
		OnRamp:       gethcommon.HexToAddress("0x1fd73af7953b3402b9204e01f137f9878b04122e"),
		OffRamp:      gethcommon.HexToAddress("0xf904d336ab8db50c0beb38823b35e5c164c71547"),
		ReceiverDapp: gethcommon.HexToAddress("0x96250fe5bc50283c3ff900ff99ef342429cbb6dc"),
		PingPongDapp: gethcommon.HexToAddress("0xd2a9e71a67aa965c4880c5b078ff2a56aa6fdf36"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         6473732,
	},
}

var Alpha_AvaxFujiToOptimismGoerli = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_AvaxFuji,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0x05df5f5c7ac976b3968e1e0539094e2d09fee365"),
		OnRamp:       gethcommon.HexToAddress("0x86a6e48d823ff5aa6dab47f9af8b20f41e1dd11b"),
		OffRamp:      gethcommon.HexToAddress("0x09c0a5cd78cfcc470d41ab8ecf9cd356a5b27041"),
		ReceiverDapp: gethcommon.HexToAddress("0x0c51053fa16ba9b1ce71b9b328776b71831bf94b"),
		PingPongDapp: gethcommon.HexToAddress("0xf9aad8a4cc15813f1086c48764df3c270391178e"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         19676473,
	},
}

var Alpha_SepoliaToOptimismGoerli = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_Sepolia,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0xb29ac4f927b734adb0a18543fa3f33d2011f8f5a"),
		OnRamp:       gethcommon.HexToAddress("0x41d2c9b2665bd7fe12ded7b56a85701b6d0e9fb2"),
		OffRamp:      gethcommon.HexToAddress("0x886faefbd511d76d635d12f87726cf3cc4349cf9"),
		ReceiverDapp: gethcommon.HexToAddress("0x608850eb9c25922d355c02dbb721799ceb1092e9"),
		PingPongDapp: gethcommon.HexToAddress("0x3f949ab4b4d31c9dbe92dc8e0870a7f3ec1987c8"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         3060752,
	},
}

var Alpha_OptimismGoerliToSepolia = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_OptimismGoerli,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0x5d50d6239a3da796650321699380f364975d95f2"),
		OnRamp:       gethcommon.HexToAddress("0x211fe3dcc4c70bd2d4c243cf306202e3a28e5099"),
		OffRamp:      gethcommon.HexToAddress("0x7dd4517c4c144792ebee90bce6c0d852a5d2db83"),
		ReceiverDapp: gethcommon.HexToAddress("0xda9190149645f4ad8f09b517b50e25d8f5c310cb"),
		PingPongDapp: gethcommon.HexToAddress("0xc4e40d949bfaa569fd29c6eb568ea810fa48f77c"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         6510308,
	},
}

var Alpha_SepoliaToAvaxFuji = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_Sepolia,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0x30c2f336ced959d56d6bd79d22acf34dccd0effc"),
		OnRamp:       gethcommon.HexToAddress("0x9e8a738a321b105065ce6fa22d47130b4519cde4"),
		OffRamp:      gethcommon.HexToAddress("0x79dbafa3b9b39a3e3b3789f8e0dc92f649d4b7c7"),
		ReceiverDapp: gethcommon.HexToAddress("0x1f4e1ef33d4e0f751ee66083dcaccf007b7e52c7"),
		PingPongDapp: gethcommon.HexToAddress("0xb012a8562c441975cd9f256c63d7779e66b390b0"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         3060823,
	},
}

var Alpha_AvaxFujiToSepolia = rhea.EvmDeploymentConfig{
	ChainConfig: Alpha_AvaxFuji,
	LaneConfig: rhea.EVMLaneConfig{
		CommitStore:  gethcommon.HexToAddress("0x3b22729c18d93e67c7389bcedf69c59f0df77a95"),
		OnRamp:       gethcommon.HexToAddress("0xf6b5f2b53261068daf9806b2980ff75c4c872d75"),
		OffRamp:      gethcommon.HexToAddress("0x70001a5cd7b1a8f8818243b1e54a730b15d90731"),
		ReceiverDapp: gethcommon.HexToAddress("0x6dc153a7d8ddec309585fc59d89fc09ed2412357"),
		PingPongDapp: gethcommon.HexToAddress("0xc342b4af5dcc055e6720a8a622908af2244e38f6"),
	},
	DeploySettings: rhea.DeploySettings{
		DeployAFN:           false,
		DeployTokenPools:    false,
		DeployRouter:        false,
		DeployPriceRegistry: false,

		DeployCommitStore:  false,
		DeployRamp:         false,
		DeployPingPongDapp: false,
		DeployedAt:         19704118,
	},
}
