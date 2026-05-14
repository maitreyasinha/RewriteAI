//
//  RewriteAIApp.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

@main
struct RewriteAIApp: App {
    @State private var aiManager = AIManager()
    var body: some Scene {
        // This is your Clipy-style menu bar icon
        MenuBarExtra("Rewrite", systemImage: "sparkles") {
                    Button("Rewrite Selection (Gemini)") {
                        aiManager.process(engine: .gemini)
                    }
                    Button("Rewrite Selection (GPT-5)") {
                        aiManager.process(engine: .gpt)
                    }
                    Divider()
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                }
    }
}
