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
            if aiManager.isProcessing {
                Image(systemName: "ellipsis.circle.fill")
                    .symbolEffect(.pulse, isActive: true)
            } else {
                Image("MenuBarIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
        .menuBarExtraStyle(.window)
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 480, height: 240)
        .windowResizability(.contentSize)
    }
}
