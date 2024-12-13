package main

import (
	"encoding/hex"
	"encoding/json"
	"log"
	"os"

	pb "github.com/meta-node-blockchain/meta-node/pkg/proto"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/holiman/uint256"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	c_config "github.com/meta-node-blockchain/meta-node/cmd/client/pkg/config"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/config"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	"github.com/meta-node-blockchain/meta-node/pkg/transaction"
)

type ProductReturn struct {
	ID          []byte
	ImgUrl      []byte
	MemberPrice uint
	RetailPrice uint
	Desc        []byte
	Active      bool
	BoostTime   uint
}

type ProductOutput struct {
	ID          string
	ImgUrl      string
	MemberPrice uint
	RetailPrice uint
	Desc        string
	Active      bool
	BoostTime   uint
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

	reader, err := os.Open(cfg.ProductABIPath) // * Unit Test
	if err != nil {
		log.Fatal("Error occured while read create card smart contract abi")
	}

	defer reader.Close()

	abi, err := abi.JSON(reader)
	if err != nil {
		log.Fatal("Error occured while parse create card smart contract abi")
	}

	input, err := abi.Pack(
		"userViewProduct",
	)
	if err != nil {
		logger.Error("error when pack call data", err)
		panic(err)
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", err)
		panic(err)
	}

	relatedAddress := []common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	receipt, err := chainClient.SendTransaction(
		common.HexToAddress(cfg.ProductAddress),
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)

	if err != nil {
		panic(1)
	}

	result := make(map[string]interface{})
	err = abi.UnpackIntoMap(result, "userViewProduct", receipt.Return())
	if err != nil {
		logger.Error("UnpackIntoMap", err)
		return
	}

	jsonData, err := json.Marshal(result["_products"])
	if err != nil {
		logger.Error("json.Marshal(result)", err)
		return
	}

	products := []ProductReturn{}
	err = json.Unmarshal([]byte(jsonData), &products)
	if err != nil {
		logger.Error("json.Marshal(result)", err)
		return
	}

	output := []ProductOutput{}
	for _, product := range products {
		url, err := hex.DecodeString(common.Bytes2Hex(product.ImgUrl))
		if err != nil {
			panic(err)
		}
		desc, err := hex.DecodeString(common.Bytes2Hex(product.Desc))
		if err != nil {
			panic(err)
		}
		output = append(output, ProductOutput{
			ID:          common.Bytes2Hex(product.ID),
			ImgUrl:      string(url),
			Desc:        string(desc),
			MemberPrice: product.MemberPrice,
			RetailPrice: product.RetailPrice,
			Active:      product.Active,
			BoostTime:   product.BoostTime,
		})
	}

	jData, err := json.Marshal(output)
	if err != nil {
		panic("Error marshaling JSON")
	}
	err = os.WriteFile("products.json", jData, 0644)
	if err != nil {
		panic("Error writing to file")
	}

}
