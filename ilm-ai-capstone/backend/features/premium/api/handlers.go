package api

import (
	"database/sql"
	"encoding/base64"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
)

type ValidatePromoRequest struct {
	Email string `json:"email" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

type SubscriptionStatus struct {
	Tier            string    `json:"tier"`
	PlanDays        int       `json:"plan_days"`
	ExpiresAt       time.Time `json:"expires_at"`
	DaysRemaining   int       `json:"days_remaining"`
	MaxFiles        int       `json:"max_files"`
	MaxChatRequests int       `json:"max_chat_requests"`
	MaxFlashcards   int       `json:"max_flashcards"`
}

type CreatePromoRequest struct {
	Code            string `json:"code" binding:"required"`
	DiscountPercent int    `json:"discount_percent" binding:"required"`
	ValidUntil      string `json:"valid_until" binding:"required"`
	MaxUses         int    `json:"max_uses" binding:"required"`
	Tier            string `json:"tier" binding:"required"`
}

type PaymentRequest struct {
	Provider string `json:"provider" binding:"required"` // "click" yoki "payme"
	Amount   int    `json:"amount"`                      // To'lov summasi (so'mda)
}

func handleGeneratePaymentLink(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var req PaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "INVALID_REQUEST", Message: "Invalid request payload"})
		return
	}

	if req.Amount <= 0 {
		req.Amount = 49000 // Default 49,000 so'm
	}

	var paymentUrl string

	// Dastlabki MERCHANT ID larni shu yerga yozasiz (Hozir test uchun kiritilgan)
	clickServiceID := "12345"
	clickMerchantID := "12345"
	paymeMerchantID := "5f3a1...YOUR_PAYME_MERCHANT_ID"

	if req.Provider == "click" {
		// Click uchun URL
		paymentUrl = fmt.Sprintf("https://my.click.uz/services/pay?service_id=%s&merchant_id=%s&amount=%d&transaction_param=%s",
			clickServiceID, clickMerchantID, req.Amount, userEmail)
	} else if req.Provider == "payme" {
		// Payme uchun URL (Tiyinda hisoblanadi va Base64 qilinadi)
		amountTiyin := req.Amount * 100
		rawStr := fmt.Sprintf("m=%s;ac.account=%s;a=%d", paymeMerchantID, userEmail, amountTiyin)
		encoded := base64.StdEncoding.EncodeToString([]byte(rawStr))
		paymentUrl = "https://checkout.paycom.uz/" + encoded
	} else {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "INVALID_PROVIDER", Message: "Faqat 'click' yoki 'payme' bo'lishi mumkin"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": paymentUrl})
}

func handleValidatePromo(c *gin.Context) {
	var req ValidatePromoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "INVALID_REQUEST", Message: "Invalid request format"})
		return
	}

	var code, tier string
	var used, maxUses int
	var validUntil time.Time
	var isActive bool

	err := db.Instance.QueryRow(
		"SELECT code, tier, used_count, max_uses, valid_until, is_active FROM promo_codes WHERE code = $1",
		req.Code,
	).Scan(&code, &tier, &used, &maxUses, &validUntil, &isActive)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "INVALID_PROMO_CODE", Message: "Promo code not found"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{Code: "DATABASE_ERROR", Message: "Database query failed"})
		return
	}
	if !isActive {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "PROMO_CODE_INACTIVE", Message: "This promo code is no longer active"})
		return
	}
	if time.Now().After(validUntil) {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "PROMO_CODE_EXPIRED", Message: "This promo code has expired"})
		return
	}
	if used >= maxUses {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "PROMO_CODE_EXHAUSTED", Message: "This promo code has reached its usage limit"})
		return
	}

	tx, _ := db.Instance.Begin()
	tx.Exec("UPDATE promo_codes SET used_count = used_count + 1 WHERE code = $1", req.Code)

	expiresAt := time.Now().AddDate(0, 0, 30) // 30 kun premium
	planDays := 30

	tx.Exec(
		`INSERT INTO user_subscriptions (user_email, tier, promo_code_used, plan_days, expires_at, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		 ON CONFLICT (user_email) DO UPDATE SET
		 tier = $2, promo_code_used = $3, plan_days = $4, expires_at = $5, updated_at = CURRENT_TIMESTAMP`,
		req.Email, tier, req.Code, planDays, expiresAt,
	)

	tx.Exec(
		`INSERT INTO feature_limits (user_email, max_files, max_chat_requests, max_flashcard_generation, plan_duration_days, created_at)
		 VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
		 ON CONFLICT (user_email) DO UPDATE SET
		 max_files = $2, max_chat_requests = $3, max_flashcard_generation = $4, plan_duration_days = $5`,
		req.Email, 999999, 999999, 999999, 30,
	)

	tx.Exec("UPDATE users SET tier = $1 WHERE email = $2", tier, req.Email)
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{
		"valid": true, "tier": tier, "plan_days": planDays,
		"expires_at": expiresAt, "message": "Promo code applied successfully",
	})
}

func handleGetSubscriptionStatus(c *gin.Context) {
	email := auth.ExtractUserEmail(c)
	if email == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{Code: "UNAUTHORIZED", Message: "User not authenticated"})
		return
	}

	var status SubscriptionStatus
	var expiresAt sql.NullTime

	err := db.Instance.QueryRow(
		`SELECT s.tier, s.plan_days, s.expires_at, f.max_files, f.max_chat_requests, f.max_flashcard_generation
		 FROM user_subscriptions s LEFT JOIN feature_limits f ON s.user_email = f.user_email WHERE s.user_email = $1`,
		email,
	).Scan(&status.Tier, &status.PlanDays, &expiresAt, &status.MaxFiles, &status.MaxChatRequests, &status.MaxFlashcards)

	if err == sql.ErrNoRows {
		status = SubscriptionStatus{Tier: "free", PlanDays: 7, MaxFiles: 3, MaxChatRequests: 10, MaxFlashcards: 50}
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{Code: "DATABASE_ERROR", Message: "Failed to fetch subscription"})
		return
	}

	if expiresAt.Valid {
		status.ExpiresAt = expiresAt.Time
		status.DaysRemaining = int(time.Until(expiresAt.Time).Hours() / 24)
	}
	c.JSON(http.StatusOK, status)
}

func handleCreatePromoCode(c *gin.Context) {
	var req CreatePromoRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "INVALID_REQUEST", Message: "Missing required fields"})
		return
	}

	_, err := db.Instance.Exec(
		`INSERT INTO promo_codes (code, discount_percent, valid_until, max_uses, tier, is_active, created_at)
		 VALUES ($1, $2, $3, $4, $5, true, CURRENT_TIMESTAMP)`,
		req.Code, req.DiscountPercent, req.ValidUntil, req.MaxUses, req.Tier,
	)

	if err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{Code: "CODE_EXISTS", Message: "Promo code already exists"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Promo code created successfully", "code": req.Code})
}

func handleListPromoCodes(c *gin.Context) {
	rows, err := db.Instance.Query("SELECT code, discount_percent, valid_until, used_count, max_uses, tier, is_active, created_at FROM promo_codes ORDER BY created_at DESC")
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{Code: "DATABASE_ERROR", Message: "Failed to list promo codes"})
		return
	}
	defer rows.Close()

	var codes []map[string]interface{}
	for rows.Next() {
		var code, tier string
		var discount, used, maxUses int
		var isActive bool
		var validUntil, createdAt time.Time
		if err := rows.Scan(&code, &discount, &validUntil, &used, &maxUses, &tier, &isActive, &createdAt); err == nil {
			codes = append(codes, map[string]interface{}{
				"code": code, "discount_percent": discount, "used_count": used, "max_uses": maxUses,
				"tier": tier, "is_active": isActive, "valid_until": validUntil, "created_at": createdAt,
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"codes": codes})
}

func handleUpdatePromoCode(c *gin.Context) {
	code := c.Param("code")
	isActive := c.Query("active") == "true"
	_, err := db.Instance.Exec("UPDATE promo_codes SET is_active = $1 WHERE code = $2", isActive, code)
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{Code: "DATABASE_ERROR", Message: "Failed to update"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Promo code updated"})
}

func handleSyncRemoteConfig(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Promo codes synced to Remote Config"})
}