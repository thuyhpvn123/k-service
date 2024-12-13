package routes

import (
	"github.com/gin-gonic/gin"
	"github.com/meta-node-blockchain/meta-node/cmd/kventures/internal/api/handlers"
)

func SetupLogHistoryRoutes(
	router *gin.RouterGroup,
	LogHistoryHandler *handlers.LogHistoryHandler,
) {
	routes := router.Group("/log-history")
	{
		routes.POST("/login", LogHistoryHandler.LogIn)
		routes.POST("/logout", LogHistoryHandler.UpdateLogOut)

	}
}
