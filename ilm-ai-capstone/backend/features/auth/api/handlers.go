package api

import (
	"net/http"
	"ilm_ai_backend/core/db"
	"github.com/gin-gonic/gin"
)

type SyncRequest struct {
	Email        string `json:"email" binding:"required"`
	Name         string `json:"name"`
	AuthProvider string `json:"auth_provider"`
	PictureUrl   string `json:"picture_url"`
}

func handleSync(c *gin.Context) {
	var req SyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payload"})
		return
	}

	var exists bool
	db.Instance.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email=$1)", req.Email).Scan(&exists)
	if !exists {
		db.Instance.Exec(
			"INSERT INTO users (email, name, auth_provider, picture_url, tier, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
			req.Email, req.Name, req.AuthProvider, req.PictureUrl, "free",
		)
		// Initialize subscription
		db.Instance.Exec(
			"INSERT INTO user_subscriptions (user_email, tier, plan_days, expires_at, created_at, updated_at) VALUES ($1, $2, $3, NOW() + INTERVAL '7 days', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
			req.Email, "free", 7,
		)
		// Initialize feature limits
		db.Instance.Exec(
			"INSERT INTO feature_limits (user_email, max_files, max_chat_requests, max_flashcard_generation, plan_duration_days, created_at) VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)",
			req.Email, 3, 10, 50, 7,
		)
	} else {
		db.Instance.Exec(
			"UPDATE users SET auth_provider=$2, name=$3, picture_url=$4, updated_at=CURRENT_TIMESTAMP WHERE email=$1",
			req.Email, req.AuthProvider, req.Name, req.PictureUrl,
		)
	}

	var role, tier string
	db.Instance.QueryRow("SELECT role, tier FROM users WHERE email=$1", req.Email).Scan(&role, &tier)

	c.JSON(http.StatusOK, gin.H{
		"token": req.Email,
		"role":  role,
		"tier":  tier,
	})
}