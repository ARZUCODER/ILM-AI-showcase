package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"cloud.google.com/go/vertexai/genai"
	"golang.org/x/oauth2/google"
)

// httpClient is a shared client with a sane timeout so requests never hang forever.
var httpClient = &http.Client{Timeout: 60 * time.Second}

// embedBatchSize limits how many chunks we send per embedding request.
// Vertex text-embedding-004 caps at 250 instances AND ~20k tokens per call;
// 50 chunks (~900 chars each) stays comfortably within the token budget.
const embedBatchSize = 50

// maxRetries controls exponential-backoff retries for transient Vertex errors.
const maxRetries = 4

// isRetryable reports whether an HTTP status code is worth retrying.
func isRetryable(status int) bool {
	return status == http.StatusTooManyRequests || // 429
		status == http.StatusInternalServerError || // 500
		status == http.StatusBadGateway || // 502
		status == http.StatusServiceUnavailable || // 503
		status == http.StatusGatewayTimeout // 504
}

// doWithRetry executes an HTTP request builder with exponential backoff.
// The builder is re-invoked each attempt because request bodies are single-use.
func doWithRetry(ctx context.Context, build func() (*http.Request, error)) (*http.Response, error) {
	var lastErr error
	backoff := 500 * time.Millisecond
	for attempt := 0; attempt <= maxRetries; attempt++ {
		req, err := build()
		if err != nil {
			return nil, err
		}
		resp, err := httpClient.Do(req)
		if err != nil {
			lastErr = err
		} else if isRetryable(resp.StatusCode) {
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			lastErr = fmt.Errorf("retryable status %d: %s", resp.StatusCode, string(body))
		} else {
			return resp, nil
		}

		if attempt < maxRetries {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(backoff):
			}
			backoff *= 2 // exponential backoff
		}
	}
	return nil, fmt.Errorf("vertex request failed after %d retries: %w", maxRetries, lastErr)
}

type Client struct {
	client    *genai.Client
	projectID string
	location  string
}

func NewGeminiClient() *Client {
	ctx := context.Background()
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		projectID = "ilm-ai-app"
	}
	location := "us-central1"

	c, err := genai.NewClient(ctx, projectID, location)
	if err != nil {
		log.Printf("Vertex Client error: %v", err)
	}
	return &Client{
		client:    c,
		projectID: projectID,
		location:  location,
	}
}

type GenerateResult struct {
	Text string
}

func (c *Client) ProcessDocument(ctx context.Context, fileBytes []byte, prompt string) (*GenerateResult, error) {
	if c.client == nil {
		return nil, fmt.Errorf("client not initialized")
	}
	model := c.client.GenerativeModel("gemini-2.5-flash")
	model.SetTemperature(0.1)

	var reqParts []genai.Part
	if len(fileBytes) > 0 {
		reqParts = append(reqParts, genai.Blob{MIMEType: "application/pdf", Data: fileBytes})
	}
	reqParts = append(reqParts, genai.Text(prompt))

	// Retry transient failures with exponential backoff.
	var resp *genai.GenerateContentResponse
	var err error
	backoff := 500 * time.Millisecond
	for attempt := 0; attempt <= maxRetries; attempt++ {
		resp, err = model.GenerateContent(ctx, reqParts...)
		if err == nil {
			break
		}
		if attempt < maxRetries {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(backoff):
			}
			backoff *= 2
		}
	}
	if err != nil {
		return nil, fmt.Errorf("document processing failed after retries: %w", err)
	}

	result := &GenerateResult{}
	if len(resp.Candidates) > 0 && len(resp.Candidates[0].Content.Parts) > 0 {
		if txt, ok := resp.Candidates[0].Content.Parts[0].(genai.Text); ok {
			result.Text = string(txt)
		}
	}
	return result, nil
}

func (c *Client) getVertexEmbedding(ctx context.Context, text, taskType string) ([]float32, error) {
	ts, err := google.DefaultTokenSource(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, err
	}
	tok, err := ts.Token()
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/text-embedding-004:predict", c.location, c.projectID, c.location)

	reqBody := map[string]interface{}{
		"instances": []map[string]interface{}{
			{
				"task_type": taskType,
				"content":   text,
			},
		},
	}
	b, _ := json.Marshal(reqBody)

	resp, err := doWithRetry(ctx, func() (*http.Request, error) {
		req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(b))
		if err != nil {
			return nil, err
		}
		req.Header.Set("Authorization", "Bearer "+tok.AccessToken)
		req.Header.Set("Content-Type", "application/json")
		return req, nil
	})
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("embedding API error (%d): %s", resp.StatusCode, string(bodyBytes))
	}

	var resData struct {
		Predictions []struct {
			Embeddings struct {
				Values []float32 `json:"values"`
			} `json:"embeddings"`
		} `json:"predictions"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&resData); err != nil {
		return nil, err
	}

	if len(resData.Predictions) > 0 && len(resData.Predictions[0].Embeddings.Values) > 0 {
		return resData.Predictions[0].Embeddings.Values, nil
	}
	return nil, fmt.Errorf("no embedding")
}

// GenerateBatchEmbeddings embeds all chunks, automatically splitting into
// batches that respect Vertex's per-request limits, with retry on each batch.
func (c *Client) GenerateBatchEmbeddings(ctx context.Context, texts []string, taskType string) ([][]float32, error) {
	if len(texts) == 0 {
		return nil, nil
	}

	var allResults [][]float32
	for start := 0; start < len(texts); start += embedBatchSize {
		end := start + embedBatchSize
		if end > len(texts) {
			end = len(texts)
		}
		batch := texts[start:end]

		batchResults, err := c.embedBatch(ctx, batch, taskType)
		if err != nil {
			return nil, fmt.Errorf("batch %d-%d: %w", start, end, err)
		}
		allResults = append(allResults, batchResults...)
	}

	if len(allResults) != len(texts) {
		return nil, fmt.Errorf("mismatch: got %d, expected %d", len(allResults), len(texts))
	}
	return allResults, nil
}

// embedBatch sends a single (already size-limited) batch to Vertex.
func (c *Client) embedBatch(ctx context.Context, texts []string, taskType string) ([][]float32, error) {
	ts, err := google.DefaultTokenSource(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return nil, err
	}
	tok, err := ts.Token()
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1/projects/%s/locations/%s/publishers/google/models/text-embedding-004:predict", c.location, c.projectID, c.location)

	instances := make([]map[string]interface{}, len(texts))
	for i, t := range texts {
		instances[i] = map[string]interface{}{
			"task_type": taskType,
			"content":   t,
		}
	}

	b, _ := json.Marshal(map[string]interface{}{"instances": instances})

	resp, err := doWithRetry(ctx, func() (*http.Request, error) {
		req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(b))
		if err != nil {
			return nil, err
		}
		req.Header.Set("Authorization", "Bearer "+tok.AccessToken)
		req.Header.Set("Content-Type", "application/json")
		return req, nil
	})
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API error (%d): %s", resp.StatusCode, string(bodyBytes))
	}

	var resData struct {
		Predictions []struct {
			Embeddings struct {
				Values []float32 `json:"values"`
			} `json:"embeddings"`
		} `json:"predictions"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&resData); err != nil {
		return nil, err
	}

	var results [][]float32
	for _, pred := range resData.Predictions {
		results = append(results, pred.Embeddings.Values)
	}

	if len(results) != len(texts) {
		return nil, fmt.Errorf("batch mismatch: got %d, expected %d", len(results), len(texts))
	}
	return results, nil
}

func (c *Client) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	return c.getVertexEmbedding(ctx, text, "RETRIEVAL_QUERY")
}

func (c *Client) GenerateDocumentEmbedding(ctx context.Context, text string) ([]float32, error) {
	return c.getVertexEmbedding(ctx, text, "RETRIEVAL_DOCUMENT")
}