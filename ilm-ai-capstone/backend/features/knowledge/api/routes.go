package api

import "github.com/gin-gonic/gin"

func RegisterKnowledgeRoutes(rg *gin.RouterGroup) {
	rg.POST("/upload", handleFileUpload)
	rg.GET("/files", handleListFiles)
	rg.DELETE("/files/:id", handleDeleteFile)
	rg.POST("/retrieve", handleRetrieve)
}