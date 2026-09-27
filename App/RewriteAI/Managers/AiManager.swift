//
//  AiManager.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI
import Observation
import AppKit

/// Main orchestration controller for RewriteAI
@Observable
class AIManager {
    var inputText: String = ""
    var rewrittenText: String = ""
    var isProcessing: Bool = false
    var errorMessage: String? = nil
    var isCopied: Bool = false
    var selectedStyle: Style? = nil
    
    /// Service Provider Factory returning an implementation conforming to AIService protocol
    func service(for engine: AIEngine = .gemini) -> AIService {
        switch engine {
        case .gemini:
            return GeminiService()
        case .gpt:
            return OpenAIService()
        }
    }
    
    /// Automatically captures selected text when popover opens
    @MainActor
    func captureSelectedTextOnOpen() async {
        TextService.shared.captureFocus()
        if let captured = await TextService.shared.getSelectedText(),
           !captured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.inputText = captured
            self.errorMessage = nil
        }
    }
    
    /// Explicitly captures selected text from the active application using TextService
    @MainActor
    func captureSelectedText() async {
        TextService.shared.captureFocus()
        if let captured = await TextService.shared.getSelectedText(),
           !captured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.inputText = captured
            self.errorMessage = nil
        }
    }
    
    /// Processes text rewrite flow and updates state for popover UI
    /// - Parameters:
    ///   - engine: Selected AI Provider (defaults to .gemini)
    ///   - style: Desired rewrite preset style (.professional, .funny, .summarize)
    @MainActor
    func process(engine: AIEngine = .gemini, style: Style) {
        guard !isProcessing else { return }
        selectedStyle = style
        errorMessage = nil
        
        Task {
            // If input text is empty, attempt to capture selected text automatically
            if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await captureSelectedText()
            }
            
            let textToProcess = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !textToProcess.isEmpty else {
                errorMessage = AIError.emptySelection.localizedDescription
                return
            }
            
            isProcessing = true
            
            defer {
                isProcessing = false
            }
            
            let provider = service(for: engine)
            
            do {
                let result = try await provider.rewrite(textToProcess, style: style)
                self.rewrittenText = result
                self.errorMessage = nil
            } catch let error as AIError {
                self.errorMessage = error.localizedDescription
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Copies the rewritten text to system clipboard and shows feedback
    @MainActor
    func copyToClipboard() {
        guard !rewrittenText.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(rewrittenText, forType: .string)
        
        isCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.isCopied = false
        }
    }
    
    /// Clears input and rewritten output text
    @MainActor
    func clearAll() {
        inputText = ""
        rewrittenText = ""
        errorMessage = nil
        selectedStyle = nil
    }
    
    /// Opens Settings window
    @MainActor
    func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
