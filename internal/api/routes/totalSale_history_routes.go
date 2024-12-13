package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func SetupTotalSaleHistoryRoutes(
	router *gin.RouterGroup,
	EBuyProductDataHistoryHandler *handlers.EBuyProductDataHistoryHandler,
) {
	routes := router.Group("/children-history")
	{
		routes.GET("/active-user", EBuyProductDataHistoryHandler.QueryActiveUser)
		routes.GET("/last-activate", EBuyProductDataHistoryHandler.QueryLastActivate)
		routes.GET("/new-login", EBuyProductDataHistoryHandler.QueryNewLogin)
		routes.GET("/total-revenue", EBuyProductDataHistoryHandler.QueryTotalRevenue)
		routes.GET("/used-time", EBuyProductDataHistoryHandler.QueryUsedTime)

	}
}
