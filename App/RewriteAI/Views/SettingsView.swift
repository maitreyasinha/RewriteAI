//
//  SettingsView.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

/// Settings view for configuring AI provider and API keys
struct SettingsView: View {
    @AppStorage("selected_engine") private var selectedEngineRaw: String = AIEngine.customEndpoint.rawValue
    @AppStorage("gemini_api_key") private var geminiApiKey: String = ""
    @AppStorage("openai_api_key") private var openaiApiKey: String = ""
    
    private var selectedEngine: AIEngine {
        AIEngine(rawValue: selectedEngineRaw) ?? .customEndpoint
    }
    
    private var isKeyConfigured: Bool {
        switch selectedEngine {
        case .customEndpoint:
            return true
        case .gemini:
            return !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .gpt:
            return !openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Provider Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("AI Provider")
                    .font(.headline)
                
                Picker("Provider", selection: $selectedEngineRaw) {
                    ForEach(AIEngine.allCases) { engine in
                        Text(engine.rawValue).tag(engine.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            // Provider Specific Config
            VStack(alignment: .leading, spacing: 8) {
                switch selectedEngine {
                case .customEndpoint:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Custom hosted endpoint at https://rewrite-ai-kappa.vercel.app/api. No API key required.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                case .gemini:
                    HStack {
                        Text("Google Gemini API Key")
                            .font(.subheadline)
                            .bold()
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
                    
                    Text("Requires a Google Gemini API key. Get a free key at [Google AI Studio](https://aistudio.google.com/).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                case .gpt:
                    HStack {
                        Text("OpenAI API Key")
                            .font(.subheadline)
                            .bold()
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
                    
                    SecureField("Paste your OpenAI API Key", text: $openaiApiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Requires an OpenAI API key.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 440, height: 200)
        .onAppear {
            makeWindowFloat()
        }
    }
    
    private func makeWindowFloat() {
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApplication.shared.windows {
            if window.isVisible && (window.title == "Settings" || window.frame.width == 440) {
                window.level = .floating
                window.center()
            }
        }
    }
}

#Preview {
    SettingsView()
}
