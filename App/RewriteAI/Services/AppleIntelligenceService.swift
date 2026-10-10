//
//  AppleIntelligenceService.swift
//  RewriteAI
//
//  Uses Apple's on-device Foundation Model for private, key-free rewrites.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Rewrites text with the on-device Apple Intelligence model when it is available.
struct AppleIntelligenceService: AIService {
    let providerName = "Apple Intelligence"

    func rewrite(_ text: String, style: Style) async throws -> String {
#if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AIError.requestFailed(
                message: "Apple Intelligence rewrites require macOS 26 or later."
            )
        }

        return try await rewriteUsingSystemModel(text, style: style)
#else
        throw AIError.requestFailed(
            message: "This build does not include the Foundation Models framework."
        )
#endif
    }

#if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func rewriteUsingSystemModel(_ text: String, style: Style) async throws -> String {
        let model = SystemLanguageModel.default

        guard case .available = model.availability else {
            throw AIError.requestFailed(
                message: "Apple Intelligence is unavailable. Enable it in System Settings and wait for its model to finish downloading."
            )
        }

        let session = LanguageModelSession(instructions: """
            You rewrite supplied text according to the requested style.
            Return only the rewritten text, with no preamble, explanation, quotation marks, or Markdown.
            Preserve the input language unless the request explicitly asks otherwise.
            """)

        let response = try await session.respond(to: """
            Style: (style.rawValue)
            Instruction: (style.promptInstruction)

            Text to rewrite:
            (text)
            """)

        let rewrittenText = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rewrittenText.isEmpty else {
            throw AIError.requestFailed(message: "Apple Intelligence returned an empty rewrite.")
        }

        return rewrittenText
    }
#endif
}
