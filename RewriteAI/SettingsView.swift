//
//  SettingsView.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

/// Settings view for configuring API keys
struct SettingsView: View {
    @AppStorage("gemini_api_key") private var geminiApiKey: String = ""
    @AppStorage("openai_api_key") private var openAIApiKey: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Google Gemini API")) {
                SecureField("Gemini API Key", text: $geminiApiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get your key at [Google AI Studio](https://aistudio.google.com/)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("OpenAI API (GPT-4o)")) {
                SecureField("OpenAI API Key", text: $openAIApiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Get your key at [OpenAI Platform](https://platform.openai.com/api-keys)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 420, height: 230)
        .onAppear {
            makeWindowFloat()
        }
    }
    
    private func makeWindowFloat() {
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApplication.shared.windows {
            if window.isVisible && (window.title == "Settings" || window.frame.width == 420) {
                window.level = .floating
                window.center()
            }
        }
    }
}

#Preview {
    SettingsView()
}
