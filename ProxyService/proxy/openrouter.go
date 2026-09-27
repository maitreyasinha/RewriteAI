package proxy

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
)

const (
	defaultModel             = "openrouter/free"
	openRouterCompletionsURL = "https://openrouter.ai/api/v1/chat/completions"
	openRouterReferer        = "https://rewrite-ai-kappa.vercel.app"
	openRouterTitle          = "RewriteAI"
)

var (
	errMalformedResponse = errors.New("malformed response from model")
)

// OpenRouterRequest represents the chat completions payload sent to OpenRouter.
type OpenRouterRequest struct {
	Model    string              `json:"model"`
	Messages []OpenRouterMessage `json:"messages"`
}

// OpenRouterMessage represents a single message in the chat conversation.
type OpenRouterMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// OpenRouterResponse represents the JSON response structure from OpenRouter.
type OpenRouterResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Usage struct {
		TotalTokens int64 `json:"total_tokens"`
	} `json:"usage"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// UpstreamError captures non-200 responses from OpenRouter so they can be relayed.
type UpstreamError struct {
	StatusCode int
	Body       []byte
}

func (e *UpstreamError) Error() string {
	return fmt.Sprintf("upstream returned status %d: %s", e.StatusCode, string(e.Body))
}

// buildSystemPrompt constructs the rewrite system instruction, tailoring tone if provided.
func buildSystemPrompt(tone string) string {
	if tone != "" {
		return fmt.Sprintf("Rewrite the following text with a %s tone. Maintain the source language. Output only the rewritten text.", tone)
	}
	return "Rewrite the following text clearly, concisely, and naturally. Maintain the source language. Output only the rewritten text."
}

// estimateTokens falls back to estimating ~4 characters per token if upstream usage is 0.
func estimateTokens(prompt, rewritten string) int64 {
	return int64((len(prompt) + len(rewritten)) / 4)
}

// callOpenRouter sends the completion request to OpenRouter and returns the parsed response.
func callOpenRouter(ctx context.Context, model, prompt, tone string) (*ClientResponse, error) {
	openRouterKey := strings.TrimSpace(os.Getenv("OPENROUTER_API_KEY"))
	if openRouterKey == "" {
		return nil, errors.New("OPENROUTER_API_KEY environment variable is not configured on Vercel")
	}

	orBody := OpenRouterRequest{
		Model: model,
		Messages: []OpenRouterMessage{
			{Role: "system", Content: buildSystemPrompt(tone)},
			{Role: "user", Content: prompt},
		},
	}

	orData, err := json.Marshal(orBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, openRouterCompletionsURL, bytes.NewBuffer(orData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+openRouterKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("HTTP-Referer", openRouterReferer)
	req.Header.Set("X-Title", openRouterTitle)

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("upstream service unreachable: %w", err)
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, &UpstreamError{
			StatusCode: resp.StatusCode,
			Body:       respBytes,
		}
	}

	var orResponse OpenRouterResponse
	if err := json.Unmarshal(respBytes, &orResponse); err != nil || len(orResponse.Choices) == 0 {
		return nil, errMalformedResponse
	}

	rewrittenText := strings.TrimSpace(orResponse.Choices[0].Message.Content)
	tokensUsed := orResponse.Usage.TotalTokens
	if tokensUsed == 0 {
		tokensUsed = estimateTokens(prompt, rewrittenText)
	}

	return &ClientResponse{
		Rewritten:  rewrittenText,
		TokensUsed: tokensUsed,
		Model:      model,
	}, nil
}
