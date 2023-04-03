// Package gethwrappers_ccip provides tools for wrapping solidity contracts with
// golang packages, using abigen.
package gethwrappers

//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/CommitStore.abi ../../contracts/solc/v0.8.15/CommitStore.bin CommitStore commit_store
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/CommitStoreHelper.abi ../../contracts/solc/v0.8.15/CommitStoreHelper.bin CommitStoreHelper commit_store_helper
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/BurnMintTokenPool.abi ../../contracts/solc/v0.8.15/BurnMintTokenPool.bin BurnMintTokenPool burn_mint_token_pool
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/LockReleaseTokenPool.abi ../../contracts/solc/v0.8.15/LockReleaseTokenPool.bin LockReleaseTokenPool lock_release_token_pool
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/CustomTokenPool.abi ../../contracts/solc/v0.8.15/CustomTokenPool.bin CustomTokenPool custom_token_pool
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/AFN.abi ../../contracts/solc/v0.8.15/AFN.bin AFNContract afn_contract
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/MockAFN.abi ../../contracts/solc/v0.8.15/MockAFN.bin MockAFNContract mock_afn_contract

//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/EVM2EVMOnRamp.abi ../../contracts/solc/v0.8.15/EVM2EVMOnRamp.bin EVM2EVMOnRamp evm_2_evm_onramp
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/EVM2EVMOffRamp.abi ../../contracts/solc/v0.8.15/EVM2EVMOffRamp.bin EVM2EVMOffRamp evm_2_evm_offramp
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/EVM2EVMOffRampHelper.abi ../../contracts/solc/v0.8.15/EVM2EVMOffRampHelper.bin EVM2EVMOffRampHelper evm_2_evm_offramp_helper
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/Router.abi ../../contracts/solc/v0.8.15/Router.bin Router router
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/PriceRegistry.abi ../../contracts/solc/v0.8.15/PriceRegistry.bin PriceRegistry price_registry

//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/ReceiverDapp.abi ../../contracts/solc/v0.8.15/ReceiverDapp.bin ReceiverDapp receiver_dapp
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/SimpleMessageReceiver.abi ../../contracts/solc/v0.8.15/SimpleMessageReceiver.bin SimpleMessageReceiver simple_message_receiver
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/MaybeRevertMessageReceiver.abi ../../contracts/solc/v0.8.15/MaybeRevertMessageReceiver.bin MaybeRevertMessageReceiver maybe_revert_message_receiver
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/GovernanceDapp.abi ../../contracts/solc/v0.8.15/GovernanceDapp.bin GovernanceDapp governance_dapp
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/PingPongDemo.abi ../../contracts/solc/v0.8.15/PingPongDemo.bin PingPongDemo ping_pong_demo
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/WETH9.abi ../../contracts/solc/v0.8.15/WETH9.bin WETH9 weth9

// Customer contracts
//go:generate go run ./generation/generate/wrap.go ../../contracts/solc/v0.8.15/CacheGoldChild.abi ../../contracts/solc/v0.8.15/CacheGoldChild.bin CacheGoldChild cache_gold_child

// To run these commands, you must either install docker, or the correct version
// of abigen. The latter can be installed with these commands, at least on linux:
//
//   git clone https://github.com/ethereum/go-ethereum
//   cd go-ethereum/cmd/abigen
//   git checkout v<version-needed>
//   go install
//
// Here, <version-needed> is the version of go-ethereum specified in chainlink's
// go.mod. This will install abigen in "$GOPATH/bin", which you should add to
// your $PATH.
//
// To reduce explicit dependencies, and in case the system does not have the
// correct version of abigen installed , the above commands spin up docker
// containers. In my hands, total running time including compilation is about
// 13s. If you're modifying solidity code and testing against go code a lot, it
// might be worthwhile to generate the the wrappers using a static container
// with abigen and solc, which will complete much faster. E.g.
//
//   abigen -sol ../../contracts/src/v0.6/VRFAll.sol -pkg vrf -out solidity_interfaces.go
//
// where VRFAll.sol simply contains `import "contract_path";` instructions for
// all the contracts you wish to target. This runs in about 0.25 seconds in my
// hands.
//
// If you're on linux, you can copy the correct version of solc out of the
// appropriate docker container. At least, the following works on ubuntu:
//
//   $ docker run --name solc ethereum/solc:0.6.2
//   $ sudo docker cp solc:/usr/bin/solc /usr/bin
//   $ docker rm solc
//
// If you need to point abigen at your solc executable, you can specify the path
// with the abigen --solc <path-to-executable> option.
