package api

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
)

type GeneratePlanRequest struct {
	Goal       string `json:"goal" binding:"required"`
	TargetDate string `json:"target_date" binding:"required"`
}

type PlanDay struct {
	DayNumber int      `json:"day_number"`
	Title     string   `json:"title"`
	Tasks     []string `json:"tasks"`
}

type StudyPlan struct {
	Goal  string    `json:"goal"`
	Days  []PlanDay `json:"days"`
	Total int       `json:"total"`
}

func handleGeneratePlan(c *gin.Context) {
	email := auth.ExtractUserEmail(c)
	if email == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var req GeneratePlanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Missing goal or target_date",
		})
		return
	}

	// Parse target date
	targetDate, err := time.Parse("2006-01-02", req.TargetDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_DATE",
			Message: "Target date must be in YYYY-MM-DD format",
		})
		return
	}

	// Calculate duration
	durationDays := int(time.Until(targetDate).Hours() / 24)
	if durationDays <= 0 {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_DATE",
			Message: "Target date must be in the future",
		})
		return
	}

	// Check user's tier and plan duration limits
	var tier string
	var maxPlanDays int
	err = db.Instance.QueryRow(
		`SELECT COALESCE(tier, 'free'),
		 CASE WHEN tier = 'premium' THEN 30 ELSE 7 END
		 FROM users WHERE email = $1`,
		email,
	).Scan(&tier, &maxPlanDays)

	if err == sql.ErrNoRows {
		tier = "free"
		maxPlanDays = 7
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to check user tier",
		})
		return
	}

	// Check if duration exceeds limit
	if durationDays > maxPlanDays {
		c.JSON(http.StatusForbidden, auth.ErrorResponse{
			Code:    "PLAN_DURATION_EXCEEDED",
			Message: "Plan duration exceeds your tier limit",
			Details: map[string]interface{}{
				"requested_days": durationDays,
				"allowed_days":   maxPlanDays,
				"tier":          tier,
				"upgrade_message": "Upgrade to Premium to create plans up to 30 days",
			},
		})
		return
	}

	// TODO: Call Gemini API to generate actual plan
	// For now, create a sample plan
	plan := StudyPlan{
		Goal: req.Goal,
		Days: generateSamplePlan(durationDays),
		Total: durationDays,
	}

	// Save plan to database
	planJSON, _ := json.Marshal(plan)
	_, saveErr := db.Instance.Exec(
		`INSERT INTO study_plans (user_email, plan_json, duration_days, created_at, updated_at)
		 VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
		email, string(planJSON), durationDays,
	)

	if saveErr != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to save plan",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"plan": plan,
		"tier": tier,
	})
}

func handleGetPlan(c *gin.Context) {
	email := auth.ExtractUserEmail(c)
	if email == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var planJSON string
	err := db.Instance.QueryRow(
		"SELECT plan_json FROM study_plans WHERE user_email = $1 ORDER BY created_at DESC LIMIT 1",
		email,
	).Scan(&planJSON)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, auth.ErrorResponse{
			Code:    "NOT_FOUND",
			Message: "No plan found for this user",
		})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to retrieve plan",
		})
		return
	}

	var plan StudyPlan
	json.Unmarshal([]byte(planJSON), &plan)

	c.JSON(http.StatusOK, gin.H{
		"plan": plan,
	})
}

func handleRegeneratePlan(c *gin.Context) {
	// Same logic as generate, but replaces existing plan
	handleGeneratePlan(c)
}

func generateSamplePlan(days int) []PlanDay {
	var planDays []PlanDay
	for i := 1; i <= days; i++ {
		dayNum := i % 10
		planDays = append(planDays, PlanDay{
			DayNumber: i,
			Title:     "Day " + string(rune(48+dayNum)),
			Tasks: []string{
				"Review materials",
				"Practice exercises",
				"Take notes",
			},
		})
	}
	return planDays
}