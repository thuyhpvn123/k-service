package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func SetupSubInfoHistoryRoutes(
	router *gin.RouterGroup,
	SubInfoHistoryHandler *handlers.SubInfoHistoryHandler,
) {
	routes := router.Group("/subinfo-history")
	{
		routes.GET("/new-user", SubInfoHistoryHandler.QueryNewUser)
		routes.GET("/number-of-purchase", SubInfoHistoryHandler.QueryNumberOfPurchase)
		routes.GET("/conversion", SubInfoHistoryHandler.QueryConversion)
		routes.POST("/filter", SubInfoHistoryHandler.QueryTeamFilter)

	}
}
