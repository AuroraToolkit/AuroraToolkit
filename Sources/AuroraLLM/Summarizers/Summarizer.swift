//
//  Summarizer.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 8/21/24.
//

import AuroraCore
import Foundation

/// The `Summarizer` class provides an implementation of the `SummarizerProtocol`, delegating all summarization tasks to an LLM service.
public class Summarizer: SummarizerProtocol {
    private let llmService: LLMServiceProtocol
    private let logger: CustomLogger?

    /// Initializes a new `Summarizer` instance with the specified LLM service.
    ///
    /// - Parameters:
    ///    - llmService: The LLM service to use for summarization.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(llmService: LLMServiceProtocol, logger: CustomLogger? = nil) {
        self.llmService = llmService
        self.logger = logger
    }

    /// Summarizes a text using the LLM service.
    ///
    /// - Parameters:
    ///     - text: The text to summarize.
    ///     - options: The summarization options to configure the LLM response.
    ///     - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    ///
    /// - Returns: The summarized text.
    public func summarize(_ text: String, options: SummarizerOptions? = nil, logger: CustomLogger? = nil) async throws -> String {
        let logger = logger ?? self.logger

        logger?.debug("Summarizer [summarize] Starting single text summarization (length: \(text.count) characters)", category: "Summarizer")

        let messages: [LLMMessage] = [
            LLMMessage(role: .system, content: "Summarize the following text."),
            LLMMessage(role: .user, content: text),
        ]

        do {
            let result = try await sendToLLM(messages, options: options)
            logger?.debug("Summarizer [summarize] Single text summarization completed successfully", category: "Summarizer")
            return result
        } catch {
            logger?.error("Summarizer [summarize] Single text summarization failed: \(error.localizedDescription)", category: "Summarizer")
            throw error
        }
    }

    /// Summarizes multiple texts using the LLM service.
    ///
    /// - Parameters:
    ///     - texts: An array of texts to summarize.
    ///     - type: The type of summary to generate (e.g., `.single`, or `.multiple`).
    ///     - options: The summarization options to configure the LLM response.
    ///     - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    ///
    /// - Returns: An array of summarized texts corresponding to the input texts.
    public func summarizeGroup(
        _ texts: [String],
        type: SummaryType,
        options: SummarizerOptions? = nil,
        logger: CustomLogger? = nil
    ) async throws -> [String] {
        let logger = logger ?? self.logger

        logger?.debug("Summarizer [summarizeGroup] Starting group summarization (count: \(texts.count), type: \(type))", category: "Summarizer")

        guard !texts.isEmpty else {
            logger?.error("Summarizer [summarizeGroup] No texts provided for summarization", category: "Summarizer")
            throw NSError(domain: "Summarizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No texts provided for summarization."])
        }

        do {
            let result: [String]

            switch type {
            case .single:
                logger?.debug("Summarizer [summarizeGroup] Performing single combined summary", category: "Summarizer")
                // Combine texts into one string and use the existing `summarize` function
                let combinedText = texts.joined(separator: "\n")
                let summary = try await summarize(combinedText, options: options)
                result = [summary]

            case .multiple:
                logger?.debug("Summarizer [summarizeGroup] Performing multiple individual summaries", category: "Summarizer")
                // Use JSON input for structured summarization of individual texts
                let jsonInput: [String: Any] = ["texts": texts]
                let jsonData = try JSONSerialization.data(withJSONObject: jsonInput, options: [])
                let jsonString = String(decoding: jsonData, as: UTF8.self)

                // Create messages for the LLM
                let messages: [LLMMessage] = [
                    LLMMessage(role: .system, content: summaryInstruction(for: .multiple)),
                    LLMMessage(role: .user, content: jsonString),
                ]

                // Send the request to the LLM
                let response = try await sendToLLM(messages, options: options)

                // Parse the JSON response
                guard let responseData = response.data(using: .utf8),
                      let jsonResponse = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                      let summaries = jsonResponse["summaries"] as? [String]
                else {
                    logger?.error("Summarizer [summarizeGroup] Failed to parse JSON response: \(response)", category: "Summarizer")
                    throw NSError(domain: "Summarizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response from LLM: \(response)"])
                }

                result = summaries
            }

            logger?.debug("Summarizer [summarizeGroup] Group summarization completed successfully (returned \(result.count) summaries)", category: "Summarizer")
            return result

        } catch {
            logger?.error("Summarizer [summarizeGroup] Group summarization failed: \(error.localizedDescription)", category: "Summarizer")
            throw error
        }
    }

    /// Constructs the appropriate system-level instruction based on the summary type.
    ///
    /// - Parameter type: The type of summary to generate (e.g., `.single`, or `.multiple`).
    ///
    /// - Returns: The appropriate system instruction for the summary type.
    private func summaryInstruction(for type: SummaryType) -> String {
        switch type {
        case .single:
            return "Summarize the following text:\n"
        case .multiple:
            return """
            You are an assistant that summarizes text. I will provide a JSON object containing a list of texts under the key "texts".
            For each text, provide a concise summary in the same JSON format under the key "summaries".

            For example:
            Input: {"texts": ["Text 1", "Text 2"]}
            Output: {"summaries": ["Summary of Text 1", "Summary of Text 2"]}

            Here is the input:
            """
        }
    }

    /// Sends the messages to the LLM service for summarization and returns the result.
    ///
    /// - Parameters:
    ///    - messages: The conversation messages to be sent to the LLM service.
    ///    - options: The summarization options to configure the LLM response.
    ///
    /// - Returns: The summarized result returned by the LLM service.
    ///
    /// - Throws: An error if the LLM service fails to process the request.
    private func sendToLLM(_ messages: [LLMMessage], options: SummarizerOptions? = nil) async throws -> String {
        let maxTokens = min(options?.maxTokens ?? llmService.maxOutputTokens, llmService.maxOutputTokens)

        logger?.debug("Summarizer [sendToLLM] Sending request to LLM service (maxTokens: \(maxTokens))", category: "Summarizer")

        let request = LLMRequest(
            messages: messages,
            temperature: options?.temperature ?? 0.7,
            maxTokens: maxTokens,
            model: options?.model,
            stream: options?.stream ?? false
        )

        let response = try await llmService.sendRequest(request)

        logger?.debug("Summarizer [sendToLLM] Received response from LLM service (length: \(response.text.count) characters)", category: "Summarizer")

        return response.text
    }
}
