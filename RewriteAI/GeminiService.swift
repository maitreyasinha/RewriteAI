//
//  GeminiService.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Foundation

struct GeminiResponse: Decodable {
    let candidates: [Candidate]
    struct Candidate: Decodable {
        let content: Content
        struct Content: Decodable {
            let parts: [Part]
            struct Part: Decodable { let text: String }
        }
    }
}
class GeminiService {
    // In a real app, you'd pull this from a Secure .plist or Environment Variable
    private let apiKey = "API_KEY"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"
    
        func rewrite(_ text: String) async throws -> String {
            guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {throw URLError(.badURL)}
            let body: [String: Any] = [
                "contents": [[
                    "parts": [["text": "Rewrite the following text to be more professional and clear. Return ONLY the rewritten text: \(text)"]]
                ]]
            ]
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Status Code = \(httpResponse.statusCode)")
                // 2. If it's NOT 200, print the raw data from Google
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("DEBUG: API Error Body: \(errorString)")
                    }
                    throw URLError(.badServerResponse)
                }
            }

            let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return result.candidates.first?.content.parts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error: No text returned"
    }
}
