//
//  GeminiService.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Foundation
import AppKit

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
    // 2. Use this computed property instead:
       private var apiKey: String {
           // This looks at the same "key" name used in your SettingsView
           UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
       }
        private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent"

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
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            
                    // 1. Try to parse Google's error JSON
                    if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                        throw AIError.requestFailed(message: errorResponse.error.message)
                    }
                    // 2. Fallback if the JSON is weird
                    throw AIError.requestFailed(message: "Server returned status \(httpResponse.statusCode)")
                }
            }

            let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return result.candidates.first?.content.parts.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error: No text returned"
    }
}

@MainActor
class HUDManager {
    static let shared = HUDManager()
    private var hudWindow: NSPanel?

    func show(at point: NSPoint? = nil) {
        if hudWindow != nil { return }
        
        // 1. Create a tiny, elegant panel
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        
        panel.backgroundColor = .black.withAlphaComponent(0.8)
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .mainMenu // Sits above most things
        panel.isMovableByWindowBackground = true
        panel.center() // Or position near mouse
        
        // 2. Add a spinner and text
        let stack = NSStackView(frame: panel.contentView!.bounds)
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.startAnimation(nil)
        
        let text = NSTextField(labelWithString: "Rewriting...")
        text.textColor = .white
        text.font = .systemFont(ofSize: 12, weight: .medium)
        
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(text)
        panel.contentView?.addSubview(stack)
        
        panel.orderFrontRegardless()
        self.hudWindow = panel
    }

    func hide() {
        hudWindow?.orderOut(nil)
        hudWindow = nil
    }
}
