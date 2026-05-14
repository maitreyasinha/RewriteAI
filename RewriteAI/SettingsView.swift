//
//  SettingsView.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

struct SettingsView: View {
    // This automatically saves/loads from the Mac's internal storage
    @AppStorage("gemini_api_key") private var apiKey: String = ""
    
    var body: some View {
            Form {
                Section(header: Text("API Configuration")) {
                    SecureField("Gemini API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Get your key at [Google AI Studio](https://aistudio.google.com/)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(width: 400, height: 150)
            .onAppear {
                       makeWindowFloat()
                   }
        }
    
    private func makeWindowFloat() {
            // 1. Force the app to the front so the window isn't born in the background
            NSApp.activate(ignoringOtherApps: true)

            // 2. Find the window that contains this view
            // We look for windows that are currently visible and belong to our app
            for window in NSApplication.shared.windows {
                // Standard SwiftUI settings windows usually have "Settings" or the App Name in the title
                if window.isVisible && (window.title == "Settings" || window.frame.width == 350) {
                    window.level = .floating // Keeps it above TextEdit/Chrome
                    window.center()          // Optional: Keeps it centered
                }
            }
        }
}
