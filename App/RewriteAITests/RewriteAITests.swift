//
//  RewriteAITests.swift
//  RewriteAITests
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Testing
import Foundation
@testable import RewriteAI

struct RewriteAITests {

    @Test func testMissingGeminiAPIKeyThrowsError() async throws {
        // Clear any stored key for testing
        let key = UserDefaults.standard.string(forKey: "gemini_api_key")
        UserDefaults.standard.removeObject(forKey: "gemini_api_key")
        defer {
            if let key { UserDefaults.standard.set(key, forKey: "gemini_api_key") }
        }
        
        let service = GeminiService()
        
        await #expect(throws: AIError.self) {
            _ = try await service.rewrite("Test text", style: .professional)
        }
    }
    
    @Test func testStyleInstructions() {
        #expect(Style.professional.promptInstruction.contains("professional"))
        #expect(Style.funny.promptInstruction.contains("humorous"))
        #expect(Style.summarize.promptInstruction.contains("Summarize"))
    }
    
    @Test func testMockAIServiceRewrite() async throws {
        let mockService = MockAIService()
        let result = try await mockService.rewrite("Hello World", style: .funny)
        #expect(result.contains("Funny"))
        #expect(result.contains("Hello World"))
    }
    
    @Test func testAIManagerServiceFactoryDefaultsToGemini() {
        let manager = AIManager()
        let service = manager.service(for: .gemini)
        #expect(service.providerName == "Google Gemini")
    }
    
    @Test @MainActor func testAIManagerCopyToClipboardAndClear() {
        let manager = AIManager()
        manager.inputText = "Original Input"
        manager.rewrittenText = "Rewritten Result"
        
        manager.copyToClipboard()
        #expect(manager.isCopied == true)
        
        manager.clearAll()
        #expect(manager.inputText.isEmpty)
        #expect(manager.rewrittenText.isEmpty)
        #expect(manager.selectedStyle == nil)
    }
}
