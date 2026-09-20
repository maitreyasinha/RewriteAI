//
//  OpenAIService.swift
//  RewriteAI
//
//  Created by Antigravity on 20/09/2026.
//

import Foundation

// MARK: - Response Data Models

private struct OpenAIResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable {
        let message: Message
        struct Message: Decodable {
            let content: String
        }
    }
}

private struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorDetails
    struct OpenAIErrorDetails: Decodable {
        let message: String
    }
}

// MARK: - OpenAI AIService Implementation

/// Implementation of AIService protocol for OpenAI REST API (GPT-4o)
class OpenAIService: AIService {
    
    let providerName = "OpenAI (GPT-4o)"
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openai_api_key")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    func rewrite(_ text: String, style: Style) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey(providerName: providerName)
        }
        
        guard let url = URL(string: endpoint) else {
            throw AIError.requestFailed(message: "Invalid OpenAI endpoint URL.")
        }
        
        let messages: [[String: String]] = [
            [
                "role": "system",
                "content": "You are a text rewriting assistant. Return ONLY the rewritten text without quotes, commentary, or formatting wrapper."
            ],
            [
                "role": "user",
                "content": "\(style.promptInstruction) Text: \(text)"
            ]
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw AIError.requestFailed(message: errorResponse.error.message)
            }
            throw AIError.requestFailed(message: "OpenAI server error (Status \(httpResponse.statusCode)).")
        }

        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let rewrittenText = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AIError.requestFailed(message: "OpenAI returned empty response.")
        }
        
        return rewrittenText
    }
}
