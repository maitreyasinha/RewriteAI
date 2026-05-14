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
enum Style {
    case Professional, Funny, Summarize
}

enum AIError: Error, LocalizedError {
    case requestFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return message
        }
    }
}

// Helper to decode Google's specific error JSON
struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetails
    struct GeminiErrorDetails: Decodable {
        let message: String
    }
}


@Observable
class AIManager {
    var status: String = "Ready"
    var isProcessing = false
        
    private let gemini = GeminiService()
    
    func process(engine: AIEngine, prompt: Style) {
        let _ = checkAccessibility()
        
        // Prevent re-entrancy/crashes from overlapping calls
        if isProcessing { return }
       
        TextService.shared.captureFocus()
        guard let selectedText = TextService.shared.getSelectedText() else { return }
        HUDManager.shared.show()
        Task { @MainActor in
            isProcessing = true
             // Show the "Thinking" Bubble
            NSCursor.pointingHand.set() // Tactile feedback
            
            do {
                let rewrittenText = try await gemini.rewrite(selectedText)
                // Replaces text in the original app
                TextService.shared.replaceText(with: rewrittenText)
                // Always clean up
                isProcessing = false
                HUDManager.shared.hide()
            } catch {
                isProcessing = false
                HUDManager.shared.hide()
                showErrorDialog(title: "Error", message: error.localizedDescription)
            }
            
        }
    }
    
    private func callMockAPI(engine: AIEngine) {
        // This is where your API logic will live in Step 3
        let mockResult = "This is a polished version of your text."
    }
    
    @MainActor
    private func showShield() {
        NSCursor.busy.set()
    }

    @MainActor
    private func hideShield() {
        NSCursor.arrow.set()
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
        alert.runModal() // This pauses the app until they click OK
    }
}

extension NSCursor {
    static var busy: NSCursor {
        // Using the "progress" or "wait" symbols from macOS Tahoe
        let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: "Busy")?
            .withSymbolConfiguration(config)
        
        // We have to convert the SF Symbol to a standard image to use it as a cursor
        return NSCursor(image: image ?? NSCursor.arrow.image, hotSpot: NSPoint(x: 12, y: 12))
    }
}

func checkAccessibility() -> Bool {
    let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let status = AXIsProcessTrustedWithOptions(options as CFDictionary)
    return status
}
