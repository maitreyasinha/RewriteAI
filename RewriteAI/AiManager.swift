//
//  AiManager.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI
import Observation

enum AIEngine {
    case gemini, gpt
}

@Observable
class AIManager {
    var status: String = "Ready"
    var isProcessing = false
        
    private let gemini = GeminiService()
    
    func process(engine: AIEngine) {
        let isAccessible = checkAccessibility()
        print("Accessibility result is  \(isAccessible)...")
        print("Triggering rewrite with \(engine)...")
//        var isProcessing = false
        
        guard let selectedText = TextService.shared.getSelectedText() else { return }
        
        isProcessing = true
//        print(selectedText)
        // 1. We will eventually 'Copy' the text here
        // 2. We will call the API
        // 3. We will 'Paste' the result
        
        // Let's test if it's working with a simple print
        Task {
            do {
                let rewrittenText = try await gemini.rewrite(selectedText)
                await MainActor.run {
                    TextService.shared.replaceSelectedText(with: rewrittenText)
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func callMockAPI(engine: AIEngine) {
        // This is where your API logic will live in Step 3
        let mockResult = "This is a polished version of your text."
        print("AI Result: \(mockResult)")
    }
}

func checkAccessibility() -> Bool {
    let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let status = AXIsProcessTrustedWithOptions(options as CFDictionary)
    print("Accessibility Status: \(status)")
    return status
}
