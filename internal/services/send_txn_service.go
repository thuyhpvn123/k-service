package services

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/accounts/abi"
	e_common "github.com/ethereum/go-ethereum/common"
	"github.com/holiman/uint256"
	"github.com/meta-node-blockchain/meta-node/cmd/client"
	"github.com/meta-node-blockchain/meta-node/pkg/logger"
	pb "github.com/meta-node-blockchain/meta-node/pkg/proto"
	"github.com/meta-node-blockchain/meta-node/pkg/transaction"
	"github.com/meta-node-blockchain/meta-node/types"
	"fmt"
)

type SendTransactionService struct {
	chainClient     *client.Client
	kventureAbi     *abi.ABI
	kventureAddress e_common.Address
}
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

func NewSendTransactionService(
	chainClient *client.Client,
	kventureAbi *abi.ABI,
	kventureAddress e_common.Address,
) *SendTransactionService {
	return &SendTransactionService{
		chainClient:     chainClient,
		kventureAbi:     kventureAbi,
		kventureAddress: kventureAddress,
	}
}

func (h *SendTransactionService) CallPayGoodSaleBonusWeekly() error {
	input, err := h.kventureAbi.Pack(
		"payGoodSaleBonusWeekly",
	)
	if err != nil {
		logger.Error("error when pack call data", err)
		return err
	}
	callData := transaction.NewCallData(input)
	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", err)
		return err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	receipt, err := h.chainClient.SendTransaction(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)

	logger.Info("receipt CallPayGoodSaleBonusWeekly", receipt)

	if err != nil {
		logger.Error("error when send transaction", err)
		return errors.New("call chain failed")
	} else if receipt.Status() == pb.RECEIPT_STATUS_RETURNED {
		return nil
	} else if receipt.Status() == pb.RECEIPT_STATUS_THREW {
		return errors.New(e_common.Bytes2Hex(receipt.Return()))
	} else {
		return errors.New("call chain failed")
	}
}

func (h *SendTransactionService) CallUpdateRankDaily() error {
	input, err := h.kventureAbi.Pack(
		"updateRankDaily",
	)
	if err != nil {
		logger.Error("error when pack call data", err)
		return err
	}
	callData := transaction.NewCallData(input)
	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", err)
		return err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	receipt, err := h.chainClient.SendTransaction(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)

	logger.Info("receipt CallUpdateRankDaily", receipt)

	if err != nil {
		logger.Error("error when send transaction", err)
		return errors.New("call chain failed")
	} else if receipt.Status() == pb.RECEIPT_STATUS_RETURNED {
		return nil
	} else if receipt.Status() == pb.RECEIPT_STATUS_THREW {
		return errors.New(e_common.Bytes2Hex(receipt.Return()))
	} else {
		return errors.New("call chain failed")
	}
}

func (h *SendTransactionService) CallAddressList(index uint64) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"addressList",
		uint256.NewInt(index).ToBig(),
	)
	if err != nil {
		logger.Error("error when pack call data", index, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", index, err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	return h.chainClient.SendTransaction(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)

}
func (h *SendTransactionService) CallmIDTOOrder(id string) (types.Receipt, error) {
	bytes, err := hex.DecodeString(id)
	fmt.Println("id:",id)
	if err != nil {
		logger.Error("error when pack call data", id, err)
		return nil, err
	}
	// Convert string to bytes32
    var bid [32]byte
    copy(bid[:], bytes)
	input, err := h.kventureAbi.Pack(
		"mIDTOOrder",
		bid,
	)
	if err != nil {
		logger.Error("error when pack call data", err)
		return nil, err
	}
	fmt.Println("input:",hex.EncodeToString(input))

	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)
	commissionPrivateKey,err := hex.DecodeString("2b3aa0f620d2d73c046cd93eb64f2eb687a95b22e278500aa251c8c9dda1203b")
	return h.chainClient.SendTransactionWithCommission(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
		commissionPrivateKey,
	)

}
func (h *SendTransactionService) CallmAddressTOOrderID(address string,index uint64) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"mAddressTOOrderID",
		common.HexToAddress(address),
		uint256.NewInt(index).ToBig(),
	)
	if err != nil {
		logger.Error("error when pack call data",index, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)
	commissionPrivateKey,err := hex.DecodeString("2b3aa0f620d2d73c046cd93eb64f2eb687a95b22e278500aa251c8c9dda1203b")
	return h.chainClient.SendTransactionWithCommission(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
		commissionPrivateKey,
	)

}
func (h *SendTransactionService) CallUserBuyList(index uint64) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"Users",
		uint256.NewInt(index).ToBig(),
	)
	if err != nil {
		logger.Error("error when pack call data", index, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", index, err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)
	commissionPrivateKey,err := hex.DecodeString("2b3aa0f620d2d73c046cd93eb64f2eb687a95b22e278500aa251c8c9dda1203b")
	return h.chainClient.SendTransactionWithCommission(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
		commissionPrivateKey,
	)

}
func (h *SendTransactionService) CallGetUserInfo(address string) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"GetUserInfo",
		e_common.HexToAddress(address),
	)
	if err != nil {
		logger.Error("error when pack call data", address, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", address, err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)
	// commissionPrivateKey,err := hex.DecodeString("2b3aa0f620d2d73c046cd93eb64f2eb687a95b22e278500aa251c8c9dda1203b")

	// return h.chainClient.SendTransactionWithCommission(
	return h.chainClient.SendTransaction(

		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
		// commissionPrivateKey,

	)
}

func (h *SendTransactionService) CallGetSubcribeInfo(address string) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"mSubInfo",
		e_common.HexToAddress(address),
	)
	if err != nil {
		logger.Error("error when pack call data", address, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", address, err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	return h.chainClient.SendTransaction(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)
}

func (h *SendTransactionService) CallGetRevenue(address string) (types.Receipt, error) {
	input, err := h.kventureAbi.Pack(
		"totalRevenues",
		e_common.HexToAddress(address),
	)
	if err != nil {
		logger.Error("error when pack call data", address, err)
		return nil, err
	}
	callData := transaction.NewCallData(input)

	bData, err := callData.Marshal()
	if err != nil {
		logger.Error("error when marshal call data", address, err)
		return nil, err
	}

	relatedAddress := []e_common.Address{}
	maxGas := uint64(5_000_000)
	maxGasPrice := uint64(1_000_000_000)
	timeUse := uint64(0)

	return h.chainClient.SendTransaction(
		h.kventureAddress,
		uint256.NewInt(0),
		pb.ACTION_CALL_SMART_CONTRACT,
		bData,
		relatedAddress,
		maxGas,
		maxGasPrice,
		timeUse,
	)
}
func (h *SendTransactionService) CallChildrenArr(address string) ([]string,error) {
	var childrenArr []string
	receipt, err := h.CallGetUserInfo(address)
	if err != nil {
		logger.Error("error call children arr", address, err)
		return childrenArr,err
	}
	result := make(map[string]interface{})
	err = h.kventureAbi.UnpackIntoMap(result, "GetUserInfo", receipt.Return())
	if err != nil {
		logger.Error("UnpackIntoMap", address)
		return childrenArr,err
	}
	jsonData, err := json.Marshal(result["userinfo"])
	if err != nil {
		logger.Error("json.Marshal(result)", address)
		return childrenArr,err
	}
	infoReturn := InfoReturn{}
	err = json.Unmarshal([]byte(jsonData), &infoReturn)
	if err != nil {
		logger.Error("json.Unmarshal([]byte(jsonData), &infoReturn)", address)
		return childrenArr,err
	}
	childrenArr = infoReturn.Childrens
	return childrenArr, nil
}
