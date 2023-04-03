package rhea

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"

	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/burn_mint_token_pool"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/cache_gold_child"
	"github.com/smartcontractkit/chainlink/core/scripts/ccip-test/shared"
	helpers "github.com/smartcontractkit/chainlink/core/scripts/common"
)

func DeployCacheGoldTokenAndPool(t *testing.T, client *EvmDeploymentConfig) {
	if client.ChainConfig.CustomerSettings.CacheGoldFeeAddress == common.HexToAddress("") ||
		client.ChainConfig.CustomerSettings.CacheGoldFeeEnforcer == common.HexToAddress("") {
		client.Logger.Infof("Cannot deploy Cache.gold token because no fee address is set.")
		return
	}

	tokenAddress, tx, _, err := cache_gold_child.DeployCacheGoldChild(client.Owner, client.Client)
	shared.RequireNoError(t, err)
	shared.WaitForMined(t, client.Logger, client.Client, tx.Hash(), true)
	client.Logger.Infof("CACHE.gold token instance deployed on %s in tx: %s", tokenAddress.Hex(), helpers.ExplorerLink(int64(client.ChainConfig.ChainId), tx.Hash()))

	poolAddress, tx, _, err := burn_mint_token_pool.DeployBurnMintTokenPool(client.Owner, client.Client, tokenAddress)
	shared.RequireNoError(t, err)
	shared.WaitForMined(t, client.Logger, client.Client, tx.Hash(), true)
	client.Logger.Infof("CACHE.gold token pool deployed on %s in tx: %s", poolAddress.Hex(), helpers.ExplorerLink(int64(client.ChainConfig.ChainId), tx.Hash()))

	cacheGoldToken, err := cache_gold_child.NewCacheGoldChild(tokenAddress, client.Client)
	shared.RequireNoError(t, err)

	tx, err = cacheGoldToken.Initialize(client.Owner, client.ChainConfig.CustomerSettings.CacheGoldFeeAddress, client.ChainConfig.CustomerSettings.CacheGoldFeeEnforcer, poolAddress, client.Owner.From, common.Address{})
	shared.RequireNoError(t, err)
	shared.WaitForMined(t, client.Logger, client.Client, tx.Hash(), true)
	client.Logger.Infof("CACHE.gold token initialized in tx: %s", helpers.ExplorerLink(int64(client.ChainConfig.ChainId), tx.Hash()))

	tx, err = cacheGoldToken.SetTransferFeeExempt(client.Owner, poolAddress)
	shared.RequireNoError(t, err)
	shared.WaitForMined(t, client.Logger, client.Client, tx.Hash(), true)
	client.Logger.Infof("CACHE.gold token pool set fee exempt in tx: %s", helpers.ExplorerLink(int64(client.ChainConfig.ChainId), tx.Hash()))
}
