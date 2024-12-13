package main

import (
	"encoding/hex"
	"encoding/json"
	"log"
	"math/big"
	"os"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
)

type InputInfo struct {
	Topic2 string
	Month  string
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
	reader, err := os.Open("../userInfo/kventure")
	if err != nil {
		log.Fatal("Error occured while read create card smart contract abi")
	}

	defer reader.Close()

	abi, err := abi.JSON(reader)
	if err != nil {
		log.Fatal("Error occured while parse create card smart contract abi")
	}

	// Initialize services

	input := []InputInfo{}
	output := []CallData{}

	dat, _ := os.ReadFile("input")
	err = json.Unmarshal(dat, &input)
	if err != nil {
		panic(err)
	}
	for _, v := range input {

		address := common.HexToAddress(v.Topic2)
		month, _ := big.NewInt(0).SetString(v.Month, 10)
		logger.DebugP(v.Month)
		logger.DebugP(v.Topic2)
		bcall, _ := abi.Pack(
			"PaySub",
			month,
			address,
		)
		temp := CallData{
			Action:         "call",
			Address:        "_to",
			Input:          "0x" + common.Bytes2Hex(bcall),
			RelatedAddress: []string{},
			Amount:         "0",
			Name:           "kventure-PaySub-" + hex.EncodeToString(common.HexToAddress(v.Topic2).Bytes()),
		}

		output = append(output, temp)
	}

	jData, err := json.Marshal(output)
	if err != nil {
		panic("Error marshaling JSON")
	}
	err = os.WriteFile("calldata.json", jData, 0644)
	if err != nil {
		panic("Error writing to file")
	}

}
