package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func SetupDiscountHistoryRoutes(
	router *gin.RouterGroup,
	DiscountHistoryHandler *handlers.DiscountHistoryHandler,
) {
	routes := router.Group("/discount-history")
	{
		routes.GET("/", DiscountHistoryHandler.QueryDiscountHistory)
	}
}
