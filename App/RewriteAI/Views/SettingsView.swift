//
//  SettingsView.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

/// Settings view for configuring Gemini API key
struct SettingsView: View {
    @AppStorage("gemini_api_key") private var geminiApiKey: String = ""
    
    private var isKeyConfigured: Bool {
        !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Google Gemini API Key")
                    .font(.headline)
                Spacer()
                if isKeyConfigured {
                    Label("Configured", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Key Required", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            SecureField("Paste your Gemini API Key", text: $geminiApiKey)
                .textFieldStyle(.roundedBorder)
            
            Text("RewriteAI v1 requires a Google Gemini API key. Get a free API key at [Google AI Studio](https://aistudio.google.com/).")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 420, height: 130)
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
