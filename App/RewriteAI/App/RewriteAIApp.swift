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
            ContentView()
                .environment(aiManager)
        } label: {
            Image(systemName: aiManager.isProcessing ? "ellipsis.circle.fill" : "sparkles")
                .symbolEffect(.pulse, isActive: aiManager.isProcessing)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}
