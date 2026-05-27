package api

import "github.com/gin-gonic/gin"

func RegisterQuizRoutes(rg *gin.RouterGroup) {
	rg.POST("/score", handleSaveScore)
	rg.GET("/history", handleGetHistory)
}