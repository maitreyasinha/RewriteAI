//
//  ContentView.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AIManager.self) private var aiManager
    @AppStorage("gemini_api_key") private var geminiApiKey: String = ""
    
    private var isApiKeySet: Bool {
        !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.tint)
                        .font(.title3)
                    Text("RewriteAI")
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    aiManager.openSettings()
                }) {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Quit RewriteAI")
            }
            
            Divider()
            
            // Missing API Key Banner
            if !isApiKeySet {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gemini API Key Required")
                            .font(.caption)
                            .bold()
                        Text("Add your key in Settings to begin rewriting.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Settings") {
                        aiManager.openSettings()
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(6)
            }
            
            // Input Text Area
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Original Text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await aiManager.captureSelectedText()
                        }
                    }) {
                        Label("Capture Text", systemImage: "doc.on.clipboard")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    
                    if !aiManager.inputText.isEmpty {
                        Button("Clear") {
                            aiManager.clearAll()
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                    }
                }
                
                ZStack(alignment: .topLeading) {
                    if aiManager.inputText.isEmpty {
                        Text("Highlight text in any app & click a style below, or paste text here...")
                            .font(.callout)
                            .foregroundColor(.secondary.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: Bindable(aiManager).inputText)
                        .font(.callout)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(height: 80)
            }
            
            // Style Selector Buttons
            VStack(alignment: .leading, spacing: 6) {
                Text("Select Style to Rewrite")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(Style.allCases) { style in
                        Button(action: {
                            aiManager.process(engine: .gemini, style: style)
                        }) {
                            HStack(spacing: 4) {
                                if aiManager.isProcessing && aiManager.selectedStyle == style {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: iconForStyle(style))
                                }
                                Text(style.rawValue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .disabled(aiManager.isProcessing)
                    }
                }
            }
            
            // Processing Status Indicator
            if aiManager.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Rewriting with Gemini...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            
            // Error Message Banner
            if let errorMsg = aiManager.errorMessage {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorMsg)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Rewritten Output Area
            if !aiManager.rewrittenText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Rewritten Result")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        Button(action: {
                            aiManager.copyToClipboard()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: aiManager.isCopied ? "checkmark" : "doc.on.doc")
                                Text(aiManager.isCopied ? "Copied!" : "Copy")
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(aiManager.isCopied ? .green : .accentColor)
                        .controlSize(.small)
                    }
                    
                    ScrollView {
                        Text(aiManager.rewrittenText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .frame(maxHeight: 120)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 360, height: aiManager.rewrittenText.isEmpty ? 320 : 440)
        .task {
            await aiManager.captureSelectedTextOnOpen()
        }
    }
    
    private func iconForStyle(_ style: Style) -> String {
        switch style {
        case .professional:
            return "briefcase"
        case .funny:
            return "face.smiling"
        case .summarize:
            return "text.alignleft"
        }
    }
}

#Preview {
    ContentView()
        .environment(AIManager())
}
