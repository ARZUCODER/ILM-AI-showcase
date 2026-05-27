package api

import (
	"net/http"
	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
	"ilm_ai_backend/core/quota"
)

type QuizScoreRequest struct {
	Topic string `json:"topic"`
	Score int    `json:"score"`
	Total int    `json:"total"`
}

func handleSaveScore(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var req QuizScoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Invalid request payload",
		})
		return
	}

	if req.Topic == "" || req.Total <= 0 || req.Score < 0 || req.Score > req.Total {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Invalid topic, score or total",
		})
		return
	}

	canGenerate, maxGenerations, err := quota.CheckFlashcardQuota(userEmail)
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to check quota",
		})
		return
	}

	if !canGenerate {
		remaining, _ := quota.GetFlashcardGenerationsRemaining(userEmail)
		c.JSON(http.StatusForbidden, auth.ErrorResponse{
			Code:    "FLASHCARD_QUOTA_EXCEEDED",
			Message: "You have reached your monthly flashcard generation limit",
			Details: map[string]interface{}{
				"max_generations": maxGenerations,
				"remaining": remaining,
				"upgrade_message": "Upgrade to Premium for unlimited flashcard generation",
			},
		})
		return
	}

	db.Instance.Exec(
		"INSERT INTO quiz_sessions (user_email, topic, score, total) VALUES ($1,$2,$3,$4)",
		userEmail, req.Topic, req.Score, req.Total,
	)

	remaining, _ := quota.GetFlashcardGenerationsRemaining(userEmail)
	c.JSON(http.StatusOK, gin.H{
		"ok": true,
		"flashcard_generations_remaining": remaining,
	})
}

func handleGetHistory(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	rows, err := db.Instance.Query(
		"SELECT id, topic, score, total, created_at FROM quiz_sessions WHERE user_email=$1 ORDER BY created_at DESC",
		userEmail,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to fetch history",
		})
		return
	}
	defer rows.Close()

	var history []map[string]interface{}
	for rows.Next() {
		var id, score, total int
		var topic, createdAt string
		rows.Scan(&id, &topic, &score, &total, &createdAt)
		history = append(history, map[string]interface{}{
			"id":         id,
			"topic":      topic,
			"score":      score,
			"total":      total,
			"created_at": createdAt,
		})
	}

	if history == nil {
		history = make([]map[string]interface{}, 0)
	}

	c.JSON(http.StatusOK, gin.H{
		"history": history,
	})
}