package api

import "github.com/gin-gonic/gin"

func RegisterProfileRoutes(rg *gin.RouterGroup) {
	rg.GET("/me", handleGetProfile)
	rg.PUT("/goal", handleSetGoal)
	rg.GET("/stats", handleGetStats)
	rg.DELETE("/me", handleDeleteAccount)
	rg.POST("/tg-code", handleGenerateTgCode)
	rg.POST("/tg-disconnect", handleDisconnectTg)
}