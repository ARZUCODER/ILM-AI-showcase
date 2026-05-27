package api

import "github.com/gin-gonic/gin"

func RegisterAuthRoutes(rg *gin.RouterGroup) {
	rg.POST("/sync", handleSync)
}