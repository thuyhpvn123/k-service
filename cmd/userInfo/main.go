package main

import (
	"encoding/hex"
	"encoding/json"
	"log"
	"math"
	"os"
	"os/signal"
	"syscall"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/holiman/uint256"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	c_config "github.com/meta-node-blockchain/meta-node/cmd/client/pkg/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	pb "github.com/meta-node-blockchain/meta-node/pkg/proto"
	"github.com/meta-node-blockchain/meta-node/pkg/transaction"
)

type InfoReturn struct {
	ID                          uint
	Add                         string
	FirstTimePay                uint
	NextTimePay                 uint
	Month                       uint
	Childrens                   []string
	ChildrensMatrix             []string
	MPhone                      []byte
	Line                        string
	LineMatrix                  string
	MtotalMember                uint
	Rank                        uint
	TotalSubcriptionBonus       uint
	TotalMatrixBonus            uint
	TotalMatchingBonus          uint
	TotalSaleBonus              uint
	TotalGoodSaleBonus          uint
	TotalExtraDiamondBonus      uint
	TotalExtraCrownDiamondBonus uint
	TotalSale                   uint
	TotalChildrensMatrix        uint
	IsActive                    bool
}

type CodeRefReturn struct {
	CodeRef []byte
	Phone   []byte
}

type CallData struct {
	Action         string   `json:"action"`
	Address        string   `json:"address"`
	Input          string   `json:"input"`
	RelatedAddress []string `json:"related_address"`
	Amount         string   `json:"amount"`
	Name           string   `json:"name"`
}

func main() {
	cfg, err := config.LoadConfig("config.yaml")
	if err != nil {
		log.Fatal("Failed to load config")
	}

	// Initialize the database
	err = database.InitializeDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to connect to the database")
		panic("Failed to connect to the database")
	}
	database.Migrate()

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
	logger.Error(abi.Events["Subcribed"].ID.String()[2:])
	// Initialize services

	addressList := []string{}
	dat, _ := os.ReadFile("output")
	err = json.Unmarshal(dat, &addressList)
	if err != nil {
		panic(err)
	}

	// output := []CallData{}

	input, _ := abi.Pack(
		"GetAllData",
	)
	bData, _ := transaction.NewCallData(input).Marshal()
	relatedAddress := []common.Address{}
	maxGas := uint64(5_000_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	rc, _ := chainClient.SendTransaction(
		common.HexToAddress(cfg.KvenAddress),
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)
	result := make(map[string]interface{})
	abi.UnpackIntoMap(result, "GetAllData", rc.Return())

	jsonData, _ := json.Marshal(result["rs"])

	infoReturn := []InfoReturn{}
	json.Unmarshal([]byte(jsonData), &infoReturn)
	output := []CallData{}

	for index, v := range infoReturn {
		logger.DebugP(v)
		jsonData, _ = json.Marshal(v)
		userInfo := models.UserInfo{}
		json.Unmarshal([]byte(jsonData), &userInfo)
		userInfo.Index = uint(index)
		jsonChildDirect, err := json.Marshal(v.Childrens)
		if err != nil {
			logger.Error("json.Marshal(infoReturn.Childrens)")
			return
		}

		jsonChildMatrix, err := json.Marshal(v.ChildrensMatrix)
		if err != nil {
			logger.Error("json.Marshal(infoReturn.ChildrensMatrix)")
			return
		}
		userInfo.ChildsDirect = string(jsonChildDirect)
		userInfo.ChildsMatrix = string(jsonChildMatrix)
		userInfo.Phone = hex.EncodeToString(v.MPhone)
		userInfo.Month = uint(math.Ceil(float64((v.NextTimePay - v.FirstTimePay) / (60 * 60 * 24 * 29))))

		var byte32Array [32]byte
		copy(byte32Array[:], v.MPhone)
		input, _ = abi.Pack(
			"MigrateRegister",
			byte32Array,
			common.HexToAddress(userInfo.Line),
			uint256.NewInt(uint64(userInfo.Month)-1).ToBig(),
			byte32Array,
			common.HexToAddress(userInfo.Add),
			uint256.NewInt(uint64(v.NextTimePay)).ToBig(),
		)

		temp := CallData{
			Action:         "call",
			Address:        "_to",
			Input:          "0x" + common.Bytes2Hex(input),
			RelatedAddress: []string{},
			Amount:         "0",
			Name:           "kventure-MigrateRegister-" + hex.EncodeToString(common.HexToAddress(userInfo.Add).Bytes()),
		}
		err = database.DB.Create(&userInfo).Error
		if err != nil {
			logger.Error("database.DB.Create(userInfo)")
			return
		}
		output = append(output, temp)
	}
	// logger.Warn(rc)
	logger.SetFlag(6)
	jData, err := json.Marshal(output)
	if err != nil {
		panic("Error marshaling JSON")
	}
	err = os.WriteFile("calldata.json", jData, 0644)
	if err != nil {
		panic("Error writing to file")
	}
	sigs := make(chan os.Signal, 1)
	done := make(chan struct{})
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		close(done)
	}()
	<-done
}
