//
//  GeminiService.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Foundation

// MARK: - Response Data Models

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    struct Candidate: Decodable {
        let content: Content
        struct Content: Decodable {
            let parts: [Part]
            struct Part: Decodable { let text: String }
        }
    }
}

private struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetails
    struct GeminiErrorDetails: Decodable {
        let message: String
    }
}

// MARK: - Gemini AIService Implementation

/// Implementation of AIService protocol for Google Gemini REST API
class GeminiService: AIService {
    
    let providerName = "Google Gemini"
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "gemini_api_key")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"

    func rewrite(_ text: String, style: Style) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey(providerName: providerName)
        }
        
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            throw AIError.requestFailed(message: "Invalid Gemini endpoint URL.")
        }
        
        let promptText = "\(style.promptInstruction) Return ONLY the final rewritten text without quote marks or introductory remarks: \(text)"
        
        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": promptText]]
            ]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw AIError.requestFailed(message: errorResponse.error.message)
            }
            throw AIError.requestFailed(message: "Gemini server error (Status \(httpResponse.statusCode)).")
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let rewrittenText = decoded.candidates?.first?.content.parts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AIError.requestFailed(message: "Gemini returned empty response.")
        }
        
        return rewrittenText
    }
}
