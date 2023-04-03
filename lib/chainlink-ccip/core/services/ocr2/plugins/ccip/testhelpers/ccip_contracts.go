package testhelpers

import (
	"context"
	"fmt"
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/accounts/abi/bind/backends"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/onsi/gomega"
	"github.com/smartcontractkit/libocr/offchainreporting2/confighelper"
	"github.com/stretchr/testify/require"

	"github.com/smartcontractkit/chainlink/core/chains/evm/logpoller"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/commit_store"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/custom_token_pool"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/evm_2_evm_offramp"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/evm_2_evm_onramp"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/link_token_interface"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/lock_release_token_pool"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/maybe_revert_message_receiver"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/mock_afn_contract"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/price_registry"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/router"
	"github.com/smartcontractkit/chainlink/core/gethwrappers/generated/weth9"
	"github.com/smartcontractkit/chainlink/core/internal/testutils"
	"github.com/smartcontractkit/chainlink/core/logger"
	"github.com/smartcontractkit/chainlink/core/services/ocr2/plugins/ccip"
	"github.com/smartcontractkit/chainlink/core/services/ocr2/plugins/ccip/hasher"
	"github.com/smartcontractkit/chainlink/core/services/ocr2/plugins/ccip/merklemulti"
	"github.com/smartcontractkit/chainlink/core/services/ocrcommon"
	"github.com/smartcontractkit/chainlink/core/utils"
)

var (
	// Source
	SourcePool   = "source pool"
	SourcePrices = "source prices"
	OnRamp       = "onramp"
	SourceRouter = "source router"

	// Dest
	OffRamp  = "offramp"
	DestPool = "dest pool"

	Receiver    = "receiver"
	Sender      = "sender"
	Link        = func(amount int64) *big.Int { return new(big.Int).Mul(big.NewInt(1e18), big.NewInt(amount)) }
	HundredLink = Link(100)
)

type MaybeRevertReceiver struct {
	Receiver *maybe_revert_message_receiver.MaybeRevertMessageReceiver
	Strict   bool
}

type Common struct {
	ChainID       uint64
	User          *bind.TransactOpts
	Chain         *backends.SimulatedBackend
	LinkToken     *link_token_interface.LinkToken
	Pool          *lock_release_token_pool.LockReleaseTokenPool
	CustomPool    *custom_token_pool.CustomTokenPool
	CustomToken   *link_token_interface.LinkToken
	AFN           *mock_afn_contract.MockAFNContract
	PriceRegistry *price_registry.PriceRegistry
}

type SourceChain struct {
	Common
	Router *router.Router
	OnRamp *evm_2_evm_onramp.EVM2EVMOnRamp
}

type DestinationChain struct {
	Common

	CommitStore *commit_store.CommitStore
	Router      *router.Router
	OffRamp     *evm_2_evm_offramp.EVM2EVMOffRamp
	Receivers   []MaybeRevertReceiver
}

type OCR2Config struct {
	Signers               []common.Address
	Transmitters          []common.Address
	F                     uint8
	OnchainConfig         []byte
	OffchainConfigVersion uint64
	OffchainConfig        []byte
}

type BalanceAssertion struct {
	Name     string
	Address  common.Address
	Expected string
	Getter   func(addr common.Address) *big.Int
	Within   string
}

type BalanceReq struct {
	Name   string
	Addr   common.Address
	Getter func(addr common.Address) *big.Int
}

type CCIPContracts struct {
	t         *testing.T
	Source    SourceChain
	Dest      DestinationChain
	OCRConfig *OCR2Config
}

func (c *CCIPContracts) DeployNewOffRamp() {
	offRampAddress, _, _, err := evm_2_evm_offramp.DeployEVM2EVMOffRamp(
		c.Dest.User,
		c.Dest.Chain,
		evm_2_evm_offramp.IEVM2EVMOffRampStaticConfig{
			CommitStore:   c.Dest.CommitStore.Address(),
			ChainId:       c.Dest.ChainID,
			SourceChainId: c.Source.ChainID,
			OnRamp:        c.Source.OnRamp.Address(),
		},
		evm_2_evm_offramp.IEVM2EVMOffRampDynamicConfig{
			PermissionLessExecutionThresholdSeconds: 1,
			ExecutionDelaySeconds:                   0,
			Router:                                  c.Dest.Router.Address(),
			MaxDataSize:                             1e5,
			MaxTokensLength:                         5,
			Afn:                                     c.Dest.AFN.Address(),
		},
		[]common.Address{c.Source.LinkToken.Address()}, // source tokens
		[]common.Address{c.Dest.Pool.Address()},        // pools
		evm_2_evm_offramp.IAggregateRateLimiterRateLimiterConfig{
			Capacity: HundredLink,
			Rate:     big.NewInt(1e18),
			Admin:    c.Source.User.From,
		},
	)
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	c.Dest.OffRamp, err = evm_2_evm_offramp.NewEVM2EVMOffRamp(offRampAddress, c.Dest.Chain)
	require.NoError(c.t, err)

	_, err = c.Dest.OffRamp.SetPrices(c.Dest.User, []common.Address{c.Dest.LinkToken.Address()}, []*big.Int{big.NewInt(1)})
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()
	c.Source.Chain.Commit()
}

func (c *CCIPContracts) EnableOffRamp() {
	_, err := c.Dest.Pool.ApplyRampUpdates(c.Dest.User,
		[]lock_release_token_pool.IPoolRampUpdate{},
		[]lock_release_token_pool.IPoolRampUpdate{{Ramp: c.Dest.OffRamp.Address(), Allowed: true}},
	)

	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	_, err = c.Dest.Router.ApplyRampUpdates(c.Dest.User, nil, []router.IRouterOffRampUpdate{
		{SourceChainId: c.Source.ChainID, OffRamps: []common.Address{c.Dest.OffRamp.Address()}}})
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	_, err = c.Dest.OffRamp.SetOCR2Config(
		c.Dest.User,
		c.OCRConfig.Signers,
		c.OCRConfig.Transmitters,
		c.OCRConfig.F,
		c.OCRConfig.OnchainConfig,
		c.OCRConfig.OffchainConfigVersion,
		c.OCRConfig.OffchainConfig,
	)
	require.NoError(c.t, err)
	c.Source.Chain.Commit()
	c.Dest.Chain.Commit()
}

func (c *CCIPContracts) EnableCommitStore() {
	_, err := c.Dest.CommitStore.SetOCR2Config(
		c.Dest.User,
		c.OCRConfig.Signers,
		c.OCRConfig.Transmitters,
		c.OCRConfig.F,
		c.OCRConfig.OnchainConfig,
		c.OCRConfig.OffchainConfigVersion,
		c.OCRConfig.OffchainConfig,
	)
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	_, err = c.Dest.PriceRegistry.ApplyPriceUpdatersUpdates(c.Dest.User, []common.Address{c.Dest.CommitStore.Address()}, []common.Address{})
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()
}

func (c *CCIPContracts) DeployNewOnRamp() {
	c.t.Log("Deploying new onRamp")
	onRampAddress, _, _, err := evm_2_evm_onramp.DeployEVM2EVMOnRamp(
		c.Source.User,  // user
		c.Source.Chain, // client
		evm_2_evm_onramp.IEVM2EVMOnRampStaticConfig{
			LinkToken:         c.Source.LinkToken.Address(),
			ChainId:           c.Source.ChainID,
			DestChainId:       c.Dest.ChainID,
			DefaultTxGasLimit: 200_000,
		},
		evm_2_evm_onramp.IEVM2EVMOnRampDynamicConfig{
			Router:          c.Source.Router.Address(),
			PriceRegistry:   c.Source.PriceRegistry.Address(),
			MaxDataSize:     1e5,
			MaxTokensLength: 5,
			MaxGasLimit:     ccip.GasLimitPerTx,
			FeeAdmin:        common.Address{},
			Afn:             c.Source.AFN.Address(), // AFN
		},
		[]evm_2_evm_onramp.EVM2EVMOnRampTokenAndPool{
			{
				Token: c.Source.LinkToken.Address(),
				Pool:  c.Source.Pool.Address(),
			},
		},
		[]common.Address{}, // allow list
		evm_2_evm_onramp.IAggregateRateLimiterRateLimiterConfig{
			Capacity: HundredLink,
			Rate:     big.NewInt(1e18),
			Admin:    c.Source.User.From,
		},
		[]evm_2_evm_onramp.IEVM2EVMOnRampFeeTokenConfigArgs{
			{
				Token:           c.Source.LinkToken.Address(),
				Multiplier:      1e18,
				FeeAmount:       big.NewInt(0),
				DestGasOverhead: 0,
			},
		},
		[]evm_2_evm_onramp.IEVM2EVMOnRampNopAndWeight{},
	)

	require.NoError(c.t, err)
	c.Source.OnRamp, err = evm_2_evm_onramp.NewEVM2EVMOnRamp(onRampAddress, c.Source.Chain)
	require.NoError(c.t, err)
	c.Source.Chain.Commit()

	_, err = c.Source.OnRamp.SetPrices(c.Source.User, []common.Address{c.Source.LinkToken.Address()}, []*big.Int{big.NewInt(1)})
	require.NoError(c.t, err)

	c.Source.Chain.Commit()
	c.Dest.Chain.Commit()
}

func (c *CCIPContracts) EnableOnRamp() {
	c.t.Log("Setting onRamp on source pool")
	_, err := c.Source.Pool.ApplyRampUpdates(c.Source.User,
		[]lock_release_token_pool.IPoolRampUpdate{{Ramp: c.Source.OnRamp.Address(), Allowed: true}},
		[]lock_release_token_pool.IPoolRampUpdate{},
	)

	require.NoError(c.t, err)
	c.Source.Chain.Commit()

	c.t.Log("Setting onRamp on source router")
	_, err = c.Source.Router.ApplyRampUpdates(c.Source.User, []router.IRouterOnRampUpdate{{DestChainId: c.Dest.ChainID, OnRamp: c.Source.OnRamp.Address()}}, nil)
	require.NoError(c.t, err)
	c.Source.Chain.Commit()

	c.t.Log("Enabling onRamp on blob verifier")

	c.Source.Chain.Commit()
	c.Dest.Chain.Commit()
}

func (c *CCIPContracts) DeployNewCommitStore() {
	commitStoreAddress, _, _, err := commit_store.DeployCommitStore(
		c.Dest.User,  // user
		c.Dest.Chain, // client
		commit_store.ICommitStoreStaticConfig{
			ChainId:       c.Dest.ChainID,
			SourceChainId: c.Source.ChainID,
			OnRamp:        c.Source.OnRamp.Address(),
		},
		commit_store.ICommitStoreDynamicConfig{
			PriceRegistry: c.Dest.PriceRegistry.Address(),
			Afn:           c.Dest.AFN.Address(), // AFN address
		},
	)
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()
	c.Dest.CommitStore, err = commit_store.NewCommitStore(commitStoreAddress, c.Dest.Chain)
	require.NoError(c.t, err)
}

func (c *CCIPContracts) GetSourceLinkBalance(addr common.Address) *big.Int {
	bal, err := c.Source.LinkToken.BalanceOf(nil, addr)
	require.NoError(c.t, err)
	return bal
}

func (c *CCIPContracts) GetDestLinkBalance(addr common.Address) *big.Int {
	bal, err := c.Dest.LinkToken.BalanceOf(nil, addr)
	require.NoError(c.t, err)
	return bal
}

func (c *CCIPContracts) AssertBalances(bas []BalanceAssertion) {
	for _, b := range bas {
		actual := b.Getter(b.Address)
		require.NotNil(c.t, actual, "%v getter return nil", b.Name)
		if b.Within == "" {
			require.Equal(c.t, b.Expected, actual.String(), "wrong balance for %s got %s want %s", b.Name, actual, b.Expected)
		} else {
			bi, _ := big.NewInt(0).SetString(b.Expected, 10)
			withinI, _ := big.NewInt(0).SetString(b.Within, 10)
			high := big.NewInt(0).Add(bi, withinI)
			low := big.NewInt(0).Sub(bi, withinI)
			require.Equal(c.t, -1, actual.Cmp(high), "wrong balance for %s got %s outside expected range [%s, %s]", b.Name, actual, low, high)
			require.Equal(c.t, 1, actual.Cmp(low), "wrong balance for %s got %s outside expected range [%s, %s]", b.Name, actual, low, high)
		}
	}
}

func (c *CCIPContracts) DeriveOCR2Config(oracles []confighelper.OracleIdentityExtra, reportingPluginConfig []byte) {
	signers, transmitters, threshold, onchainConfig, offchainConfigVersion, offchainConfig, err := confighelper.ContractSetConfigArgsForTests(
		2*time.Second,        // deltaProgress
		1*time.Second,        // deltaResend
		1*time.Second,        // deltaRound
		500*time.Millisecond, // deltaGrace
		2*time.Second,        // deltaStage
		3,
		[]int{1, 1, 1, 1},
		oracles,
		reportingPluginConfig,
		50*time.Millisecond, // Max duration query
		1*time.Second,       // Max duration observation
		100*time.Millisecond,
		100*time.Millisecond,
		100*time.Millisecond,
		1, // faults
		nil,
	)
	require.NoError(c.t, err)
	lggr := logger.TestLogger(c.t)
	lggr.Infow("Setting Config on Oracle Contract",
		"signers", signers,
		"transmitters", transmitters,
		"threshold", threshold,
		"onchainConfig", onchainConfig,
		"encodedConfigVersion", offchainConfigVersion,
	)
	signerAddresses, err := ocrcommon.OnchainPublicKeyToAddress(signers)
	require.NoError(c.t, err)
	transmitterAddresses, err := ocrcommon.AccountToAddress(transmitters)
	require.NoError(c.t, err)

	c.OCRConfig = &OCR2Config{
		Signers:               signerAddresses,
		Transmitters:          transmitterAddresses,
		F:                     threshold,
		OnchainConfig:         onchainConfig,
		OffchainConfigVersion: offchainConfigVersion,
		OffchainConfig:        offchainConfig,
	}
}

func (c *CCIPContracts) SetupOnchainConfig(oracles []confighelper.OracleIdentityExtra, reportingPluginConfig []byte) int64 {
	// Note We do NOT set the payees, payment is done in the OCR2Base implementation
	// Set the offramp offchainConfig.
	c.DeriveOCR2Config(oracles, reportingPluginConfig)
	blockBeforeConfig, err := c.Dest.Chain.BlockByNumber(context.Background(), nil)
	require.NoError(c.t, err)
	// Set the DON on the offramp
	_, err = c.Dest.CommitStore.SetOCR2Config(
		c.Dest.User,
		c.OCRConfig.Signers,
		c.OCRConfig.Transmitters,
		c.OCRConfig.F,
		c.OCRConfig.OnchainConfig,
		c.OCRConfig.OffchainConfigVersion,
		c.OCRConfig.OffchainConfig,
	)
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	// Same DON on the offramp
	_, err = c.Dest.OffRamp.SetOCR2Config(
		c.Dest.User,
		c.OCRConfig.Signers,
		c.OCRConfig.Transmitters,
		c.OCRConfig.F,
		c.OCRConfig.OnchainConfig,
		c.OCRConfig.OffchainConfigVersion,
		c.OCRConfig.OffchainConfig,
	)
	require.NoError(c.t, err)
	c.Dest.Chain.Commit()

	return blockBeforeConfig.Number().Int64()
}

func (c *CCIPContracts) NewCCIPJobSpecParams(tokenPricesUSDPipeline string, configBlock int64) CCIPJobSpecParams {
	return CCIPJobSpecParams{
		OnRamp:                 c.Source.OnRamp.Address(),
		CommitStore:            c.Dest.CommitStore.Address(),
		SourceChainId:          c.Source.ChainID,
		DestChainId:            c.Dest.ChainID,
		SourceChainName:        "SimulatedSource",
		DestChainName:          "SimulatedDest",
		TokenPricesUSDPipeline: tokenPricesUSDPipeline,
		PollPeriod:             time.Second,
		DestStartBlock:         uint64(configBlock),
	}
}

func SendMessage(gasLimit, gasPrice, tokenAmount *big.Int, receiverAddr common.Address, c CCIPContracts) {
	t := c.t
	extraArgs, err := GetEVMExtraArgsV1(gasLimit, false)
	require.NoError(t, err)
	msg := router.ClientEVM2AnyMessage{
		Receiver: MustEncodeAddress(t, receiverAddr),
		Data:     []byte("hello"),
		TokenAmounts: []router.ClientEVMTokenAmount{
			{
				Token:  c.Source.LinkToken.Address(),
				Amount: tokenAmount,
			},
		},
		FeeToken:  c.Source.LinkToken.Address(),
		ExtraArgs: extraArgs,
	}
	fee, err := c.Source.Router.GetFee(nil, c.Dest.ChainID, msg)
	require.NoError(t, err)
	// Currently no overhead and 1gwei dest gas price. So fee is simply gasLimit * gasPrice.
	//require.Equal(t, new(big.Int).Mul(gasLimit, gasPrice).String(), fee.String())
	// Approve the fee amount + the token amount
	_, err = c.Source.LinkToken.Approve(c.Source.User, c.Source.Router.Address(), new(big.Int).Add(fee, tokenAmount))
	require.NoError(t, err)
	c.Source.Chain.Commit()
	SendRequest(t, c, msg)
}

func GetBalances(brs []BalanceReq) (map[string]*big.Int, error) {
	m := make(map[string]*big.Int)
	for _, br := range brs {
		m[br.Name] = br.Getter(br.Addr)
		if m[br.Name] == nil {
			return nil, fmt.Errorf("%v getter return nil", br.Name)
		}
	}
	return m, nil
}

func MustAddBigInt(a *big.Int, b string) *big.Int {
	bi, _ := big.NewInt(0).SetString(b, 10)
	return big.NewInt(0).Add(a, bi)
}

func MustSubBigInt(a *big.Int, b string) *big.Int {
	bi, _ := big.NewInt(0).SetString(b, 10)
	return big.NewInt(0).Sub(a, bi)
}

func MustEncodeAddress(t *testing.T, address common.Address) []byte {
	bts, err := utils.ABIEncode(`[{"type":"address"}]`, address)
	require.NoError(t, err)
	return bts
}

func SetupCCIPContracts(t *testing.T, sourceChainID, destChainID uint64) CCIPContracts {
	sourceChain, sourceUser := SetupChain(t)
	destChain, destUser := SetupChain(t)

	// Deploy link token and pool on source chain
	sourceLinkTokenAddress, _, _, err := link_token_interface.DeployLinkToken(sourceUser, sourceChain)
	require.NoError(t, err)
	sourceChain.Commit()
	sourceLinkToken, err := link_token_interface.NewLinkToken(sourceLinkTokenAddress, sourceChain)
	require.NoError(t, err)
	sourcePoolAddress, _, _, err := lock_release_token_pool.DeployLockReleaseTokenPool(sourceUser,
		sourceChain,
		sourceLinkTokenAddress)
	require.NoError(t, err)
	sourceChain.Commit()
	sourcePool, err := lock_release_token_pool.NewLockReleaseTokenPool(sourcePoolAddress, sourceChain)
	require.NoError(t, err)

	// Deploy link token and pool on destination chain
	destLinkTokenAddress, _, _, err := link_token_interface.DeployLinkToken(destUser, destChain)
	require.NoError(t, err)
	destChain.Commit()
	destLinkToken, err := link_token_interface.NewLinkToken(destLinkTokenAddress, destChain)
	require.NoError(t, err)
	destPoolAddress, _, _, err := lock_release_token_pool.DeployLockReleaseTokenPool(destUser, destChain, destLinkTokenAddress)
	require.NoError(t, err)
	destChain.Commit()
	destPool, err := lock_release_token_pool.NewLockReleaseTokenPool(destPoolAddress, destChain)
	require.NoError(t, err)
	destChain.Commit()

	// Float the offramp pool
	o, err := destPool.Owner(nil)
	require.NoError(t, err)
	require.Equal(t, destUser.From.String(), o.String())
	_, err = destLinkToken.Approve(destUser, destPoolAddress, Link(200))
	require.NoError(t, err)
	_, err = destPool.AddLiquidity(destUser, Link(200))
	require.NoError(t, err)
	destChain.Commit()

	// Deploy custom token pool source
	sourceCustomTokenAddress, _, _, err := link_token_interface.DeployLinkToken(sourceUser, sourceChain) // Just re-use this, it's an ERC20.
	require.NoError(t, err)
	sourceCustomToken, err := link_token_interface.NewLinkToken(sourceCustomTokenAddress, sourceChain)
	require.NoError(t, err)
	destChain.Commit()

	// Deploy custom token pool dest
	destCustomTokenAddress, _, _, err := link_token_interface.DeployLinkToken(destUser, destChain) // Just re-use this, it's an ERC20.
	require.NoError(t, err)
	destCustomToken, err := link_token_interface.NewLinkToken(destCustomTokenAddress, destChain)
	require.NoError(t, err)
	destChain.Commit()

	afnSourceAddress, _, _, err := mock_afn_contract.DeployMockAFNContract(
		sourceUser,
		sourceChain,
	)
	require.NoError(t, err)
	sourceChain.Commit()
	sourceAFN, err := mock_afn_contract.NewMockAFNContract(afnSourceAddress, sourceChain)
	require.NoError(t, err)

	// Create router
	sourceWeth9addr, _, _, err := weth9.DeployWETH9(sourceUser, sourceChain)
	require.NoError(t, err)
	sourceRouterAddress, _, _, err := router.DeployRouter(sourceUser, sourceChain, sourceWeth9addr)
	require.NoError(t, err)
	sourceRouter, err := router.NewRouter(sourceRouterAddress, sourceChain)
	require.NoError(t, err)
	sourceChain.Commit()

	// Deploy and configure onramp
	sourcePricesAddress, _, _, err := price_registry.DeployPriceRegistry(
		sourceUser,
		sourceChain,
		price_registry.InternalPriceUpdates{
			TokenPriceUpdates: []price_registry.InternalTokenPriceUpdate{
				{
					SourceToken: sourceLinkTokenAddress,
					UsdPerToken: big.NewInt(8e18), // 8usd
				},
			},
			DestChainId:   destChainID,
			UsdPerUnitGas: big.NewInt(2000e9), // $2000 per eth * 1gwei = 2000e9
		},
		nil,
		[]common.Address{sourceLinkTokenAddress},
		60*60*24*14, // two weeks
	)
	require.NoError(t, err)

	srcPriceRegistry, err := price_registry.NewPriceRegistry(sourcePricesAddress, sourceChain)
	require.NoError(t, err)

	onRampAddress, _, _, err := evm_2_evm_onramp.DeployEVM2EVMOnRamp(
		sourceUser,  // user
		sourceChain, // client
		evm_2_evm_onramp.IEVM2EVMOnRampStaticConfig{
			LinkToken:         sourceLinkTokenAddress,
			ChainId:           sourceChainID, // source chain id
			DestChainId:       destChainID,   // destinationChainIds
			DefaultTxGasLimit: 200_000,
		},
		evm_2_evm_onramp.IEVM2EVMOnRampDynamicConfig{
			Router:          sourceRouterAddress,
			PriceRegistry:   sourcePricesAddress,
			MaxDataSize:     1e5,
			MaxTokensLength: 5,
			MaxGasLimit:     ccip.GasLimitPerTx,
			FeeAdmin:        common.Address{},
			Afn:             afnSourceAddress, // AFN
		},
		[]evm_2_evm_onramp.EVM2EVMOnRampTokenAndPool{
			{
				Token: sourceLinkTokenAddress,
				Pool:  sourcePoolAddress,
			},
		},
		[]common.Address{}, // allow list
		evm_2_evm_onramp.IAggregateRateLimiterRateLimiterConfig{
			Capacity: HundredLink,
			Rate:     big.NewInt(1e18),
			Admin:    sourceUser.From,
		},
		[]evm_2_evm_onramp.IEVM2EVMOnRampFeeTokenConfigArgs{
			{
				Token:           sourceLinkTokenAddress,
				Multiplier:      1e18,
				FeeAmount:       big.NewInt(0),
				DestGasOverhead: 0,
			},
		},
		[]evm_2_evm_onramp.IEVM2EVMOnRampNopAndWeight{},
	)
	require.NoError(t, err)
	onRamp, err := evm_2_evm_onramp.NewEVM2EVMOnRamp(onRampAddress, sourceChain)
	require.NoError(t, err)
	_, err = sourcePool.ApplyRampUpdates(sourceUser,
		[]lock_release_token_pool.IPoolRampUpdate{{Ramp: onRampAddress, Allowed: true}},
		[]lock_release_token_pool.IPoolRampUpdate{},
	)
	require.NoError(t, err)
	sourceChain.Commit()
	_, err = onRamp.SetPrices(sourceUser, []common.Address{sourceLinkTokenAddress}, []*big.Int{big.NewInt(1)})
	require.NoError(t, err)
	_, err = sourceRouter.ApplyRampUpdates(sourceUser, []router.IRouterOnRampUpdate{{DestChainId: destChainID, OnRamp: onRampAddress}}, nil)
	require.NoError(t, err)
	sourceChain.Commit()

	afnDestAddress, _, _, err := mock_afn_contract.DeployMockAFNContract(
		destUser,
		destChain,
	)
	require.NoError(t, err)
	destChain.Commit()
	destAFN, err := mock_afn_contract.NewMockAFNContract(afnDestAddress, destChain)
	require.NoError(t, err)

	// Deploy and configure ge offramp.
	destPricesAddress, _, _, err := price_registry.DeployPriceRegistry(
		destUser,
		destChain,
		price_registry.InternalPriceUpdates{
			TokenPriceUpdates: []price_registry.InternalTokenPriceUpdate{
				{
					SourceToken: destLinkTokenAddress,
					UsdPerToken: big.NewInt(8e18), // 8usd
				},
			},
			DestChainId:   sourceChainID,
			UsdPerUnitGas: big.NewInt(2000e9), // $2000 per eth * 1gwei = 2000e9
		},
		nil,
		[]common.Address{destLinkTokenAddress},
		60*60*24*14, // two weeks
	)
	require.NoError(t, err)
	destPriceRegistry, err := price_registry.NewPriceRegistry(destPricesAddress, destChain)
	require.NoError(t, err)

	// Deploy commit store.
	commitStoreAddress, _, _, err := commit_store.DeployCommitStore(
		destUser,  // user
		destChain, // client
		commit_store.ICommitStoreStaticConfig{
			ChainId:       destChainID,
			SourceChainId: sourceChainID,
			OnRamp:        onRamp.Address(),
		},
		commit_store.ICommitStoreDynamicConfig{
			PriceRegistry: destPricesAddress,
			Afn:           afnDestAddress, // AFN address
		},
	)
	require.NoError(t, err)
	commitStore, err := commit_store.NewCommitStore(commitStoreAddress, destChain)
	require.NoError(t, err)
	destChain.Commit()

	// Create dest router
	destWeth9addr, _, _, err := weth9.DeployWETH9(destUser, destChain)
	require.NoError(t, err)
	destRouterAddress, _, _, err := router.DeployRouter(destUser, destChain, destWeth9addr)
	require.NoError(t, err)
	destChain.Commit()
	destRouter, err := router.NewRouter(destRouterAddress, destChain)
	require.NoError(t, err)

	offRampAddress, _, _, err := evm_2_evm_offramp.DeployEVM2EVMOffRamp(
		destUser,
		destChain,
		evm_2_evm_offramp.IEVM2EVMOffRampStaticConfig{
			CommitStore:   commitStore.Address(),
			ChainId:       destChainID,
			SourceChainId: sourceChainID,
			OnRamp:        onRampAddress,
		},
		evm_2_evm_offramp.IEVM2EVMOffRampDynamicConfig{
			Router:                                  destRouter.Address(),
			PermissionLessExecutionThresholdSeconds: 1,
			ExecutionDelaySeconds:                   0,
			MaxDataSize:                             1e5,
			MaxTokensLength:                         5,
			Afn:                                     afnDestAddress,
		},
		[]common.Address{sourceLinkTokenAddress},
		[]common.Address{destPoolAddress},
		evm_2_evm_offramp.IAggregateRateLimiterRateLimiterConfig{
			Capacity: HundredLink,
			Rate:     big.NewInt(1e18),
			Admin:    sourceUser.From,
		},
	)
	require.NoError(t, err)
	offRamp, err := evm_2_evm_offramp.NewEVM2EVMOffRamp(offRampAddress, destChain)
	require.NoError(t, err)
	_, err = destPool.ApplyRampUpdates(destUser,
		[]lock_release_token_pool.IPoolRampUpdate{},
		[]lock_release_token_pool.IPoolRampUpdate{{Ramp: offRampAddress, Allowed: true}},
	)
	require.NoError(t, err)
	destChain.Commit()
	_, err = destPriceRegistry.ApplyPriceUpdatersUpdates(destUser, []common.Address{commitStoreAddress}, []common.Address{})
	require.NoError(t, err)
	_, err = destRouter.ApplyRampUpdates(destUser, nil, []router.IRouterOffRampUpdate{
		{SourceChainId: sourceChainID, OffRamps: []common.Address{offRampAddress}}})
	require.NoError(t, err)
	_, err = offRamp.SetPrices(destUser, []common.Address{destLinkTokenAddress}, []*big.Int{big.NewInt(1)})
	require.NoError(t, err)

	// Deploy 2 revertable (one SS one non-SS)
	revertingMessageReceiver1Address, _, _, err := maybe_revert_message_receiver.DeployMaybeRevertMessageReceiver(destUser, destChain, false)
	require.NoError(t, err)
	revertingMessageReceiver1, _ := maybe_revert_message_receiver.NewMaybeRevertMessageReceiver(revertingMessageReceiver1Address, destChain)
	revertingMessageReceiver2Address, _, _, err := maybe_revert_message_receiver.DeployMaybeRevertMessageReceiver(destUser, destChain, false)
	require.NoError(t, err)
	revertingMessageReceiver2, _ := maybe_revert_message_receiver.NewMaybeRevertMessageReceiver(revertingMessageReceiver2Address, destChain)
	// Need to commit here, or we will hit the block gas limit when deploying the executor
	sourceChain.Commit()
	destChain.Commit()

	// Ensure we have at least finality blocks.
	for i := 0; i < 50; i++ {
		sourceChain.Commit()
		destChain.Commit()
	}

	source := SourceChain{
		Common: Common{
			ChainID:       sourceChainID,
			User:          sourceUser,
			Chain:         sourceChain,
			LinkToken:     sourceLinkToken,
			Pool:          sourcePool,
			CustomPool:    nil,
			CustomToken:   sourceCustomToken,
			AFN:           sourceAFN,
			PriceRegistry: srcPriceRegistry,
		},
		Router: sourceRouter,
		OnRamp: onRamp,
	}
	dest := DestinationChain{
		Common: Common{
			ChainID:       destChainID,
			User:          destUser,
			Chain:         destChain,
			LinkToken:     destLinkToken,
			Pool:          destPool,
			CustomPool:    nil,
			CustomToken:   destCustomToken,
			AFN:           destAFN,
			PriceRegistry: destPriceRegistry,
		},
		CommitStore: commitStore,
		Router:      destRouter,
		OffRamp:     offRamp,
		Receivers:   []MaybeRevertReceiver{{Receiver: revertingMessageReceiver1, Strict: false}, {Receiver: revertingMessageReceiver2, Strict: true}},
	}

	return CCIPContracts{
		t:      t,
		Source: source,
		Dest:   dest,
	}
}

func SendRequest(t *testing.T, ccipContracts CCIPContracts, msg router.ClientEVM2AnyMessage) {
	tx, err := ccipContracts.Source.Router.CcipSend(ccipContracts.Source.User, ccipContracts.Dest.ChainID, msg)
	require.NoError(t, err)
	ConfirmTxs(t, []*types.Transaction{tx}, ccipContracts.Source.Chain)
}

func AssertExecState(t *testing.T, ccipContracts CCIPContracts, log logpoller.Log, state ccip.MessageExecutionState) {
	executionStateChanged, err := ccipContracts.Dest.OffRamp.ParseExecutionStateChanged(log.GetGethLog())
	require.NoError(t, err)
	if ccip.MessageExecutionState(executionStateChanged.State) != state {
		t.Log("Execution failed")
		t.Fail()
	}
}

func EventuallyExecutionStateChangedToSuccess(t *testing.T, ccipContracts CCIPContracts, seqNum []uint64, blockNum uint64) {
	gomega.NewGomegaWithT(t).Eventually(func() bool {
		it, err := ccipContracts.Dest.OffRamp.FilterExecutionStateChanged(&bind.FilterOpts{Start: blockNum}, seqNum, [][32]byte{})
		require.NoError(t, err)
		for it.Next() {
			if ccip.MessageExecutionState(it.Event.State) == ccip.Success {
				return true
			}
		}
		ccipContracts.Source.Chain.Commit()
		ccipContracts.Dest.Chain.Commit()
		return false
	}, testutils.WaitTimeout(t), time.Second).
		Should(gomega.BeTrue(), "ExecutionStateChanged Event")
}

func EventuallyReportCommitted(t *testing.T, ccipContracts CCIPContracts, onRamp common.Address, max int) {
	gomega.NewGomegaWithT(t).Eventually(func() bool {
		minSeqNum, err := ccipContracts.Dest.CommitStore.GetExpectedNextSequenceNumber(nil)
		require.NoError(t, err)
		ccipContracts.Source.Chain.Commit()
		ccipContracts.Dest.Chain.Commit()
		t.Log("min seq num reported", minSeqNum)
		return minSeqNum > uint64(max)
	}, testutils.WaitTimeout(t), time.Second).Should(gomega.BeTrue(), "report has not been committed")
}

func GetEVMExtraArgsV1(gasLimit *big.Int, strict bool) ([]byte, error) {
	EVMV1Tag := []byte{0x97, 0xa6, 0x57, 0xc9}

	encodedArgs, err := utils.ABIEncode(`[{"type":"uint256"},{"type":"bool"}]`, gasLimit, strict)
	if err != nil {
		return nil, err
	}

	return append(EVMV1Tag, encodedArgs...), nil
}

func ExecuteMessage(
	t *testing.T,
	ccipContracts CCIPContracts,
	req logpoller.Log,
	allReqs []logpoller.Log,
	report commit_store.ICommitStoreCommitReport,
) uint64 {
	t.Log("Executing request manually")
	// Build a merkle tree for the report
	mctx := hasher.NewKeccakCtx()
	leafHasher := ccip.NewLeafHasher(ccipContracts.Source.ChainID, ccipContracts.Dest.ChainID, ccipContracts.Source.OnRamp.Address(), mctx)

	var leafHashes [][32]byte
	for _, otherReq := range allReqs {
		hash, err := leafHasher.HashLeaf(otherReq.GetGethLog())
		require.NoError(t, err)
		leafHashes = append(leafHashes, hash)
	}
	decodedMsg, err := ccip.DecodeMessage(req.Data)
	require.NoError(t, err)
	tree, err := merklemulti.NewTree(mctx, leafHashes)
	require.NoError(t, err)
	require.Equal(t, tree.Root(), report.MerkleRoot, "Roots do not match")

	idx := int(decodedMsg.SequenceNumber - report.Interval.Min)
	proof := tree.Prove([]int{idx})
	offRampProof := evm_2_evm_offramp.InternalExecutionReport{
		SequenceNumbers: []uint64{decodedMsg.SequenceNumber},
		EncodedMessages: [][]byte{req.Data},
		Proofs:          proof.Hashes,
		ProofFlagBits:   ccip.ProofFlagsToBits(proof.SourceFlags),
	}

	// Execute.
	tx, err := ccipContracts.Dest.OffRamp.ManuallyExecute(ccipContracts.Dest.User, offRampProof)
	require.NoError(t, err, "Executing manually")
	ccipContracts.Dest.Chain.Commit()
	ccipContracts.Source.Chain.Commit()
	rec, err := ccipContracts.Dest.Chain.TransactionReceipt(context.Background(), tx.Hash())
	require.NoError(t, err)
	require.Equal(t, uint64(1), rec.Status, "manual execution failed")
	t.Logf("Manual Execution completed for seqNum %d", decodedMsg.SequenceNumber)
	return decodedMsg.SequenceNumber
}
