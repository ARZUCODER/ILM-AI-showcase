package api

import (
	"database/sql"
	"math/rand"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
)

type GoalRequest struct {
	Goal       string `json:"goal"`
	TargetDate string `json:"target_date"`
}

func handleGetProfile(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User-Email required"})
		return
	}

	var name, provider sql.NullString
	var goal sql.NullString
	var targetDate sql.NullTime
	var createdAt sql.NullTime
	var tgChatID sql.NullInt64

	err := db.Instance.QueryRow(
		"SELECT name, auth_provider, learning_goal, target_date, created_at, telegram_chat_id FROM users WHERE email=$1",
		userEmail,
	).Scan(&name, &provider, &goal, &targetDate, &createdAt, &tgChatID)

	if err == sql.ErrNoRows {
		db.Instance.Exec("INSERT INTO users (email, auth_provider, tier) VALUES ($1, 'firebase', 'free')", userEmail)
	}

	var daysLeft *int
	if targetDate.Valid {
		days := int(time.Until(targetDate.Time).Hours() / 24)
		if days < 0 {
			days = 0
		}
		daysLeft = &days
	}

	isTgLinked := false
	if tgChatID.Valid && tgChatID.Int64 > 0 {
		isTgLinked = true
	}

	resp := gin.H{
		"email":         userEmail,
		"name":          name.String,
		"auth_provider": provider.String,
		"learning_goal": goal.String,
		"tg_linked":     isTgLinked,
	}
	if targetDate.Valid {
		resp["target_date"] = targetDate.Time.Format("2006-01-02")
		resp["days_left"] = daysLeft
	}
	if createdAt.Valid {
		resp["created_at"] = createdAt.Time.Format(time.RFC3339)
	}
	c.JSON(http.StatusOK, resp)
}

func handleSetGoal(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	var req GoalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid body"})
		return
	}

	var targetTime sql.NullTime
	if req.TargetDate != "" {
		t, err := time.Parse("2006-01-02", req.TargetDate)
		if err == nil {
			targetTime = sql.NullTime{Time: t, Valid: true}
		}
	}

	_, err := db.Instance.Exec("UPDATE users SET learning_goal=$1, target_date=$2 WHERE email=$3", req.Goal, targetTime, userEmail)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func handleDeleteAccount(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	tx, _ := db.Instance.Begin()
	tables := []string{"quiz_sessions", "chat_history", "knowledge_chunks", "source_files", "study_plans"}
	for _, table := range tables {
		tx.Exec("DELETE FROM "+table+" WHERE user_email=$1", userEmail)
	}
	tx.Exec("DELETE FROM users WHERE email=$1", userEmail)
	tx.Commit()
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func handleGetStats(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	var filesCount, chunksCount, chatCount, quizCount, totalScore, totalQuestions int
	db.Instance.QueryRow("SELECT COUNT(*) FROM source_files WHERE user_email=$1", userEmail).Scan(&filesCount)
	db.Instance.QueryRow("SELECT COUNT(*) FROM knowledge_chunks WHERE user_email=$1", userEmail).Scan(&chunksCount)
	db.Instance.QueryRow("SELECT COUNT(*) FROM chat_history WHERE user_email=$1 AND is_user=true", userEmail).Scan(&chatCount)
	db.Instance.QueryRow("SELECT COUNT(*), COALESCE(SUM(score),0), COALESCE(SUM(total),0) FROM quiz_sessions WHERE user_email=$1", userEmail).Scan(&quizCount, &totalScore, &totalQuestions)

	var accuracy float64
	if totalQuestions > 0 {
		accuracy = float64(totalScore) / float64(totalQuestions) * 100
	}

	c.JSON(http.StatusOK, gin.H{
		"files":          filesCount,
		"chunks":         chunksCount,
		"chat_messages":  chatCount,
		"quiz_sessions":  quizCount,
		"questions_done": totalQuestions,
		"accuracy":       accuracy,
	})
}

func generateRandomString(length int) string {
	rand.Seed(time.Now().UnixNano())
	chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, length)
	for i := 0; i < length; i++ {
		result[i] = chars[rand.Intn(len(chars))]
	}
	return string(result)
}

func handleGenerateTgCode(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	code := generateRandomString(6)

	res, err := db.Instance.Exec(
		"UPDATE users SET tg_auth_code=$1, tg_auth_code_exp=CURRENT_TIMESTAMP + INTERVAL '10 minutes' WHERE email=$2",
		code, userEmail,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Baza xatosi: " + err.Error()})
		return
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		db.Instance.Exec("INSERT INTO users (email, auth_provider, tier) VALUES ($1, 'firebase', 'free')", userEmail)
		db.Instance.Exec("UPDATE users SET tg_auth_code=$1, tg_auth_code_exp=CURRENT_TIMESTAMP + INTERVAL '10 minutes' WHERE email=$2", code, userEmail)
	}

	c.JSON(http.StatusOK, gin.H{"code": code})
}

func handleDisconnectTg(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	db.Instance.Exec("UPDATE users SET telegram_chat_id = 0, tg_auth_code = NULL, tg_auth_code_exp = NULL WHERE email=$1", userEmail)
	c.JSON(http.StatusOK, gin.H{"ok": true})
}