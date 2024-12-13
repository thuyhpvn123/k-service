package handlers

import (
	"fmt"
	"math/big"
	"net/http"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/request"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
)

type BonusHistoryHandler struct {
	BonusHistoryRepo *repositories.BonusHistoryRepository
	kvenABI          *abi.ABI
}

func NewBonusHistoryHandler(BonusHistoryRepo *repositories.BonusHistoryRepository, kvenABI *abi.ABI) *BonusHistoryHandler {
	return &BonusHistoryHandler{BonusHistoryRepo: BonusHistoryRepo, kvenABI: kvenABI}
}

func (h *BonusHistoryHandler) QueryBonusHistory(c *gin.Context) {
	var queryData request.QueryBonusHistoryRequest

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var histories []*models.BonusHistory
	if queryData.Type != "" {
		histories, err = h.BonusHistoryRepo.GetBonusHistoryByAddressAndType(queryData.Address, queryData.Type)
	} else {
		histories, err = h.BonusHistoryRepo.GetBonusHistoryByAddress(queryData.Address)
	}
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't create BonusHistory now %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    histories,
	})
}
func (h *BonusHistoryHandler) QueryTotalBonusHistoryByTime(c *gin.Context) {
	var queryData request.QueryBonusHistoryByTimeRequest

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var histories []*models.BonusHistory
	if queryData.Type != "" {
		histories, err = h.BonusHistoryRepo.GetBonusHistoryByAddressAndTypeTime(queryData.Address, queryData.Type, queryData.From, queryData.To)
	} else {
		histories, err = h.BonusHistoryRepo.GetBonusHistoryByAddressAndTime(queryData.Address, queryData.From, queryData.To)
	}

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't create BonusHistory now %v", err),
		})
		return
	}
	var totalAmount uint64
	for _, v := range histories {
		totalAmount += v.Amount
	}
	totalBonusHistories := map[string]interface{}{
		"address":    queryData.Address,
		"totalBonus": totalAmount,
		"from":       queryData.From,
		"to":         queryData.To,
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    totalBonusHistories,
	})
}

func (h *BonusHistoryHandler) InsertHistories(c *gin.Context) {
	var reqData []request.InsertBatchBonusHistory
	err := c.ShouldBindJSON(&reqData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	histories := []*models.BonusHistory{}
	for _, data := range reqData {
		eventResult := make(map[string]interface{})
		err = h.kvenABI.UnpackIntoMap(eventResult, "PayBonus", common.FromHex(data.Data))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": fmt.Sprintf("Unable to unpack into map %v", err),
			})
			return
		}
		typ := eventResult["typ"].(string)
		add := eventResult["add"].(common.Address)
		time := uint(eventResult["time"].(*big.Int).Uint64())
		amount := eventResult["commission"].(*big.Int).Uint64()
		histories = append(histories, &models.BonusHistory{
			Address:         add.String(),
			Type:            typ,
			Time:            time,
			Amount:          amount,
			Rank:            uint(eventResult["rank"].(*big.Int).Uint64()),
			Index:           uint(eventResult["index"].(*big.Int).Uint64()),
			Rate:            uint(eventResult["rate"].(*big.Int).Uint64()),
			BlockCount:      data.BlockCount,
			TransactionHash: data.TransactionHash,
			LogHash:         data.LogHash,
		})

	}

	err = h.BonusHistoryRepo.CreateBonusHistoryBatch(histories, 100)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Create Bonus History Batch %v", err),
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
	})
}
