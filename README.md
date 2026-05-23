# ILM AI - Personal AI Learning Companion

**Builder:** [ARZUCODER]  
**Project for:** AI Incubator Mentorship Program (Option A)

## Live Demos
- 🌍 **Web App:** [ilmai.arzucoder.uz](http://ilmai.arzucoder.uz/)
- 📱 **Google Play:** [ILM AI on Play Store](https://play.google.com/store/apps/details?id=com.arzucoder.ilm_ai)
- 📊 **Pitch Deck:** [Presentation Link](http://ilmai.arzucoder.uz/)

## Project Overview
Ilm AI is a smart learning companion. Instead of generic courses, users upload their own materials (PDFs, notes, books). Ilm AI chunks, embeds, and stores them securely. It then acts as a tutor, answering questions with exact citations, generating flashcards, and building personalized day-by-day study plans without hallucinating.

### Milestones Completed
- **Week 1 (Foundation):** Firebase Auth, Go Backend, Gemini text-embedding-004 to pgvector, RAG pipeline with strict system prompts for grounding.
- **Week 2 (Core Features):** RAG Chat with dynamic UI, AI Flashcard generation (Quiz Mode), Personalized Study Plan Generation via Gemini 2.5 Flash json-responses. *(Note: Telegram bot was skipped in favor of a deeper focus on the Mobile App, Web App, and Admin Observability Panel).*
- **Week 3 (Polish & Integrate):** Premium Tier integration (Click & Payme ready), dynamic Promocodes system, beautiful "Liquid Glass" Flutter UI with multi-language support (UZ, RU, EN).
- **Week 4 (Ship It):** Deployed backend to Cloud via Docker, frontend to Google Play and Web. Built a custom Admin Dashboard for RAG Tracing and Token monitoring.

## Architecture
- **Frontend:** Flutter + Riverpod (Deployed to Web and Android)
- **Backend:** Golang (Gin)
- **Database:** PostgreSQL + `pgvector`
- **AI / LLM:** Google Vertex AI (Gemini 2.5 Flash for generation, text-embedding-004 for vectors)
- **Storage/Auth:** Firebase

## Development Diary
Read my process, struggles, and solutions in the [diary/](./diary) folder.
