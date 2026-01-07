//
//  AnalyzeSentimentLLMTask.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/2/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `AnalyzeSentimentLLMTask` is a workflow component that analyzes the sentiment of text strings using a Large Language Model (LLM).
///
/// This task leverages LLM capabilities to perform nuanced sentiment analysis, going beyond simple positive/negative classifications
/// to provide detailed sentiment insights including confidence levels and reasoning.
///
/// - **Inputs**
///   - `strings`: An array of text strings to analyze for sentiment.
///   - `options`: Optional sentiment analysis options (detailed vs. simple analysis, confidence thresholds, etc.).
///
/// - **Outputs**
///   - `sentiments`: An array of sentiment analysis results, each containing sentiment label, confidence score, and optional reasoning.
///   - `thoughts`: An array of strings containing the LLM's chain-of-thought entries, if any.
///   - `rawResponse`: The original unmodified raw response text from the LLM.
///
/// ### Use Cases:
/// - **Customer Feedback Analysis**: Analyzing customer reviews, support tickets, or survey responses.
/// - **Social Media Monitoring**: Understanding public sentiment around brands, products, or events.
/// - **Content Moderation**: Identifying potentially harmful or negative content.
/// - **Market Research**: Analyzing sentiment trends in user-generated content or feedback.
///
/// ### Example:
/// **Input Strings:**
/// - "I absolutely love this new product! It's amazing."
/// - "The service was okay, nothing special."
/// - "This is the worst experience I've ever had."
///
/// **Output:**
/// ```
/// {
///   "sentiments": [
///     {"text": "I absolutely love this new product! It's amazing.", "sentiment": "positive", "confidence": 0.95},
///     {"text": "The service was okay, nothing special.", "sentiment": "neutral", "confidence": 0.78},
///     {"text": "This is the worst experience I've ever had.", "sentiment": "negative", "confidence": 0.92}
///   ]
/// }
/// ```
public class AnalyzeSentimentLLMTask: WorkflowComponentProtocol {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a new `AnalyzeSentimentLLMTask`.
    ///
    /// - Parameters:
    ///    - name: The name of the task.
    ///    - llmService: The LLM service used for sentiment analysis.
    ///    - strings: The list of strings to analyze.
    ///    - detailed: Whether to return detailed sentiment analysis (e.g., confidence scores). Defaults to `false`.
    ///    - maxTokens: The maximum number of tokens to generate in the response. Defaults to 500.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(
        name: String? = nil,
        llmService: LLMServiceProtocol,
        strings: [String]? = nil,
        detailed: Bool = false,
        maxTokens: Int = 500,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Analyze the sentiment of a list of strings using an LLM service",
            inputs: inputs
        ) { inputs in
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []
            guard !resolvedStrings.isEmpty else {
                logger?.error("AnalyzeSentimentLLMTask [execute] No strings provided", category: "AnalyzeSentimentLLMTask")
                throw NSError(
                    domain: "AnalyzeSentimentLLMTask",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No strings provided for sentiment analysis."]
                )
            }

            let resolvedDetailed = inputs.resolve(key: "detailed", fallback: detailed)

            // Build the prompt for the LLM
            let jsonInput: [String: Any] = [
                "strings": resolvedStrings,
                "detailed": resolvedDetailed
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedStrings.joined(separator: "\n")

            // Build the prompt for the LLM
            let sentimentPrompt = """
            You are a sentiment analysis expert. Analyze the sentiment of the provided strings.

            Format the results as a single valid JSON object where:
            - Each key is an EXACT original string from the input.
            - Each value is \(resolvedDetailed ? "an object containing the 'sentiment' (Positive, Neutral, or Negative) and a 'confidence' score (0 to 100)" : "the sentiment (Positive, Neutral, or Negative)") .

            Expected Output JSON structure:
            {
              "original string 1": \(resolvedDetailed ? "{\"sentiment\": \"Positive\", \"confidence\": 95}" : "\"Positive\""),
              "original string 2": \(resolvedDetailed ? "{\"sentiment\": \"Negative\", \"confidence\": 90}" : "\"Negative\"")
            }

            Important:
            1. Return ONLY the JSON object.
            2. Do not include markdown code fences (like ```json), explanations, or any other text.
            3. Analyze ALL strings provided in the input.

            Input data (JSON):
            \(jsonString)
            """

            let request = LLMRequest(
                messages: [
                    LLMMessage(role: .system, content: "You are a professional sentiment analysis expert. You will receive a JSON object containing strings to analyze. You MUST respond ONLY with a valid JSON object mapping original strings to their sentiment analysis. No conversation, no thoughts, no markdown."),
                    LLMMessage(role: .user, content: sentimentPrompt),
                ],
                maxTokens: maxTokens
            )

            do {
                let response = try await llmService.sendRequest(request)

                let fullResponse = response.text
                let (thoughts, rawResponse) = fullResponse.extractThoughtsAndStripJSON()

                // Parse the response into a dictionary (assumes LLM returns JSON-like structure).
                guard let data = rawResponse.data(using: .utf8),
                      let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    logger?.error("AnalyzeSentimentLLMTask [execute] Failed to parse JSON response: \(rawResponse)", category: "AnalyzeSentimentLLMTask")
                    throw NSError(
                        domain: "AnalyzeSentimentLLMTask",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response as JSON."]
                    )
                }

                // Handle two formats: wrapped in "sentiments" or direct mapping
                let sentiments: Any
                if let wrappedSentiments = jsonResponse["sentiments"] {
                    // Format: {"sentiments": {...}} - some models might wrap the response in a "sentiments" key
                    sentiments = wrappedSentiments
                } else {
                    // Format: {"string": "sentiment", ...} - direct mapping (preferred)
                    sentiments = jsonResponse
                }

                // Validate and return in consistent wrapped format
                if let detailedSentiments = sentiments as? [String: [String: Any]] {
                    return [
                        "sentiments": detailedSentiments,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else if let simpleSentiments = sentiments as? [String: String] {
                    return [
                        "sentiments": simpleSentiments,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else {
                    throw NSError(
                        domain: "AnalyzeSentimentLLMTask",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected format for sentiment analysis response."]
                    )
                }
            } catch {
                logger?.error("AnalyzeSentimentLLMTask [execute] Failed: \(error.localizedDescription)", category: "AnalyzeSentimentLLMTask")
                throw error
            }
        }
    }

    /// Converts this `AnalyzeSentimentLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
