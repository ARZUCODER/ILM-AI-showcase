package db

import (
	"database/sql"
	"log"
	"time"

	_ "github.com/lib/pq"
)

var Instance *sql.DB

func InitDB(dsn string) {
	var conn *sql.DB
	var err error

	for i := 1; i <= 10; i++ {
		conn, err = sql.Open("postgres", dsn)
		if err == nil {
			err = conn.Ping()
			if err == nil {
				break
			}
		}
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		log.Fatalf("DB connection failed: %v", err)
	}

	mustExec := func(q string) {
		if _, err := conn.Exec(q); err != nil {
			log.Fatal(err)
		}
	}

	mustExec("CREATE EXTENSION IF NOT EXISTS vector")

	mustExec(`
		CREATE TABLE IF NOT EXISTS users (
			email VARCHAR(255) PRIMARY KEY,
			password_hash VARCHAR(255),
			name VARCHAR(255),
			auth_provider VARCHAR(50),
			role VARCHAR(20) DEFAULT 'user',
			learning_goal TEXT,
			target_date DATE,
			picture_url TEXT,
			tier VARCHAR(50) DEFAULT 'free',
			telegram_chat_id BIGINT DEFAULT 0,
			tg_auth_code VARCHAR(10),
			tg_auth_code_exp TIMESTAMP,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user'")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255)")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS picture_url TEXT")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS tier VARCHAR(50) DEFAULT 'free'")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS telegram_chat_id BIGINT DEFAULT 0")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS tg_auth_code VARCHAR(10)")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS tg_auth_code_exp TIMESTAMP")
	conn.Exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP")

	mustExec(`
		CREATE TABLE IF NOT EXISTS source_files (
			id SERIAL PRIMARY KEY,
			user_email VARCHAR(255),
			filename VARCHAR(500),
			char_count INTEGER DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS chat_history (
			id SERIAL PRIMARY KEY,
			user_email VARCHAR(255),
			is_user BOOLEAN,
			message TEXT,
			citations TEXT,
			rag_info TEXT,
			prompt_tokens INTEGER DEFAULT 0,
			response_tokens INTEGER DEFAULT 0,
			total_tokens INTEGER DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	conn.Exec("ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS prompt_tokens INTEGER DEFAULT 0")
	conn.Exec("ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS response_tokens INTEGER DEFAULT 0")
	conn.Exec("ALTER TABLE chat_history ADD COLUMN IF NOT EXISTS total_tokens INTEGER DEFAULT 0")

	mustExec(`
		CREATE TABLE IF NOT EXISTS knowledge_chunks (
			id SERIAL PRIMARY KEY,
			user_email VARCHAR(255),
			source_file_id INTEGER,
			content TEXT,
			embedding vector(768)
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS quiz_sessions (
			id SERIAL PRIMARY KEY,
			user_email VARCHAR(255),
			topic VARCHAR(255),
			score INTEGER,
			total INTEGER,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS study_plans (
			id SERIAL PRIMARY KEY,
			user_email VARCHAR(255),
			plan_json JSONB,
			duration_days INTEGER,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS promo_codes (
			id SERIAL PRIMARY KEY,
			code VARCHAR(50) UNIQUE,
			discount_percent INTEGER,
			valid_until DATE,
			max_uses INTEGER,
			used_count INTEGER DEFAULT 0,
			tier VARCHAR(50),
			is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS user_subscriptions (
			user_email VARCHAR(255) PRIMARY KEY,
			tier VARCHAR(50) DEFAULT 'free',
			promo_code_used VARCHAR(50),
			plan_days INTEGER,
			expires_at TIMESTAMP,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec(`
		CREATE TABLE IF NOT EXISTS feature_limits (
			user_email VARCHAR(255) PRIMARY KEY,
			max_files INTEGER DEFAULT 3,
			max_chat_requests INTEGER DEFAULT 10,
			max_flashcard_generation INTEGER DEFAULT 50,
			plan_duration_days INTEGER DEFAULT 7,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)

	mustExec("CREATE INDEX IF NOT EXISTS idx_chunks_user ON knowledge_chunks(user_email)")
	mustExec("CREATE INDEX IF NOT EXISTS idx_chat_user ON chat_history(user_email)")
	mustExec("CREATE INDEX IF NOT EXISTS idx_chat_user_created ON chat_history(user_email, created_at)")
	mustExec("CREATE INDEX IF NOT EXISTS idx_study_plans_user ON study_plans(user_email)")
	mustExec("CREATE INDEX IF NOT EXISTS idx_promo_code_active ON promo_codes(code) WHERE is_active = true")
	mustExec("CREATE INDEX IF NOT EXISTS idx_files_user ON source_files(user_email)")
	mustExec("CREATE INDEX IF NOT EXISTS idx_users_tg ON users(telegram_chat_id)")

	Instance = conn
}