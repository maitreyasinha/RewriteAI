package proxy

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"
)

const (
	dailyTokenLimit    int64 = 40000
	redisKeyTTLSeconds       = 86400 // 24 hours in seconds
)

// dailyTokenKey generates the Redis key for tracking daily IP token usage.
func dailyTokenKey(clientIP string) string {
	today := time.Now().UTC().Format("2006-01-02")
	return fmt.Sprintf("tokens:%s:%s", clientIP, today)
}

// checkRateLimit returns true if the client IP has exceeded the daily token quota.
func checkRateLimit(ctx context.Context, clientIP string) (bool, error) {
	key := dailyTokenKey(clientIP)
	valStr, err := executeUpstash(ctx, "GET", key)
	if err != nil || valStr == "" {
		return false, err
	}

	usedTokens, err := strconv.ParseInt(valStr, 10, 64)
	if err != nil {
		return false, err
	}

	return usedTokens >= dailyTokenLimit, nil
}

// recordTokenUsage increments token count and resets TTL to 24h.
func recordTokenUsage(ctx context.Context, clientIP string, tokens int64) {
	key := dailyTokenKey(clientIP)
	_, _ = executeUpstash(ctx, "INCRBY", key, tokens)
	_, _ = executeUpstash(ctx, "EXPIRE", key, redisKeyTTLSeconds)
}

// ExecuteUpstash runs a single command against the Upstash REST endpoint (uses background context).
func ExecuteUpstash(args ...any) (string, error) {
	return executeUpstash(context.Background(), args...)
}

func executeUpstash(ctx context.Context, args ...any) (string, error) {
	baseURL := os.Getenv("UPSTASH_REDIS_REST_URL")
	token := os.Getenv("UPSTASH_REDIS_REST_TOKEN")
	if baseURL == "" || token == "" {
		return "", fmt.Errorf("upstash environment variables not configured")
	}

	body, err := json.Marshal(args)
	if err != nil {
		return "", fmt.Errorf("failed to marshal upstash args: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, baseURL, bytes.NewBuffer(body))
	if err != nil {
		return "", fmt.Errorf("failed to create upstash request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("upstash request failed: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Result any    `json:"result"`
		Error  string `json:"error"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode upstash response: %w", err)
	}
	if result.Error != "" {
		return "", fmt.Errorf("upstash: %s", result.Error)
	}
	if result.Result == nil {
		return "", nil
	}

	return fmt.Sprintf("%v", result.Result), nil
}
