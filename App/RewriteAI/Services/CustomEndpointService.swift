//
//  CustomEndpointService.swift
//  RewriteAI
//
//  Created by Antigravity on 29/09/2026.
//

import Foundation

// MARK: - Response Data Models

private struct CustomEndpointResponse: Decodable, CustomStringConvertible {
    let rewritten: String
    let tokensUsed: Int?
    let model: String?
    
    enum CodingKeys: String, CodingKey {
        case rewritten
        case tokensUsed = "tokens_used"
        case model
    }
    
    var description: String {
        "CustomEndpointResponse(rewritten: \"\(rewritten)\", tokensUsed: \(tokensUsed?.description ?? "nil"), model: \"\(model ?? "")\")"
    }
}

private struct CustomEndpointErrorResponse: Decodable {
    let error: String
}

// MARK: - Custom Endpoint AIService Implementation

/// Implementation of AIService protocol for custom hosted endpoint at https://rewrite-ai-kappa.vercel.app/api
class CustomEndpointService: AIService {
    
    let providerName = "Custom Endpoint"
    
    private let endpoint = "https://rewrite-ai-kappa.vercel.app/api"
    private let model = "openrouter/free"
    
    func rewrite(_ text: String, style: Style) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw AIError.requestFailed(message: "Invalid custom endpoint URL.")
        }
        
        let tone: String
        switch style {
        case .professional:
            tone = "professional"
        case .funny:
            tone = "funny"
        case .summarize:
            tone = "summarize"
        }
        
        let body: [String: Any] = [
            "prompt": text,
            "tone": tone,
            "model": model
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = try JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted])
        request.httpBody = requestData
        
        if let requestString = String(data: requestData, encoding: .utf8) {
            print("[CustomEndpointService] Decoded Request:\n\(requestString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("[CustomEndpointService] Raw Response:\n\(responseString)")
        }
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(CustomEndpointErrorResponse.self, from: data) {
                print("[CustomEndpointService] Decoded Error Response: \(errorResponse.error)")
                throw AIError.requestFailed(message: errorResponse.error)
            }
            throw AIError.requestFailed(message: "Custom endpoint server error (Status \(httpResponse.statusCode)).")
        }
        
        if let errorResponse = try? JSONDecoder().decode(CustomEndpointErrorResponse.self, from: data), !errorResponse.error.isEmpty {
            print("[CustomEndpointService] Decoded Error Response: \(errorResponse.error)")
            throw AIError.requestFailed(message: errorResponse.error)
        }
        
        let decoded = try JSONDecoder().decode(CustomEndpointResponse.self, from: data)
        print("[CustomEndpointService] Decoded Response:\n\(decoded)")
        
        let rewrittenText = decoded.rewritten.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !rewrittenText.isEmpty else {
            throw AIError.requestFailed(message: "Custom endpoint returned empty response.")
        }
        
        return rewrittenText
    }
}
