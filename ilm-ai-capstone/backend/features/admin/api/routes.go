package api

import (
	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
)

func RegisterAdminRoutes(rg *gin.RouterGroup) {
	// Admin panel SPA (public HTML; its API calls require admin auth).
	rg.GET("/ui", servePanel)

	// Login is public; everything else requires admin role.
	rg.POST("/login", handleAdminLogin)

	protected := rg.Group("")
	protected.Use(auth.RequireAdmin())
	{
		protected.GET("/dashboard", handleGetDashboardStats)
		protected.GET("/chats", handleGetAdminChats)
		protected.GET("/users", handleGetAdminUsers)
	}
}
