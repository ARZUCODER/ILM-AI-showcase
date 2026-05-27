package api

import "github.com/gin-gonic/gin"

func RegisterChatRoutes(rg *gin.RouterGroup) {
	rg.GET("/history", handleGetHistory)
	rg.POST("/message", handleSaveMessage)
	rg.DELETE("/history", handleClearHistory) // Chat tozalash yo'li
}