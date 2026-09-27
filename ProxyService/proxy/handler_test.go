package proxy

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestHandleCORS(t *testing.T) {
	// Test OPTIONS preflight
	req := httptest.NewRequest(http.MethodOptions, "/api/rewrite", nil)
	w := httptest.NewRecorder()

	handled := handleCORS(w, req)
	if !handled {
		t.Errorf("expected handleCORS to return true for OPTIONS")
	}
	if w.Code != http.StatusNoContent {
		t.Errorf("expected status %d, got %d", http.StatusNoContent, w.Code)
	}
	if origin := w.Header().Get("Access-Control-Allow-Origin"); origin != "*" {
		t.Errorf("expected Access-Control-Allow-Origin to be '*', got %q", origin)
	}

	// Test regular POST request
	reqPost := httptest.NewRequest(http.MethodPost, "/api/rewrite", nil)
	wPost := httptest.NewRecorder()

	handledPost := handleCORS(wPost, reqPost)
	if handledPost {
		t.Errorf("expected handleCORS to return false for POST")
	}
	if origin := wPost.Header().Get("Access-Control-Allow-Origin"); origin != "*" {
		t.Errorf("expected Access-Control-Allow-Origin to be set for POST")
	}
}

func TestExtractClientIP(t *testing.T) {
	tests := []struct {
		name       string
		xff        string
		remoteAddr string
		expectedIP string
	}{
		{
			name:       "X-Forwarded-For single IP",
			xff:        "198.51.100.1",
			remoteAddr: "10.0.0.1:1234",
			expectedIP: "198.51.100.1",
		},
		{
			name:       "X-Forwarded-For multiple IPs",
			xff:        "198.51.100.1, 10.0.0.2, 10.0.0.3",
			remoteAddr: "10.0.0.1:1234",
			expectedIP: "198.51.100.1",
		},
		{
			name:       "Fallback to RemoteAddr with port",
			xff:        "",
			remoteAddr: "192.168.1.100:54321",
			expectedIP: "192.168.1.100",
		},
		{
			name:       "RemoteAddr without port",
			xff:        "",
			remoteAddr: "192.168.1.100",
			expectedIP: "192.168.1.100",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/", nil)
			if tt.xff != "" {
				req.Header.Set("X-Forwarded-For", tt.xff)
			}
			req.RemoteAddr = tt.remoteAddr

			got := extractClientIP(req)
			if got != tt.expectedIP {
				t.Errorf("extractClientIP() = %q, want %q", got, tt.expectedIP)
			}
		})
	}
}

func TestBuildSystemPrompt(t *testing.T) {
	defaultPrompt := buildSystemPrompt("")
	if defaultPrompt != "Rewrite the following text clearly, concisely, and naturally. Maintain the source language. Output only the rewritten text." {
		t.Errorf("unexpected default system prompt: %s", defaultPrompt)
	}

	formalPrompt := buildSystemPrompt("formal")
	if formalPrompt != "Rewrite the following text with a formal tone. Maintain the source language. Output only the rewritten text." {
		t.Errorf("unexpected formal system prompt: %s", formalPrompt)
	}
}

func TestEstimateTokens(t *testing.T) {
	prompt := "Hello"
	rewritten := "World!"
	tokens := estimateTokens(prompt, rewritten)
	// (5 + 6) / 4 = 11 / 4 = 2
	if tokens != 2 {
		t.Errorf("estimateTokens() = %d, want 2", tokens)
	}
}

func TestHandler_MethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/api/rewrite", nil)
	w := httptest.NewRecorder()

	Handler(w, req)

	if w.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected 405 Method Not Allowed, got %d", w.Code)
	}
	if ctype := w.Header().Get("Content-Type"); ctype != "application/json" {
		t.Errorf("expected Content-Type application/json, got %q", ctype)
	}

	var resp map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response JSON: %v", err)
	}
	if resp["error"] != "Method not allowed" {
		t.Errorf("unexpected error message: %q", resp["error"])
	}
}

func TestHandler_InvalidPayload(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/api/rewrite", bytes.NewBufferString("{}"))
	w := httptest.NewRecorder()

	Handler(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 Bad Request, got %d", w.Code)
	}

	var resp map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response JSON: %v", err)
	}
	if resp["error"] != "Invalid request. 'prompt' is required." {
		t.Errorf("unexpected error message: %q", resp["error"])
	}
}

func TestHandler_SuccessWithMock(t *testing.T) {
	originalTransport := client.Transport
	client.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		resp := OpenRouterResponse{
			Choices: []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			}{
				{
					Message: struct {
						Content string `json:"content"`
					}{
						Content: "Rewritten mock text",
					},
				},
			},
		}
		resp.Usage.TotalTokens = 42

		body, _ := json.Marshal(resp)
		return &http.Response{
			StatusCode: http.StatusOK,
			Body:       io.NopCloser(bytes.NewReader(body)),
			Header:     make(http.Header),
		}, nil
	})
	defer func() {
		client.Transport = originalTransport
	}()

	os.Setenv("OPENROUTER_API_KEY", "test-key")
	defer os.Unsetenv("OPENROUTER_API_KEY")

	reqBody := `{"prompt":"Please make this sound better"}`
	req := httptest.NewRequest(http.MethodPost, "/api/rewrite", bytes.NewBufferString(reqBody))
	w := httptest.NewRecorder()

	Handler(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d: %s", w.Code, w.Body.String())
	}

	var clientResp ClientResponse
	if err := json.Unmarshal(w.Body.Bytes(), &clientResp); err != nil {
		t.Fatalf("failed to decode client response: %v", err)
	}

	if clientResp.Rewritten != "Rewritten mock text" {
		t.Errorf("unexpected rewritten text: %q", clientResp.Rewritten)
	}
	if clientResp.TokensUsed != 42 {
		t.Errorf("unexpected tokens used: %d", clientResp.TokensUsed)
	}
	if clientResp.Model != defaultModel {
		t.Errorf("unexpected model: %q", clientResp.Model)
	}
}

func TestHandler_UpstreamErrorPassThrough(t *testing.T) {
	originalTransport := client.Transport
	client.Transport = roundTripFunc(func(r *http.Request) (*http.Response, error) {
		return &http.Response{
			StatusCode: http.StatusUnauthorized,
			Body:       io.NopCloser(bytes.NewReader([]byte(`{"error":{"message":"Invalid API Key"}}`))),
			Header:     make(http.Header),
		}, nil
	})
	defer func() {
		client.Transport = originalTransport
	}()

	os.Setenv("OPENROUTER_API_KEY", "invalid-key")
	defer os.Unsetenv("OPENROUTER_API_KEY")

	reqBody := `{"prompt":"Test prompt"}`
	req := httptest.NewRequest(http.MethodPost, "/api/rewrite", bytes.NewBufferString(reqBody))
	w := httptest.NewRecorder()

	Handler(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d: %s", w.Code, w.Body.String())
	}
}

type roundTripFunc func(req *http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
