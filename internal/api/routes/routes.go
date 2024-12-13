package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func InitRoutes(router *gin.RouterGroup, hlds *handlers.Handlers) {
	SetupBonusHistoryRoutes(router, hlds.BonusHistory)
	SetupDiscountHistoryRoutes(router, hlds.DiscountHistory)
	SetupTotalSaleHistoryRoutes(router, hlds.EBuyProductDataHistory)
	SetupSubInfoHistoryRoutes(router, hlds.SubInfoHistory)
	SetupLogHistoryRoutes(router,hlds.LogHistory)
}
