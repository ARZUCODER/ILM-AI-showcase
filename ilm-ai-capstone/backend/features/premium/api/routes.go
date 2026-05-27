package api

import (
	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
)

func RegisterPremiumRoutes(router *gin.RouterGroup) {
	premium := router.Group("/premium")
	{
		premium.POST("/validate-promo", handleValidatePromo)
		premium.GET("/status", handleGetSubscriptionStatus)
		premium.POST("/pay", handleGeneratePaymentLink) // Click va Payme link yasash
	}

	admin := router.Group("/admin")
	admin.Use(auth.RequireAdmin())
	{
		admin.POST("/promo/create", handleCreatePromoCode)
		admin.GET("/promo/list", handleListPromoCodes)
		admin.PUT("/promo/:code", handleUpdatePromoCode)
		admin.POST("/sync-remote-config", handleSyncRemoteConfig)
	}
}