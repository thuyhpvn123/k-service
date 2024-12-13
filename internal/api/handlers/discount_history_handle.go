package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/request"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/models"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/database/repositories"
)

type DiscountHistoryHandler struct {
	DiscountHistoryRepo *repositories.DiscountHistoryRepository
}

func NewDiscountHistoryHandler(DiscountHistoryRepo *repositories.DiscountHistoryRepository) *DiscountHistoryHandler {
	return &DiscountHistoryHandler{DiscountHistoryRepo: DiscountHistoryRepo}
}

func (h *DiscountHistoryHandler) QueryDiscountHistory(c *gin.Context) {
	var queryData request.QueryDiscountHistoryRequest

	err := c.ShouldBindQuery(&queryData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Unable to bind query %v", err),
		})
		return
	}
	var histories []*models.DiscountHistory
	histories, err = h.DiscountHistoryRepo.GetDiscountHistoryByAddress(queryData.Address)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": fmt.Sprintf("Can't get DiscountHistory now %v", err),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "successful request",
		"data":    histories,
	})
}
