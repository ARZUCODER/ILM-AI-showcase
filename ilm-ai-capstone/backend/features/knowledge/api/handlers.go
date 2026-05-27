package api

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/pgvector/pgvector-go"
	"ilm_ai_backend/core/ai"
	"ilm_ai_backend/core/auth"
	"ilm_ai_backend/core/db"
	"ilm_ai_backend/core/quota"
)

type RetrieveRequest struct {
	Query string `json:"query" binding:"required"`
	Limit int    `json:"limit"`
}

func chunkText(text string, targetSize int) []string {
	var chunks []string
	runes := []rune(text)

	for i := 0; i < len(runes); i += targetSize {
		end := i + targetSize
		if end > len(runes) {
			end = len(runes)
		}

		s := strings.TrimSpace(string(runes[i:end]))
		if len([]rune(s)) >= 30 {
			chunks = append(chunks, s)
		}
	}
	return chunks
}

func handleFileUpload(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	// Check file upload quota
	canUpload, maxFiles, err := quota.CheckFileQuota(userEmail)
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "DATABASE_ERROR",
			Message: "Failed to check quota",
		})
		return
	}

	if !canUpload {
		c.JSON(http.StatusForbidden, auth.ErrorResponse{
			Code:    "FILE_QUOTA_EXCEEDED",
			Message: "You have reached your file upload limit",
			Details: map[string]interface{}{
				"max_files": maxFiles,
				"upgrade_message": "Upgrade to Premium for unlimited file uploads",
			},
		})
		return
	}

	file, err := c.FormFile("document")
	if err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "File not found",
		})
		return
	}

	f, err := file.Open()
	if err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Could not open file",
		})
		return
	}
	defer f.Close()
	fileBytes, err := io.ReadAll(f)
	if err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Could not read file",
		})
		return
	}

	geminiClient := ai.NewGeminiClient()
	ctx := context.Background()

	ext := strings.ToLower(filepath.Ext(file.Filename))
	var extractedText string
	if ext == ".txt" || ext == ".md" {
		extractedText = string(fileBytes)
	} else {
		res, err := geminiClient.ProcessDocument(ctx, fileBytes, "Extract ALL the textual content from this document. Output only the raw text.")
		if err == nil && res != nil {
			extractedText = res.Text
		}
	}

	if strings.TrimSpace(extractedText) == "" {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Could not extract text from document",
		})
		return
	}

	var fileID int64
	db.Instance.QueryRow(
		"INSERT INTO source_files (user_email, filename, char_count) VALUES ($1,$2,$3) RETURNING id",
		userEmail, file.Filename, len(extractedText),
	).Scan(&fileID)

	chunks := chunkText(extractedText, 900)

	// DIQQAT: BARCHA CHUNKLARNI BITTA SO'ROVDA BATCH EMBEDDING QILAMIZ!
	embeddings, err := geminiClient.GenerateBatchEmbeddings(ctx, chunks, "RETRIEVAL_DOCUMENT")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "AI xatosi: " + err.Error()})
		return
	}

	inserted := 0
	for i, chunkContent := range chunks {
		_, err = db.Instance.Exec(
			"INSERT INTO knowledge_chunks (user_email, source_file_id, content, embedding) VALUES ($1,$2,$3,$4)",
			userEmail, fileID, chunkContent, pgvector.NewVector(embeddings[i]),
		)
		if err == nil {
			inserted++
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      fmt.Sprintf("Saved: %d chunks", inserted),
		"filename":     file.Filename,
		"chunks_saved": inserted,
	})
}

func handleListFiles(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	rows, _ := db.Instance.Query(
		"SELECT f.id, f.filename, f.char_count, f.created_at, COUNT(c.id) FROM source_files f LEFT JOIN knowledge_chunks c ON c.source_file_id = f.id WHERE f.user_email=$1 GROUP BY f.id ORDER BY f.id DESC",
		userEmail,
	)
	var files []gin.H
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var id, chars, chunks int64
			var name, createdAt string
			rows.Scan(&id, &name, &chars, &createdAt, &chunks)
			files = append(files, gin.H{
				"id": id, "filename": name, "char_count": chars,
				"chunk_count": chunks, "created_at": createdAt,
			})
		}
	}
	c.JSON(http.StatusOK, gin.H{"files": files})
}

func handleDeleteFile(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	id := c.Param("id")
	db.Instance.Exec("DELETE FROM knowledge_chunks WHERE source_file_id=$1 AND user_email=$2", id, userEmail)
	db.Instance.Exec("DELETE FROM source_files WHERE id=$1 AND user_email=$2", id, userEmail)
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func handleRetrieve(c *gin.Context) {
	userEmail := auth.ExtractUserEmail(c)
	if userEmail == "" {
		c.JSON(http.StatusUnauthorized, auth.ErrorResponse{
			Code:    "UNAUTHORIZED",
			Message: "User not authenticated",
		})
		return
	}

	var req RetrieveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, auth.ErrorResponse{
			Code:    "INVALID_REQUEST",
			Message: "Invalid request payload",
		})
		return
	}
	if req.Limit <= 0 {
		req.Limit = 5
	}

	geminiClient := ai.NewGeminiClient()
	emb, err := geminiClient.GenerateEmbedding(context.Background(), req.Query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, auth.ErrorResponse{
			Code:    "AI_ERROR",
			Message: "Failed to generate embedding",
		})
		return
	}

	rows, _ := db.Instance.Query(`
		SELECT c.id, COALESCE(f.filename,'document'), c.content, (c.embedding <=> $2)::float8 AS distance
		FROM knowledge_chunks c
		LEFT JOIN source_files f ON f.id = c.source_file_id
		WHERE c.user_email=$1
		ORDER BY c.embedding <=> $2
		LIMIT $3`,
		userEmail, pgvector.NewVector(emb), req.Limit,
	)

	var chunks []gin.H
	if rows != nil {
		defer rows.Close()
		for rows.Next() {
			var id int64
			var fname, content string
			var dist float64
			rows.Scan(&id, &fname, &content, &dist)

			// RAG threshold: cosine distance <= 0.6 (>= 40% similarity).
			// 0.40 was too strict and dropped genuinely relevant passages,
			// leaving the model with no context. 0.6 keeps relevant matches
			// while still filtering out clear noise.
			if dist <= 0.6 {
				chunks = append(chunks, gin.H{
					"id":         id,
					"filename":   fname,
					"content":    content,
					"distance":   dist,
					"similarity": 1.0 - dist,
				})
			}
		}
	}
	c.JSON(http.StatusOK, gin.H{"chunks": chunks})
}