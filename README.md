<div align="center">
  <img src="https://raw.githubusercontent.com/ARZUCODER/ILM-AI-showcase/main/screenshots/icon.png" width="120" />
  <h1>ILM AI - Full-Stack AI Learning Companion</h1>
  <p>
    <strong>From Idea to Production in 4 Weeks</strong><br/>
    Final Capstone Project for the AI Incubator Mentorship Program.
  </p>

  [![Live Demo](https://img.shields.io/badge/Live_Demo-Web_App-brightgreen?style=for-the-badge&logo=flutter)](https://ilmai.arzucoder.uz/)
  [![Google Play](https://img.shields.io/badge/Google_Play-Download-blue?style=for-the-badge&logo=google-play)](https://play.google.com/store/apps/details?id=com.arzucoder.ilm_ai)
  [![Telegram](https://img.shields.io/badge/Telegram-Bot-blue?style=for-the-badge&logo=telegram)](https://t.me/ILM_AIBOT)
  [![Portfolio](https://img.shields.io/badge/Built_by-ARZUCODER-purple?style=for-the-badge)](https://arzucoder.uz)

</div>

<p align="center">
  <img src="https://raw.githubusercontent.com/ARZUCODER/ILM-AI-showcase/main/screenshots/1.png" width="23%">
  <img src="https://raw.githubusercontent.com/ARZUCODER/ILM-AI-showcase/main/screenshots/2.png" width="23%">
  <img src="https://raw.githubusercontent.com/ARZUCODER/ILM-AI-showcase/main/screenshots/3.png" width="23%">
  <img src="https://raw.githubusercontent.com/ARZUCODER/ILM-AI-showcase/main/screenshots/4.png" width="23%">
</p>

---

## 🚀 Key Features

-   **RAG Chat:** Conversational AI grounded in user-provided documents to prevent hallucinations.
-   **AI Flashcards:** Generate interactive quizzes based on uploaded materials.
-   **Personalized Study Plans:** AI agent creates day-by-day study schedules based on user goals.
-   **Advanced Telegram Bot:** Link your account via a secure 6-digit OTP & Deep Links, get reminders, and launch the **Telegram Mini App**.
-   **Admin Observability Panel:** Custom-built dashboard to monitor RAG traces, token usage, and live chats.
-   **Monetization Engine:** Free & Premium tiers with quotas, powered by local payment providers (Click/Payme) and a dynamic promocode system.

---

## 🛠️ Architecture & Tech Stack

The project follows a modern Full-Stack architecture with a clean separation of concerns.

-   **`ilm-ai-capstone/frontend/` (Flutter):**
    -   **Framework:** Flutter (for Web, Android)
    -   **State Management:** Riverpod
    -   **Design:** Custom "Liquid Glass" UI with animations.
    -   **AI Generation:** Uses `firebase_vertexai` to directly call Gemini, reducing backend load and enabling real-time streaming.

-   **`ilm-ai-capstone/backend/` (Golang):**
    -   **Framework:** Gin (for a high-performance REST API)
    -   **Database:** PostgreSQL + `pgvector` for storing both relational data and vector embeddings.
    -   **AI Retrieval & Cost Optimization:** Uses `cloud.google.com/go/vertexai` to generate embeddings (`text-embedding-004`) and perform semantic search. This architecture allows leveraging **Google Cloud Startup Credits** to run the AI engine practically for free.
    -   **Telegram Bot:** Embedded directly into the Go backend as a **Goroutine** to save server resources and share the same DB connection.

-   **Deployment & Infrastructure:**
    -   **Cloud:** DigitalOcean Droplet
    -   **Containerization:** Docker & Docker Compose
    -   **Web Server:** Nginx with SSL from Let's Encrypt
    -   **CI/CD:** Custom shell script for one-command, zero-downtime deployment from a local machine.

---

## ⚙️ How to Run Locally

### Prerequisites
-   Docker & Docker Compose
-   Flutter SDK
-   Golang

### Backend Setup
1.  Navigate to the `ilm-ai-capstone/backend/` directory.
2.  Create a `.env` file and a `service-account.json` file.
3.  Run `go mod tidy` to install dependencies.
4.  Run `docker-compose up --build`. The backend will be available at `http://localhost:8080`.

### Frontend Setup
1.  Navigate to the `ilm-ai-capstone/frontend/` directory.
2.  Create a `.env` file with `API_BASE_URL=http://localhost:8080/api/v1`.
3.  Run `flutter pub get`.
4.  Run `flutter run -d chrome`.

---

## 📝 Development Diary
This repository also contains my full development log for the mentorship program. You can read my process, struggles, and solutions in the [**diary/**](./diary/) folder. This documents my journey from Week 1 to Week 4, including weekly Loom video demos.

---
<div align="center">
  <small>Designed & Developed by <a href="https://arzucoder.uz">ARZUCODER</a></small>
</div>
