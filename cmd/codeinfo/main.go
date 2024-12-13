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
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/services"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
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

	// Initialize services
	servs := services.NewSendTransactionService(chainClient, &abi, common.HexToAddress(
		cfg.KvenAddress,
	))
	addressList := []string{}
	dat, _ := os.ReadFile("output")
	err = json.Unmarshal(dat, &addressList)
	if err != nil {
		panic(err)
	}

	output := []CallData{}
	for index, address := range addressList {
		logger.Error("GetCodehashInfo", address)
		receipt, err := servs.CallGetUserInfo(address)
		if err != nil {
			break
		}

		result := make(map[string]interface{})
		err = abi.UnpackIntoMap(result, "GetUserInfo", receipt.Return())
		if err != nil {
			logger.Error("UnpackIntoMap", address)
			break
		}

		jsonData, err := json.Marshal(result["userinfo"])
		if err != nil {
			logger.Error("json.Marshal(result)", address)
			return
		}

		infoReturn := InfoReturn{}
		err = json.Unmarshal([]byte(jsonData), &infoReturn)
		if err != nil {
			logger.Error("json.Unmarshal([]byte(jsonData), &infoReturn)", address)
			return
		}

		userInfo := models.UserInfo{}
		err = json.Unmarshal([]byte(jsonData), &userInfo)
		if err != nil {
			logger.Error("json.Unmarshal([]byte(jsonData), &userInfo)", address, err)
			return
		}

		jsonChildDirect, err := json.Marshal(infoReturn.Childrens)
		if err != nil {
			logger.Error("json.Marshal(infoReturn.Childrens)", address)
			return
		}

		jsonChildMatrix, err := json.Marshal(infoReturn.ChildrensMatrix)
		if err != nil {
			logger.Error("json.Marshal(infoReturn.ChildrensMatrix)", address)
			return
		}
		userInfo.Index = uint(index)
		userInfo.ChildsDirect = string(jsonChildDirect)
		userInfo.ChildsMatrix = string(jsonChildMatrix)
		userInfo.Phone = hex.EncodeToString(infoReturn.MPhone)
		userInfo.Month = uint(math.Ceil(float64((infoReturn.NextTimePay - infoReturn.FirstTimePay) / (60 * 60 * 24 * 29))))

		var byte32Array [32]byte
		copy(byte32Array[:], infoReturn.MPhone)
		input, err := abi.Pack(
			"MigrateRegister",
			byte32Array,
			common.HexToAddress(userInfo.Line),
			uint256.NewInt(uint64(userInfo.Month)-1).ToBig(),
			byte32Array,
			common.HexToAddress(userInfo.Add),
			uint256.NewInt(uint64(infoReturn.NextTimePay)).ToBig(),
		)
		if err != nil {
			logger.Error("error when pack input call data", address, err)
			return
		}

		temp := CallData{
			Action:         "call",
			Address:        "_to",
			Input:          "0x" + common.Bytes2Hex(input),
			RelatedAddress: []string{},
			Amount:         "0",
			Name:           "kventure-MigrateRegister-" + hex.EncodeToString(common.HexToAddress(userInfo.Add).Bytes()),
		}

		output = append(output, temp)
		// Get total sale bonus
		logger.Error("CallGetSubcribeInfo", index, address)
		receipt, err = servs.CallGetRevenue(address)
		if err != nil {
			break
		}

		result = make(map[string]interface{})
		err = abi.UnpackIntoMap(result, "totalRevenues", receipt.Return())
		if err != nil {
			logger.Error("UnpackIntoMap", address)
			break
		}
		revenue := uint256.NewInt(0).SetBytes(receipt.Return())
		userInfo.TotalRevenues = uint(revenue.Uint64())
		err = database.DB.Create(&userInfo).Error
		if err != nil {
			logger.Error("database.DB.Create(userInfo)", address)
			return
		}

		logger.Error("CallGetSubcribeInfo", index, address)
		receipt, err = servs.CallGetSubcribeInfo(address)
		if err != nil {
			break
		}

		result = make(map[string]interface{})
		err = abi.UnpackIntoMap(result, "mSubInfo", receipt.Return())
		if err != nil {
			logger.Error("UnpackIntoMap", address)
			break
		}
		jsonData, err = json.Marshal(result)
		if err != nil {
			logger.Error("json.Marshal(result)", address)
			return
		}

		codeRefReturn := CodeRefReturn{}
		err = json.Unmarshal([]byte(jsonData), &codeRefReturn)
		if err != nil {
			logger.Error("json.Unmarshal([]byte(jsonData), &codeRefReturn)", address)
			return
		}

		var codeRef [32]byte
		copy(codeRef[:], codeRefReturn.CodeRef)

		input, err = abi.Pack(
			"SetUserInfo",
			common.HexToAddress(address),
			uint8(userInfo.Rank),
			uint256.NewInt(uint64(userInfo.TotalSubcriptionBonus)).ToBig(),
			uint256.NewInt(uint64(userInfo.TotalMatrixBonus)).ToBig(),
			uint256.NewInt(uint64(userInfo.TotalMatchingBonus)).ToBig(),
			uint256.NewInt(uint64(userInfo.TotalSaleBonus)).ToBig(),
			revenue.ToBig(),
			uint256.NewInt(uint64(userInfo.TotalSale)).ToBig(),
			codeRef,
		)
		if err != nil {
			logger.Error("error when pack input call data", address, err)
			return
		}

		codeRefCallData := CallData{
			Action:         "call",
			Address:        "_to",
			Input:          "0x" + common.Bytes2Hex(input),
			RelatedAddress: []string{},
			Amount:         "0",
			Name:           "kventure-SetUserInfo-" + address,
		}

		output = append(output, codeRefCallData)
		jData, err := json.Marshal(output)
		if err != nil {
			panic("Error marshaling JSON")
		}
		err = os.WriteFile("calldata.json", jData, 0644)
		if err != nil {
			panic("Error writing to file")
		}

	}
	logger.Error("Done")

	sigs := make(chan os.Signal, 1)
	done := make(chan struct{})
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		close(done)
	}()
	<-done
}
