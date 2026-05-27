package server

import (
	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	adminApi "ilm_ai_backend/features/admin/api"
	authApi "ilm_ai_backend/features/auth/api"
	chatApi "ilm_ai_backend/features/chat/api"
	knowApi "ilm_ai_backend/features/knowledge/api"
	planApi "ilm_ai_backend/features/planner/api"
	premiumApi "ilm_ai_backend/features/premium/api"
	profileApi "ilm_ai_backend/features/profile/api"
	quizApi "ilm_ai_backend/features/quiz/api"
)

func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Dinamik CORS: Kim so'rov yuborsa, o'shanga ruxsat beradi
		origin := c.Request.Header.Get("Origin")
		if origin != "" {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		} else {
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		}

		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, User-Email")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}

func SetupServer() *gin.Engine {
	r := gin.Default()
	r.MaxMultipartMemory = 64 << 20 // 64 MB
	r.Use(corsMiddleware())

	adminApi.RegisterAdminRoutes(r.Group("/admin"))

	v1 := r.Group("/api/v1")
	authApi.RegisterAuthRoutes(v1.Group("/auth"))

	// Protected routes with authentication middleware
	knowGroup := v1.Group("/knowledge")
	knowGroup.Use(auth.AuthMiddleware())
	knowApi.RegisterKnowledgeRoutes(knowGroup)

	chatGroup := v1.Group("/chat")
	chatGroup.Use(auth.AuthMiddleware())
	chatApi.RegisterChatRoutes(chatGroup)

	planGroup := v1.Group("/planner")
	planGroup.Use(auth.AuthMiddleware())
	planApi.RegisterPlannerRoutes(planGroup)

	quizGroup := v1.Group("/quiz")
	quizGroup.Use(auth.AuthMiddleware())
	quizApi.RegisterQuizRoutes(quizGroup)

	profileGroup := v1.Group("/profile")
	profileGroup.Use(auth.AuthMiddleware())
	profileApi.RegisterProfileRoutes(profileGroup)

	premiumApi.RegisterPremiumRoutes(v1)
	adminApi.RegisterAdminRoutes(v1.Group("/admin"))

	return r
}