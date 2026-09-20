//
//  AiManager.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI
import Observation

/// Main orchestration controller for RewriteAI
@Observable
class AIManager {
    var status: String = "Ready"
    var isProcessing = false
    
    /// Service Provider Factory returning an implementation conforming to AIService protocol
    func service(for engine: AIEngine) -> AIService {
        switch engine {
        case .gemini:
            return GeminiService()
        case .gpt:
            return OpenAIService()
        }
    }
    
    /// Processes text rewrite flow end-to-end
    /// - Parameters:
    ///   - engine: Selected AI Provider (.gemini or .gpt)
    ///   - prompt: Desired rewrite preset style (.professional, .funny, .summarize)
    func process(engine: AIEngine, prompt: Style) {
        // Prevent concurrent double-invocations
        guard !isProcessing else { return }
        
        let _ = checkAccessibility()
        
        TextService.shared.captureFocus()
        
        Task { @MainActor in
            isProcessing = true
            HUDManager.shared.show()
            
            defer {
                self.isProcessing = false
                HUDManager.shared.hide()
            }
            
            let provider = service(for: engine)
            
            do {
                guard let selectedText = await TextService.shared.getSelectedText(),
                      !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw AIError.emptySelection
                }
                
                let rewrittenText = try await provider.rewrite(selectedText, style: prompt)
                TextService.shared.replaceText(with: rewrittenText)
                
            } catch {
                showErrorDialog(title: "\(provider.providerName) Error", message: error.localizedDescription)
            }
        }
    }
}

extension AIManager {
    @MainActor
    func showErrorDialog(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.window.level = .floating
        alert.runModal()
    }
}

/// Helper to verify Accessibility permission prompt
func checkAccessibility() -> Bool {
    let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}
