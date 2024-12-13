package history

import (
	"fmt"
	"log"
	"os"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/routes"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/cronjob"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/handler"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/services"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	"github.com/meta-node-blockchain/meta-node/types"

	c_config "github.com/meta-node-blockchain/meta-node/cmd/client/pkg/config"
)

func PreflightHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}

type App struct {
	Config        *config.AppConfig
	StorageClient *client.Client
	EventChan     chan types.EventLogs
	StopChan      chan bool

	KventureHandler *handler.KventureHandler
}

func NewApp(
	configFilePath string,
	logLevel int,
) (*App, error) {
	var loggerConfig = &logger.LoggerConfig{
		Flag:    logLevel,
		Outputs: []*os.File{os.Stdout},
	}
	logger.SetConfig(loggerConfig)

	app := &App{}
	// load config
	var err error
	app.Config, err = config.LoadConfig(configFilePath)
	if err != nil {
		logger.Error(fmt.Sprintf("error when loading config %v", err))
		return nil, err
	}

	// Initialize the database
	err = database.InitializeDB(app.Config.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to connect to the database")
		panic("Failed to connect to the database")
	}
	database.Migrate()

	// Initialize the repository
	repos := repositories.NewRepositories(database.DB)

	// event channel
	app.StorageClient, err = client.NewStorageClient(
		&c_config.ClientConfig{
			Version_:                app.Config.MetaNodeVersion,
			PrivateKey_:             app.Config.PrivateKey_,
			ParentAddress:           app.Config.StorageAddress,
			ParentConnectionAddress: app.Config.StorageConnectionAddress,
			DnsLink_:                app.Config.DnsLink(),
		},
		[]common.Address{
			common.HexToAddress(app.Config.ProductAddress),
			common.HexToAddress(app.Config.RetailAddress),
			common.HexToAddress(app.Config.KvenAddress),
		},
	)

	if err != nil {
		logger.Error(fmt.Sprintf("error when create chain client %v", err))
		return nil, err
	}

	// create card abi
	reader, err := os.Open(app.Config.KvenABIPath) // * Unit Test
	if err != nil {
		logger.Error("Error occured while read create card smart contract abi")
		return nil, err
	}
	defer reader.Close()

	kventureAbi, err := abi.JSON(reader)
	if err != nil {
		logger.Error("Error occured while parse create card smart contract abi")
		return nil, err
	}

	reader, err = os.Open(app.Config.ProductABIPath)
	if err != nil {
		logger.Error("Error occured while read create card smart contract abi")
		return nil, err
	}
	defer reader.Close()

	productAbi, err := abi.JSON(reader)
	if err != nil {
		logger.Error("Error occured while parse create card smart contract abi")
		return nil, err
	}

	reader, err = os.Open(app.Config.RetailABIPath)
	if err != nil {
		logger.Error("Error occured while read create card smart contract abi")
		return nil, err
	}
	defer reader.Close()

	retailAbi, err := abi.JSON(reader)
	if err != nil {
		logger.Error("Error occured while parse create card smart contract abi")
		return nil, err
	}

	app.KventureHandler = handler.NewKventureHandler(
		common.HexToAddress(
			app.Config.RetailAddress,
		),
		&kventureAbi,
		&productAbi,
		&retailAbi,
		repos,
		app.Config.KvenBonusHash,
		app.Config.KvenSubHash,
		app.Config.ProductBuyHash,
		app.Config.RetailDiscountHash,
		services.NewTeleService(app.Config.ChatID, app.Config.BotToken),
	)

	// Initialize the Gin router
	r := gin.Default()
	// Initialize cors config
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowOrigins = []string{"*"}
	corsConfig.AllowHeaders = []string{"*"}
	corsConfig.AllowCredentials = true

	r.Use(cors.New(corsConfig))
	// Initialize services
	// Setup the user API routes
	apiRouter := r.Group("/api", PreflightHandler())
	handlerRepo := handlers.NewHandlers(repos, &kventureAbi)
	routes.InitRoutes(apiRouter, handlerRepo)
	//Initialize Cronjob
	cronjob.Start(handlerRepo)
	// defer cronjob.Stop()
	// //keep cronjob running until server close
	// var forever chan struct{}
	// <-forever
	go func() {
		err = r.Run(app.Config.APIAddress)
		if err != nil {
			log.Fatal("Failed to start the server")
		}
	}()

	return app, nil
}

func (app *App) Run() {
	app.StopChan = make(chan bool)
	for {
		select {
		case <-app.StopChan:
			return
		case eventLogs := <-app.StorageClient.GetEventLogsChan():
			logger.Debug(eventLogs)
			app.KventureHandler.HandleEvent(eventLogs)
		}
	}
}

func (app *App) Stop() error {
	app.StorageClient.Close()
	defer database.CloseDB()

	logger.Warn("App Stopped")
	return nil
}
