package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"ilm_ai_backend/core/db"
)

type ErrorResponse struct {
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// AuthMiddleware resolves the authenticated user and injects their email into
// the request context. It prefers a verified Firebase ID token (Authorization:
// Bearer <token>) but falls back to the User-Email header for backward
// compatibility, so existing clients keep working during the token rollout.
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		var email string

		// 1. Prefer a verified Firebase ID token.
		authHeader := c.GetHeader("Authorization")
		if strings.HasPrefix(authHeader, "Bearer ") {
			token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
			if verified, err := VerifyToken(c.Request.Context(), token); err == nil && verified != "" {
				email = verified
			}
		}

		// 2. Fallback to the User-Email header (legacy clients / Firebase down).
		if email == "" {
			email = c.GetHeader("User-Email")
		}

		if email == "" {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Code:    "UNAUTHORIZED",
				Message: "Authentication required",
			})
			c.Abort()
			return
		}

		c.Set("user_email", email)
		c.Next()
	}
}

// ExtractUserEmail gets the authenticated user's email from context
func ExtractUserEmail(c *gin.Context) string {
	email, exists := c.Get("user_email")
	if !exists {
		return ""
	}
	return email.(string)
}

// RequireAdmin middleware checks if the caller is an admin.
// It is self-contained: it resolves identity from an existing context value,
// a Bearer token (Firebase or plain admin email), or the User-Email header,
// then verifies role='admin' in the database.
func RequireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		email := ExtractUserEmail(c)

		// Resolve identity from Authorization: Bearer <token-or-email>
		if email == "" {
			authHeader := c.GetHeader("Authorization")
			if strings.HasPrefix(authHeader, "Bearer ") {
				token := strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
				if verified, err := VerifyToken(c.Request.Context(), token); err == nil && verified != "" {
					email = verified
				} else {
					// Admin panel issues token == admin email
					email = token
				}
			}
		}

		// Final fallback: User-Email header
		if email == "" {
			email = c.GetHeader("User-Email")
		}

		if email == "" {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Code:    "UNAUTHORIZED",
				Message: "Admin authentication required",
			})
			c.Abort()
			return
		}

		// Verify the user actually has the admin role.
		var role string
		err := db.Instance.QueryRow("SELECT role FROM users WHERE email=$1", email).Scan(&role)
		if err != nil || role != "admin" {
			c.JSON(http.StatusForbidden, ErrorResponse{
				Code:    "FORBIDDEN",
				Message: "Admin access required",
			})
			c.Abort()
			return
		}

		c.Set("user_email", email)
		c.Next()
	}
}
