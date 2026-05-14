//
//  RewriteAIApp.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

@main
struct RewriteAIApp: App {
    
    init(){
        print("Hello, the app is starting.. !!")
    }
    
    @State private var aiManager = AIManager()
    @State private var isProcessing = false
    var body: some Scene {
        // This is your Clipy-style menu bar icon
        MenuBarExtra{
            Menu("Rewrite with Gemini") {
                Button("Professional") {aiManager.process(engine: .gemini, prompt: .Professional)}
                Button("Funny") {aiManager.process(engine: .gemini, prompt: .Funny)}
                Button("Summarize") {aiManager.process(engine: .gemini, prompt: .Summarize)}
                }
                
            
            Button("Rewrite Selection (GPT-5)") {aiManager.process(engine: .gpt, prompt: .Summarize)}
                    Divider()
            // The modern, error-free way:
            SettingsLink {
                Text("Settings…")
            }
            
            Button("Quit") { NSApplication.shared.terminate(nil) }
        } label: {
            // 2. The Menu Bar Icon (The "View" where the modifier lives)
            Image(systemName: aiManager.isProcessing ? "ellipsis.circle.fill" : "sparkles")
                .symbolEffect(.pulse, isActive: aiManager.isProcessing)
        }        // This is the "Blueprint" for your settings window
        Settings {
            SettingsView()
        }
    }
}
