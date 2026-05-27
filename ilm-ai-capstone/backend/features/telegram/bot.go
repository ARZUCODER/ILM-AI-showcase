package telegram

import (
	"database/sql"
	"fmt"
	"log"
	"strings"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"ilm_ai_backend/core/db"
)

var Bot *tgbotapi.BotAPI

const webAppURL = "https://ilmai.arzucoder.uz/"

func StartBot(token string) {
	if token == "" {
		log.Println("TELEGRAM_BOT_TOKEN topilmadi")
		return
	}

	var err error
	Bot, err = tgbotapi.NewBotAPI(token)
	if err != nil {
		log.Printf("Botni ishga tushirishda xatolik: %v", err)
		return
	}

	log.Printf("Bot muvaffaqiyatli ulandi: %s", Bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60
	updates := Bot.GetUpdatesChan(u)

	go func() {
		for update := range updates {
			if update.Message != nil {
				handleMessage(update.Message)
			} else if update.CallbackQuery != nil {
				handleCallback(update.CallbackQuery)
			}
		}
	}()
}

func handleMessage(msg *tgbotapi.Message) {
	chatID := msg.Chat.ID
	text := strings.TrimSpace(msg.Text)

	if strings.HasPrefix(text, "/start") {
		parts := strings.Split(text, " ")
		if len(parts) == 2 {
			code := parts[1]
			processCode(chatID, code)
			return
		}

		var email string
		err := db.Instance.QueryRow("SELECT email FROM users WHERE telegram_chat_id = $1", chatID).Scan(&email)

		if err == sql.ErrNoRows || email == "" {
			sendGuestMenu(chatID)
		} else {
			sendMainMenu(chatID, email)
		}
		return
	}

	if len(text) == 6 {
		processCode(chatID, strings.ToUpper(text))
		return
	}

	sendMessage(chatID, "Please use the menu buttons or send your 6-digit connection code.")
}

func processCode(chatID int64, code string) {
	var email string
	err := db.Instance.QueryRow("SELECT email FROM users WHERE tg_auth_code = $1 AND tg_auth_code_exp > CURRENT_TIMESTAMP", code).Scan(&email)

	if err == sql.ErrNoRows {
		sendMessage(chatID, "❌ Invalid or expired code. Please generate a new one in the Web App.")
		sendGuestMenu(chatID)
		return
	} else if err != nil {
		sendMessage(chatID, "Server error processing code.")
		return
	}

	db.Instance.Exec("UPDATE users SET telegram_chat_id = $1, tg_auth_code = NULL, tg_auth_code_exp = NULL WHERE email = $2", chatID, email)

	sendMessage(chatID, fmt.Sprintf("✅ Welcome! Successfully linked to your ILM AI account: %s", email))
	sendMainMenu(chatID, email)
}

func handleCallback(cb *tgbotapi.CallbackQuery) {
	chatID := cb.Message.Chat.ID
	data := cb.Data

	switch data {
	case "action_quiz":
		var goal string
		err := db.Instance.QueryRow("SELECT COALESCE(learning_goal, '') FROM users WHERE telegram_chat_id = $1", chatID).Scan(&goal)
		if err != nil || goal == "" {
			Bot.Send(tgbotapi.NewMessage(chatID, "You haven't set a learning goal yet. Open the Web App to set your goals!"))
			return
		}

		questionText := fmt.Sprintf("Quick Quiz regarding your goal: '%s'\n\nWhat is the primary benefit of Retrieval-Augmented Generation (RAG)?", goal)

		msg := tgbotapi.NewMessage(chatID, questionText)
		keyboard := tgbotapi.NewInlineKeyboardMarkup(
			tgbotapi.NewInlineKeyboardRow(
				tgbotapi.NewInlineKeyboardButtonData("A) Faster code compilation", "ans_wrong"),
			),
			tgbotapi.NewInlineKeyboardRow(
				tgbotapi.NewInlineKeyboardButtonData("B) Grounding AI responses to reduce hallucinations", "ans_correct"),
			),
			tgbotapi.NewInlineKeyboardRow(
				tgbotapi.NewInlineKeyboardButtonData("C) Generating images from text", "ans_wrong"),
			),
		)
		msg.ReplyMarkup = keyboard
		Bot.Send(msg)

	case "action_plan":
		Bot.Send(tgbotapi.NewMessage(chatID, "Your daily plan requires deep focus. Please launch the Web App to view your full interactive plan and materials."))

	case "ans_correct":
		Bot.Send(tgbotapi.NewEditMessageText(chatID, cb.Message.MessageID, "✅ Correct!\n\nRAG grounds the AI model by retrieving facts from your documents, significantly reducing hallucinations."))

	case "ans_wrong":
		Bot.Send(tgbotapi.NewEditMessageText(chatID, cb.Message.MessageID, "❌ Incorrect.\n\nThe correct answer is B. RAG is primarily used to ground AI responses and reduce hallucinations based on your uploaded context."))

	case "action_disconnect":
		db.Instance.Exec("UPDATE users SET telegram_chat_id = 0 WHERE telegram_chat_id = $1", chatID)
		Bot.Send(tgbotapi.NewEditMessageText(chatID, cb.Message.MessageID, "🔌 Account disconnected successfully. You will no longer receive notifications here."))
		sendGuestMenu(chatID)
	}

	Bot.Request(tgbotapi.NewCallback(cb.ID, ""))
}

func sendGuestMenu(chatID int64) {
	msg := tgbotapi.NewMessage(chatID, "Welcome to ILM AI Bot!\n\nPlease open the Web App from your browser, go to Profile, and generate a 6-digit code to link your account.")
	keyboard := tgbotapi.NewInlineKeyboardMarkup(
		tgbotapi.NewInlineKeyboardRow(
			tgbotapi.NewInlineKeyboardButtonURL("🌐 Open Web App", webAppURL),
		),
	)
	msg.ReplyMarkup = keyboard
	Bot.Send(msg)
}

func sendMainMenu(chatID int64, email string) {
	msg := tgbotapi.NewMessage(chatID, fmt.Sprintf("Welcome back, %s!\n\nWhat would you like to do today?", email))

	keyboard := tgbotapi.NewInlineKeyboardMarkup(
		tgbotapi.NewInlineKeyboardRow(
			tgbotapi.NewInlineKeyboardButtonData("🧠 Quick Quiz", "action_quiz"),
			tgbotapi.NewInlineKeyboardButtonData("📅 My Plan", "action_plan"),
		),
		tgbotapi.NewInlineKeyboardRow(
			tgbotapi.NewInlineKeyboardButtonURL("🚀 Launch ILM AI", webAppURL),
		),
		tgbotapi.NewInlineKeyboardRow(
			tgbotapi.NewInlineKeyboardButtonData("🔌 Disconnect", "action_disconnect"),
		),
	)
	msg.ReplyMarkup = keyboard
	Bot.Send(msg)
}

func sendMessage(chatID int64, text string) {
	msg := tgbotapi.NewMessage(chatID, text)
	Bot.Send(msg)
}