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
        MenuBarExtra {
            // Gemini Options
            Menu("Rewrite with Gemini") {
                ForEach(Style.allCases) { style in
                    Button(style.rawValue) {
                        aiManager.process(engine: .gemini, prompt: style)
                    }
                }
            }
            
            // OpenAI GPT-4o Options
            Menu("Rewrite with GPT-4o") {
                ForEach(Style.allCases) { style in
                    Button(style.rawValue) {
                        aiManager.process(engine: .gpt, prompt: style)
                    }
                }
            }
            
            Divider()
            
            SettingsLink {
                Text("Settings…")
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
            
        } label: {
            Image(systemName: aiManager.isProcessing ? "ellipsis.circle.fill" : "sparkles")
                .symbolEffect(.pulse, isActive: aiManager.isProcessing)
        }
        
        Settings {
            SettingsView()
        }
    }
}
