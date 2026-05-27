package quota

import (
	"database/sql"
	"ilm_ai_backend/core/db"
	"time"
)

type QuotaLimits struct {
	MaxFiles              int
	MaxChatRequests       int
	MaxFlashcardGeneration int
	PlanDurationDays      int
}

// GetUserQuota retrieves the quota limits for a user based on their tier
func GetUserQuota(email string) (*QuotaLimits, error) {
	var tier string
	err := db.Instance.QueryRow(
		`SELECT COALESCE(tier, 'free') FROM users WHERE email = $1`,
		email,
	).Scan(&tier)

	if err == sql.ErrNoRows {
		// Default free tier
		return getDefaultQuota("free"), nil
	}
	if err != nil {
		return nil, err
	}

	// Get custom limits from feature_limits table if they exist
	var limits QuotaLimits
	err = db.Instance.QueryRow(
		`SELECT COALESCE(max_files, 0), COALESCE(max_chat_requests, 0), COALESCE(max_flashcard_generation, 0), COALESCE(plan_duration_days, 0)
		 FROM feature_limits WHERE user_email = $1`,
		email,
	).Scan(&limits.MaxFiles, &limits.MaxChatRequests, &limits.MaxFlashcardGeneration, &limits.PlanDurationDays)

	if err == sql.ErrNoRows {
		// No custom limits, use tier defaults
		return getDefaultQuota(tier), nil
	}
	if err != nil {
		return nil, err
	}

	return &limits, nil
}

// getDefaultQuota returns default limits based on tier
func getDefaultQuota(tier string) *QuotaLimits {
	if tier == "premium" {
		return &QuotaLimits{
			MaxFiles:              999999,
			MaxChatRequests:       999999,
			MaxFlashcardGeneration: 999999,
			PlanDurationDays:      30,
		}
	}
	// Free tier defaults
	return &QuotaLimits{
		MaxFiles:              3,
		MaxChatRequests:       10,
		MaxFlashcardGeneration: 50,
		PlanDurationDays:      7,
	}
}

// CheckFileQuota checks if user can upload another file
func CheckFileQuota(email string) (bool, int, error) {
	quota, err := GetUserQuota(email)
	if err != nil {
		return false, 0, err
	}

	// Count existing files
	var fileCount int
	err = db.Instance.QueryRow(
		`SELECT COUNT(*) FROM source_files WHERE user_email = $1`,
		email,
	).Scan(&fileCount)

	if err != nil {
		return false, 0, err
	}

	// Check if quota exceeded
	if fileCount >= quota.MaxFiles {
		return false, quota.MaxFiles, nil
	}

	return true, quota.MaxFiles, nil
}

// CheckChatQuota checks if user can send another chat message (daily limit)
func CheckChatQuota(email string) (bool, int, error) {
	quota, err := GetUserQuota(email)
	if err != nil {
		return false, 0, err
	}

	// For unlimited (premium), always allow
	if quota.MaxChatRequests >= 999999 {
		return true, quota.MaxChatRequests, nil
	}

	// Count messages sent today (only user messages)
	today := time.Now().Format("2006-01-02")
	var messageCount int
	err = db.Instance.QueryRow(
		`SELECT COUNT(*) FROM chat_history WHERE user_email = $1 AND is_user = true AND DATE(created_at) = $2`,
		email, today,
	).Scan(&messageCount)

	if err != nil && err != sql.ErrNoRows {
		return false, 0, err
	}

	// Check if quota exceeded
	if messageCount >= quota.MaxChatRequests {
		return false, quota.MaxChatRequests, nil
	}

	return true, quota.MaxChatRequests, nil
}

// GetChatRequestsRemaining returns how many chat requests the user has left today
func GetChatRequestsRemaining(email string) (int, error) {
	quota, err := GetUserQuota(email)
	if err != nil {
		return 0, err
	}

	if quota.MaxChatRequests >= 999999 {
		return 999999, nil
	}

	today := time.Now().Format("2006-01-02")
	var messageCount int
	err = db.Instance.QueryRow(
		`SELECT COUNT(*) FROM chat_history WHERE user_email = $1 AND is_user = true AND DATE(created_at) = $2`,
		email, today,
	).Scan(&messageCount)

	if err != nil && err != sql.ErrNoRows {
		return 0, err
	}

	remaining := quota.MaxChatRequests - messageCount
	if remaining < 0 {
		remaining = 0
	}

	return remaining, nil
}

// CheckFlashcardQuota checks if user can generate more flashcards (monthly limit)
func CheckFlashcardQuota(email string) (bool, int, error) {
	quota, err := GetUserQuota(email)
	if err != nil {
		return false, 0, err
	}

	// For unlimited (premium), always allow
	if quota.MaxFlashcardGeneration >= 999999 {
		return true, quota.MaxFlashcardGeneration, nil
	}

	// Count flashcard generations this month (quiz_sessions = flashcard attempts)
	currentMonth := time.Now().Format("2006-01")
	var generationCount int
	err = db.Instance.QueryRow(
		`SELECT COUNT(*) FROM quiz_sessions WHERE user_email = $1 AND DATE_TRUNC('month', created_at)::date = $2::date`,
		email, currentMonth+"-01",
	).Scan(&generationCount)

	if err != nil && err != sql.ErrNoRows {
		return false, 0, err
	}

	// Check if quota exceeded
	if generationCount >= quota.MaxFlashcardGeneration {
		return false, quota.MaxFlashcardGeneration, nil
	}

	return true, quota.MaxFlashcardGeneration, nil
}

// GetFlashcardGenerationsRemaining returns how many flashcard generations the user has left this month
func GetFlashcardGenerationsRemaining(email string) (int, error) {
	quota, err := GetUserQuota(email)
	if err != nil {
		return 0, err
	}

	if quota.MaxFlashcardGeneration >= 999999 {
		return 999999, nil
	}

	currentMonth := time.Now().Format("2006-01")
	var generationCount int
	err = db.Instance.QueryRow(
		`SELECT COUNT(*) FROM quiz_sessions WHERE user_email = $1 AND DATE_TRUNC('month', created_at)::date = $2::date`,
		email, currentMonth+"-01",
	).Scan(&generationCount)

	if err != nil && err != sql.ErrNoRows {
		return 0, err
	}

	remaining := quota.MaxFlashcardGeneration - generationCount
	if remaining < 0 {
		remaining = 0
	}

	return remaining, nil
}
