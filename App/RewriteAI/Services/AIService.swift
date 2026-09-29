//
//  AIService.swift
//  RewriteAI
//
//  Created by Antigravity on 20/09/2026.
//

import Foundation

// MARK: - Enums & Data Types

/// Supported AI Engine Providers
enum AIEngine: String, CaseIterable, Identifiable {
    case gemini = "Gemini"
    case gpt = "GPT-4o"
    case customEndpoint = "Custom Endpoint"
    
    var id: String { rawValue }
}

/// Rewrite style options with associated prompt instructions
enum Style: String, CaseIterable, Identifiable {
    case professional = "Professional"
    case funny = "Funny"
    case summarize = "Summarize"
    
    var id: String { rawValue }
    
    /// System/User instruction tailored to the selected style
    var promptInstruction: String {
        switch self {
        case .professional:
            return "Rewrite the following text to be professional, clear, concise, and well-structured."
        case .funny:
            return "Rewrite the following text in a witty, humorous, and lighthearted tone."
        case .summarize:
            return "Summarize the key points of the following text as clearly and concisely as possible."
        }
    }
}

/// Errors thrown by AI Services during processing
enum AIError: Error, LocalizedError {
    case missingAPIKey(providerName: String)
    case requestFailed(message: String)
    case emptySelection
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let providerName):
            return "\(providerName) API key is missing. Please add your key in Settings."
        case .requestFailed(let message):
            return message
        case .emptySelection:
            return "No text selected. Please highlight text before using RewriteAI."
        }
    }
}

// MARK: - AIService Protocol

/// Abstract interface for all AI provider integrations (Gemini, OpenAI, Local models, etc.)
protocol AIService {
    /// Human-readable provider name (e.g. "Google Gemini", "OpenAI")
    var providerName: String { get }
    
    /// Sends text to the AI model and returns the rewritten response according to style
    /// - Parameters:
    ///   - text: The input text captured from the active application
    ///   - style: The desired rewrite style/preset
    /// - Returns: The rewritten text string
    func rewrite(_ text: String, style: Style) async throws -> String
}
