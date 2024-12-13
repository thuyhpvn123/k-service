package main

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"log"
	"math/big"
	"os"
	"os/signal"
	"syscall"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/holiman/uint256"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	c_config "github.com/meta-node-blockchain/meta-node/cmd/client/pkg/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	pb "github.com/meta-node-blockchain/meta-node/pkg/proto"
	"github.com/meta-node-blockchain/meta-node/pkg/transaction"
)

type InfoReturn struct {
	ID        []byte
	HexID     string
	Buyer     string
	CreatedAt uint
	Products  []struct {
		Desc        string
		ImgUrl      string
		RetailPrice uint
		BoostTime   uint
		Quantity    uint
	}
	ShipInfo struct {
		FirstName     string
		LastName      string
		PhoneNumber   string
		Country       string
		State         string
		City          string
		StreetAddress string
		ZipCode       string
		Mail          string
	}
}

func base64Decode(str string) string {
	data, err := base64.StdEncoding.DecodeString(str)
	if err != nil {
		return str
	}
	return string(data)
}
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

	reader, err := os.Open(cfg.OrderABIPath) // * Unit Test
	if err != nil {
		log.Fatal("Error occured while read create card smart contract abi")
	}

	defer reader.Close()

	abi, err := abi.JSON(reader)
	if err != nil {
		log.Fatal("Error occured while parse create card smart contract abi")
	}

	// Initialize services
	output := []InfoReturn{}
	// Change index to coutinue get address
	index := 0
	for {
		input, _ := abi.Pack(
			"OrderIDs",
			big.NewInt(int64(index)),
		)

		callData := transaction.NewCallData(input)
		bData, _ := callData.Marshal()

		relatedAddress := []common.Address{}
		maxGas := uint64(5_000_000)
		maxGasPrice := uint64(1_000_000_000)
		timeUse := uint64(0)

		receipt, err := chainClient.SendTransactionWithCommission(
			common.HexToAddress(cfg.OrderAddress),
			uint256.NewInt(0),
			pb.ACTION_CALL_SMART_CONTRACT,
			bData,
			relatedAddress,
			maxGas,
			maxGasPrice,
			timeUse,
			common.FromHex(cfg.KvenAddress),
		)

		if err != nil {
			break
		}
		var bHash [32]byte
		copy(bHash[:], receipt.Return())

		input, _ = abi.Pack(
			"getmIDTOOrder",
			bHash,
		)

		callData = transaction.NewCallData(input)
		bData, _ = callData.Marshal()
		receipt, err = chainClient.SendTransactionWithCommission(
			common.HexToAddress(cfg.OrderAddress),
			uint256.NewInt(0),
			pb.ACTION_CALL_SMART_CONTRACT,
			bData,
			relatedAddress,
			maxGas,
			maxGasPrice,
			timeUse,
			common.FromHex(cfg.KvenAddress),
		)
		if err != nil {
			break
		}
		result := make(map[string]interface{})
		err = abi.UnpackIntoMap(result, "getmIDTOOrder", receipt.Return())
		if err != nil {
			logger.Error("UnpackIntoMap", err)
			return
		}
		jsonData, _ := json.Marshal(result[""])
		infoReturn := InfoReturn{}
		json.Unmarshal([]byte(jsonData), &infoReturn)
		if infoReturn.CreatedAt == 0 {
			break
		}
		logger.DebugP(infoReturn.ShipInfo)
		infoReturn.HexID = hex.EncodeToString(infoReturn.ID)
		for i, _ := range infoReturn.Products {
			infoReturn.Products[i].Desc = base64Decode(infoReturn.Products[i].Desc)
			infoReturn.Products[i].ImgUrl = base64Decode(infoReturn.Products[i].ImgUrl)
		}
		output = append(output, infoReturn)
		index++
		jsonData, err = json.Marshal(output)
		if err != nil {
			panic("Error marshaling JSON")
		}
		err = os.WriteFile("output", jsonData, 0644)
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
