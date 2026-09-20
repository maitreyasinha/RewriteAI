//
//  MockAIService.swift
//  RewriteAI
//
//  Created by Antigravity on 20/09/2026.
//

import Foundation

/// Mock implementation of AIService for unit tests and local UI previews without API calls
class MockAIService: AIService {
    
    let providerName = "Mock Engine"
    
    func rewrite(_ text: String, style: Style) async throws -> String {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 300_000_000)
        return "[\(style.rawValue) Mock]: \(text)"
    }
}
