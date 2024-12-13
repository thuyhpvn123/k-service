package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	c_config "github.com/meta-node-blockchain/meta-node/cmd/client/pkg/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/cronjob"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/services"
)

func main() {
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		log.Fatal("Failed to load config")
	}

	chainClient, err := client.NewClient(
		&c_config.ClientConfig{
			Version_:                cfg.MetaNodeVersion,
			PrivateKey_:             cfg.PrivateKey_,
			ParentAddress:           cfg.NodeAddress,
			ParentConnectionAddress: cfg.NodeConnectionAddress,
			DnsLink_:                cfg.DnsLink(),
		},
	)

	if err != nil {
		log.Fatal("error when create chain client")
	}

	reader, err := os.Open(cfg.KvenABIPath) // * Unit Test
	if err != nil {
		log.Fatal("Error occured while read create card smart contract abi")
	}

	defer reader.Close()

	abi, err := abi.JSON(reader)
	if err != nil {
		log.Fatal("Error occured while parse create card smart contract abi")
	}

	// Initialize services
	servs := services.NewSendTransactionService(chainClient, &abi, common.HexToAddress(
		cfg.KvenAddress,
	))

	//Initialize Cronjob
	cronjob.Start(servs)
	defer cronjob.Stop()

	sigs := make(chan os.Signal, 1)
	done := make(chan struct{})
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		close(done)
	}()
	<-done
}
