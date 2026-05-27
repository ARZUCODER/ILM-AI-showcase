package api

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
	"ilm_ai_backend/core/quota"
)

type SaveMessageRequest struct {
	IsUser      bool        `json:"is_user"`
	Message     string      `json:"message"`
	Citations   interface{} `json:"citations"`
	RagInfo     interface{} `json:"rag_info"`
	TotalTokens int         `json:"total_tokens"`
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

	rows, _ := db.Instance.Query(
		"SELECT id, is_user, message, COALESCE(citations,'') FROM chat_history WHERE user_email=$1 ORDER BY id ASC",
		userEmail,
	)

	var messages []gin.H
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var id int
			var isUser bool
			var msg, cit string
			rows.Scan(&id, &isUser, &msg, &cit)
			item := gin.H{"id": id, "isUser": isUser, "text": msg}
			if cit != "" {
				var cList []interface{}
				if json.Unmarshal([]byte(cit), &cList) == nil {
					item["citations"] = cList
				}
			}
			messages = append(messages, item)
		}
	}

	if len(messages) == 0 {
		messages = append(messages, gin.H{
			"id":     0,
			"isUser": false,
			"text":   "Salom! Men sizning AI ustozingizman. Hujjat yuklang yoki istalgan savolingizni bering.",
		})
	}

	remaining, _ := quota.GetChatRequestsRemaining(userEmail)
	c.JSON(http.StatusOK, gin.H{
		"history":                 messages,
		"chat_requests_remaining": remaining,
	})
}

func handleSaveMessage(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var req SaveMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Invalid request payload",
		})
		return
	}

	if req.IsUser {
		canChat, maxRequests, err := quota.CheckChatQuota(userEmail)
		if err != nil {
			c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
				Code:    "DATABASE_ERROR",
				Message: "Failed to check quota",
			})
			return
		}

		if !canChat {
			remaining, _ := quota.GetChatRequestsRemaining(userEmail)
			c.JSON(http.StatusForbidden, auth.ErrorResponse{
				Code:    "CHAT_QUOTA_EXCEEDED",
				Message: "You have reached your daily chat request limit",
				Details: map[string]interface{}{
					"max_requests":    maxRequests,
					"remaining":       remaining,
					"upgrade_message": "Upgrade to Premium for unlimited chat requests",
				},
			})
			return
		}
	}

	citB, _ := json.Marshal(req.Citations)
	ragB, _ := json.Marshal(req.RagInfo)
	citStr := string(citB)
	ragStr := string(ragB)

	if citStr == "null" {
		citStr = ""
	}
	if ragStr == "null" {
		ragStr = ""
	}

	var insertedID int
	err := db.Instance.QueryRow(
		"INSERT INTO chat_history (user_email, is_user, message, citations, rag_info, total_tokens) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id",
		userEmail, req.IsUser, req.Message,
		sql.NullString{String: citStr, Valid: citStr != ""},
		sql.NullString{String: ragStr, Valid: ragStr != ""},
		req.TotalTokens,
	).Scan(&insertedID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message"})
		return
	}

	remaining, _ := quota.GetChatRequestsRemaining(userEmail)
	c.JSON(http.StatusOK, gin.H{
		"ok":                      true,
		"id":                      insertedID,
		"chat_requests_remaining": remaining,
	})
}

func handleClearHistory(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{Code: "UNAUTHORIZED", Message: "Not authenticated"})
		return
	}

	// Chat tarixini tozalaymiz
	_, err := db.Instance.Exec("DELETE FROM chat_history WHERE user_email=$1", userEmail)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}