package api

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"ilm_ai_backend/core/db"
)

type AdminLoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func handleAdminLogin(c *gin.Context) {
	var req AdminLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payload"})
		return
	}

	var hash, role string
	err := db.Instance.QueryRow("SELECT password_hash, role FROM users WHERE email=$1", req.Email).Scan(&hash, &role)
	if err == sql.ErrNoRows || role != "admin" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": req.Email,
		"role":  role,
	})
}

func handleGetDashboardStats(c *gin.Context) {
	var totalUsers, totalChunks, totalChats int
	var totalTokens int64

	db.Instance.QueryRow("SELECT COUNT(*) FROM users").Scan(&totalUsers)
	db.Instance.QueryRow("SELECT COUNT(*) FROM knowledge_chunks").Scan(&totalChunks)
	db.Instance.QueryRow("SELECT COUNT(*) FROM chat_history").Scan(&totalChats)
	db.Instance.QueryRow("SELECT COALESCE(SUM(total_tokens), 0) FROM chat_history").Scan(&totalTokens)

	c.JSON(http.StatusOK, gin.H{
		"total_users":  totalUsers,
		"total_chunks": totalChunks,
		"total_chats":  totalChats,
		"total_tokens": totalTokens,
	})
}

func handleGetAdminChats(c *gin.Context) {
	rows, _ := db.Instance.Query("SELECT id, user_email, is_user, message, COALESCE(rag_info, ''), total_tokens FROM chat_history ORDER BY id DESC LIMIT 200")
	var chats []gin.H
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var id, tokens int
			var isUser bool
			var email, msg, ragInfoStr string
			rows.Scan(&id, &email, &isUser, &msg, &ragInfoStr, &tokens)

			var ragInfo interface{}
			if ragInfoStr != "" {
				json.Unmarshal([]byte(ragInfoStr), &ragInfo)
			}

			chats = append(chats, gin.H{
				"id":           id,
				"email":        email,
				"is_user":      isUser,
				"message":      msg,
				"rag_info":     ragInfo,
				"total_tokens": tokens,
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"chats": chats})
}

func handleGetAdminUsers(c *gin.Context) {
	rows, _ := db.Instance.Query("SELECT email, auth_provider, role, COALESCE(learning_goal, '') FROM users ORDER BY created_at DESC")
	var users []gin.H
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var email, auth, role, goal string
			rows.Scan(&email, &auth, &role, &goal)
			users = append(users, gin.H{
				"email": email,
				"auth":  auth,
				"role":  role,
				"goal":  goal,
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}