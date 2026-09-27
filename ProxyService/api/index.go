package handler

import (
	"net/http"

	"gemini-rewrite-proxy/proxy"
)

// Handler is the Vercel Serverless Function entrypoint.
func Handler(w http.ResponseWriter, r *http.Request) {
	proxy.Handler(w, r)
}
