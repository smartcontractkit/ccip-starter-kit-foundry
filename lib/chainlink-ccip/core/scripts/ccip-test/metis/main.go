package main

import (
	"log"
	"os"

	"github.com/urfave/cli"

	"github.com/smartcontractkit/chainlink/core/logger"
	"github.com/smartcontractkit/chainlink/core/recovery"
	"github.com/smartcontractkit/chainlink/core/scripts/ccip-test/metis/printing"
	"github.com/smartcontractkit/chainlink/core/scripts/ccip-test/rhea/deployments"
	helpers "github.com/smartcontractkit/chainlink/core/scripts/common"
)

var (
	SOURCE      = deployments.Beta_SepoliaToAvaxFuji
	DESTINATION = deployments.Beta_AvaxFujiToSepolia
)

// COMMANDS:
// state, s          prints CCIP config state
// txs, tx           prints recent txs
// tokens, t         prints fee tokens and token support
// tokenSupport, ts  prints token support
// help, h           Shows a list of commands or help for one command
func main() {
	recovery.ReportPanics(func() {
		client := NewClient()
		app := NewMetisApp(client)

		client.Logger.ErrorIf(app.Run(os.Args), "Error running app")
		if err := client.CloseLogger(); err != nil {
			log.Fatal(err)
		}
	})
}

func NewClient() MetisClient {
	lggr, closeLggr := logger.NewLogger()
	return MetisClient{
		Logger:      lggr,
		CloseLogger: closeLggr,
	}
}

type MetisClient struct {
	Logger      logger.Logger
	CloseLogger func() error
}

func NewMetisApp(client MetisClient) *cli.App {
	app := cli.NewApp()
	app.Name = "Metis"
	app.Usage = "CCIP sanity checker"

	err := SOURCE.SetupReadOnlyChain(client.Logger.Named(helpers.ChainName(int64(SOURCE.ChainConfig.ChainId))))
	if err != nil {
		log.Fatal(err)
	}
	err = DESTINATION.SetupReadOnlyChain(client.Logger.Named(helpers.ChainName(int64(DESTINATION.ChainConfig.ChainId))))
	if err != nil {
		log.Fatal(err)
	}

	app.Commands = []cli.Command{
		{
			Name:    "state",
			Aliases: []string{"s"},
			Usage:   "prints CCIP config state",
			Action: func(c *cli.Context) error {
				printing.PrintCCIPState(&SOURCE, &DESTINATION)
				return nil
			},
		},
		{
			Name:    "txs",
			Aliases: []string{"tx"},
			Usage:   "prints recent txs",
			Action: func(c *cli.Context) error {
				printing.PrintTxStatuses(&SOURCE, &DESTINATION)
				return nil
			},
		},
		{
			Name:    "tokens",
			Aliases: []string{"t"},
			Usage:   "prints fee tokens and token support",
			Action: func(c *cli.Context) error {
				printing.PrintTokenSupportAllChains(client.Logger)
				return nil
			},
		},
		{
			Name:    "tokenSupport",
			Aliases: []string{"ts"},
			Usage:   "prints token support",
			Action: func(c *cli.Context) error {
				printing.PrintBidirectionalTokenSupportState(&SOURCE, &DESTINATION)
				return nil
			},
		},
	}

	return app
}
