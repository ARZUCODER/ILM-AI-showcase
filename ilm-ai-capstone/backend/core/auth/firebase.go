package auth

import (
	"context"
	"fmt"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
)

var Client *auth.Client

func InitFirebase() {
	ctx := context.Background()
	config := &firebase.Config{
		ProjectID: os.Getenv("GOOGLE_CLOUD_PROJECT"),
	}
	if config.ProjectID == "" {
		config.ProjectID = "ilm-ai-app"
	}

	app, err := firebase.NewApp(ctx, config)
	if err != nil {
		log.Printf("Warning: Firebase initialization failed: %v. Running without Firebase auth validation.", err)
		return
	}

	Client, err = app.Auth(ctx)
	if err != nil {
		log.Printf("Warning: Could not get Auth client: %v. Running without Firebase auth validation.", err)
		return
	}

	log.Println("Firebase Auth client initialized successfully")
}

// VerifyToken verifies Firebase ID token and extracts user email
func VerifyToken(ctx context.Context, token string) (string, error) {
	if Client == nil {
		// Fallback if Firebase not initialized - check headers for email
		return "", fmt.Errorf("firebase not initialized")
	}

	decodedToken, err := Client.VerifyIDToken(ctx, token)
	if err != nil {
		return "", fmt.Errorf("token verification failed: %v", err)
	}

	email, ok := decodedToken.Claims["email"].(string)
	if !ok || email == "" {
		return "", fmt.Errorf("no email in token")
	}

	return email, nil
}

// IsAdmin checks if user has admin role (would need custom claims in Firebase)
func IsAdmin(ctx context.Context, email string) (bool, error) {
	if Client == nil {
		return false, fmt.Errorf("firebase not initialized")
	}

	user, err := Client.GetUserByEmail(ctx, email)
	if err != nil {
		return false, err
	}

	customClaims := user.CustomClaims
	if customClaims == nil {
		return false, nil
	}

	isAdmin, ok := customClaims["admin"].(bool)
	return ok && isAdmin, nil
}
