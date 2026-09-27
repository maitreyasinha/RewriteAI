package proxy

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

const httpTimeout = 45 * time.Second

// Shared HTTP client configured with connection pooling
var client = &http.Client{
	Timeout: httpTimeout,
	Transport: &http.Transport{
		MaxIdleConns:        50,
		MaxIdleConnsPerHost: 10,
		IdleConnTimeout:     90 * time.Second,
	},
}

// RequestPayload represents the incoming request schema from the client.
type RequestPayload struct {
	Prompt string `json:"prompt"`
	Model  string `json:"model"`
	Tone   string `json:"tone"`
}

// ClientResponse represents the response returned to the client.
type ClientResponse struct {
	Rewritten  string `json:"rewritten"`
	TokensUsed int64  `json:"tokens_used"`
	Model      string `json:"model"`
}

func isDebug() bool {
	return os.Getenv("DEBUG") == "true" || os.Getenv("DEBUG") == "1"
}

// Handler is the Vercel entrypoint for rewriting text prompts.
func Handler(w http.ResponseWriter, r *http.Request) {
	// 1. CORS headers & preflight
	if handleCORS(w, r) {
		return
	}

	if r.Method != http.MethodPost {
		writeJSONError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	// 2. Identify client IP
	clientIP := extractClientIP(r)

	// 3. Rate limit check (Daily bucket per IP, fail-open on Redis errors)
	if quotaExceeded, err := checkRateLimit(r.Context(), clientIP); err == nil && quotaExceeded {
		if isDebug() {
			log.Printf("[DEBUG] Rate limit quota exceeded for IP: %s", clientIP)
		}
		writeJSONError(w, http.StatusTooManyRequests, "Daily token quota exceeded for this IP. Try again tomorrow.")
		return
	}

	// 4. Parse incoming payload
	var payload RequestPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || strings.TrimSpace(payload.Prompt) == "" {
		writeJSONError(w, http.StatusBadRequest, "Invalid request. 'prompt' is required.")
		return
	}

	selectedModel := payload.Model
	if selectedModel == "" {
		selectedModel = defaultModel
	}

	if isDebug() {
		log.Printf("[DEBUG] Processing rewrite: ip=%s, model=%s, prompt_len=%d, tone=%s",
			clientIP, selectedModel, len(payload.Prompt), payload.Tone)
	}

	// 5. Query OpenRouter
	clientResp, err := callOpenRouter(r.Context(), selectedModel, payload.Prompt, payload.Tone)
	if err != nil {
		if isDebug() {
			log.Printf("[DEBUG] OpenRouter call failed: %v", err)
		}
		var upErr *UpstreamError
		if errors.As(err, &upErr) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(upErr.StatusCode)
			w.Write(upErr.Body)
			return
		}
		if errors.Is(err, errMalformedResponse) {
			writeJSONError(w, http.StatusBadGateway, "Malformed response from model")
			return
		}
		writeJSONError(w, http.StatusBadGateway, err.Error())
		return
	}

	if isDebug() {
		log.Printf("[DEBUG] Rewrite successful: tokens_used=%d, model=%s",
			clientResp.TokensUsed, clientResp.Model)
	}

	// 6. Record token consumption in Redis (best-effort)
	recordTokenUsage(r.Context(), clientIP, clientResp.TokensUsed)

	// 7. Return to caller
	writeJSON(w, http.StatusOK, clientResp)
}
