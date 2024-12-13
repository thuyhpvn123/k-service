package main

import (
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"os/signal"
	"syscall"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	sm "github.com/meta-node-blockchain/meta-node/cmd/storage/models"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
)

const (
	defaultConfigPath = "config.yaml"
	defaultLogLevel   = logger.FLAG_INFO
)

var (
	// flags
	CONFIG_FILE_PATH string
	LOG_LEVEL        int
)

// application flags

func main() {
	// init flags
	flag.StringVar(&CONFIG_FILE_PATH, "config", defaultConfigPath, "Config path")
	flag.StringVar(&CONFIG_FILE_PATH, "c", defaultConfigPath, "Config path (shorthand)")

	flag.IntVar(&LOG_LEVEL, "log-level", defaultLogLevel, "Log level")
	flag.IntVar(&LOG_LEVEL, "ll", defaultLogLevel, "Log level (shorthand)")

	flag.Parse()
	// init run app
	var loggerConfig = &logger.LoggerConfig{
		Flag:    LOG_LEVEL,
		Outputs: []*os.File{os.Stdout},
	}
	logger.SetConfig(loggerConfig)

	// load config
	var err error
	config, err := config.LoadConfig(CONFIG_FILE_PATH)
	if err != nil {
		panic(fmt.Sprintf("error when loading config %v", err))
	}

	// Initialize the database
	err = database.InitializeDB(config.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to connect to the database")
		panic("Failed to connect to the database")
	}
	database.Migrate()
	sdb, err := database.NewDBConnection(config.StorageDatabaseURL)
	if err != nil {
		panic(1)
	}
	reader, err := os.Open(config.KvenABIPath)
	if err != nil {
		panic("Error occured while read create card smart contract abi")
	}
	defer reader.Close()

	abi, err := abi.JSON(reader)
	if err != nil {
		panic("Error occured while parse create card smart contract abi")
	}

	var logs []sm.Log
	if err := sdb.Where("topic1 = ?", "c653875721be08f80a5e8e9c5924cbd3fc5b4ae8d5da0eff0d0f69a4427c067d").Find(&logs).Error; err != nil {
		panic(1)
	}
	var bonusHistories []models.BonusHistory
	for _, log := range logs {
		eventResult := make(map[string]interface{})
		err = abi.UnpackIntoMap(eventResult, "PayBonus", common.FromHex(log.Data))
		if err != nil {
			panic(1)
		}
		if eventResult["amountUsdt"].(*big.Int).Uint64() > 0 {
			bonusHistories = append(bonusHistories, models.BonusHistory{
				Address:         eventResult["sub"].(common.Address).String(),
				Type:            eventResult["typ"].(string),
				Time:            uint(eventResult["date"].(*big.Int).Uint64()),
				Amount:          eventResult["amountUsdt"].(*big.Int).Uint64(),
				BlockCount:      log.BlockCount,
				TransactionHash: log.TransactionHash,
				LogHash:         log.LogHash,
			})
		}
	}

	err = database.DB.CreateInBatches(&bonusHistories, 100).Error
	logger.Error(err)
	sigs := make(chan os.Signal, 1)
	done := make(chan struct{})
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		close(done)
	}()
	<-done
}
