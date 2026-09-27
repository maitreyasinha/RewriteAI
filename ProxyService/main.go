package main

import (
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"gemini-rewrite-proxy/proxy"
)

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

func debugLoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		lrw := &loggingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		log.Printf("[DEBUG] --> %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		next.ServeHTTP(lrw, r)
		log.Printf("[DEBUG] <-- %s %s [%d] in %v", r.Method, r.URL.Path, lrw.statusCode, time.Since(start))
	})
}

// loadEnv loads KEY=VALUE pairs from a file without external dependencies.
func loadEnv(filename string) {
	content, err := os.ReadFile(filename)
	if err != nil {
		return
	}

	for _, line := range strings.Split(string(content), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		key, val, found := strings.Cut(line, "=")
		if !found {
			continue
		}

		key = strings.TrimSpace(key)
		val = strings.TrimSpace(val)
		val = strings.Trim(val, `"'`)

		if os.Getenv(key) == "" {
			_ = os.Setenv(key, val)
		}
	}
}

func main() {
	loadEnv(".env")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	debug := os.Getenv("DEBUG") == "true" || os.Getenv("DEBUG") == "1"

	mux := http.NewServeMux()
	mux.HandleFunc("/api/rewrite", proxy.Handler)
	mux.HandleFunc("/", proxy.Handler)

	var rootHandler http.Handler = mux
	if debug {
		log.Println("[DEBUG] Debug mode enabled: verbose request/response logging active")
		rootHandler = debugLoggingMiddleware(mux)
	}

	log.Printf("Rewrite proxy service listening on :%s (DEBUG=%t)", port, debug)
	if err := http.ListenAndServe(":"+port, rootHandler); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
