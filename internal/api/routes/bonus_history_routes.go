package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func SetupBonusHistoryRoutes(
	router *gin.RouterGroup,
	BonusHistoryHandler *handlers.BonusHistoryHandler,
) {
	routes := router.Group("/bonus-history")
	{
		routes.POST("/", BonusHistoryHandler.InsertHistories)
		routes.GET("/", BonusHistoryHandler.QueryBonusHistory)
		routes.GET("/by-time", BonusHistoryHandler.QueryTotalBonusHistoryByTime)
	}
}
