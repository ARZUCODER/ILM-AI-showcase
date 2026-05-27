package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
	"ilm_ai_backend/core/server"
	"ilm_ai_backend/features/telegram"
)

func main() {
	godotenv.Load()

	createAdminEmail := flag.String("create-admin", "", "")
	createAdminPass := flag.String("password", "", "")
	flag.Parse()

	dsn := os.Getenv("DB_DSN")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@db:5432/ilmai?sslmode=disable"
	}
	db.InitDB(dsn)

	auth.InitFirebase()

	telegramToken := os.Getenv("TELEGRAM_BOT_TOKEN")
	if telegramToken != "" {
		go telegram.StartBot(telegramToken)
	} else {
		log.Println("TELEGRAM_BOT_TOKEN is not set in .env. Bot will not start.")
	}

	if *createAdminEmail != "" && *createAdminPass != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(*createAdminPass), bcrypt.DefaultCost)
		if err != nil {
			log.Fatal(err)
		}

		_, err = db.Instance.Exec(
			"INSERT INTO users (email, password_hash, name, auth_provider, role) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (email) DO UPDATE SET password_hash = $2, role = $5",
			*createAdminEmail, string(hash), "Admin", "email", "admin",
		)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Printf("Admin account %s created/updated successfully.\n", *createAdminEmail)
		os.Exit(0)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	app := server.SetupServer()
	log.Fatal(app.Run(":" + port))
}