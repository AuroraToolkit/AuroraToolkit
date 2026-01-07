//
//  DetectLanguagesLLMTask.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/4/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `DetectLanguagesTask` identifies the language(s) of the provided strings using an LLM service.
///
/// - **Inputs**
///    - `strings`: An array of strings for which the language needs to be detected.
///    - `maxTokens`: The maximum number of tokens allowed for the LLM response. Defaults to 500.
/// - **Outputs**
///    - `languages`: A dictionary where the keys are the input strings, and the values are the detected language codes (e.g., "en" for English, "fr" for French).
///    - `thoughts`: An array of strings containing the LLM's chain-of-thought entries, if any.
///    - `rawResponse`: The original unmodified raw response text from the LLM.
///
/// ### Use Cases
/// - Analyze user-generated content to understand the languages used.
/// - Preprocess multilingual datasets for translation or other tasks.
/// - Detect and handle language-specific workflows in applications.
///
/// ### Example:
/// **Input Strings:**
/// - "Bonjour tout le monde."
/// - "Hello world!"
///
/// **Output JSON:**
/// ```
/// {
///     "languages": {
///         "Bonjour tout le monde.": "fr",
///         "Hello world!": "en"
///     }
/// }
/// ```
public class DetectLanguagesLLMTask: WorkflowComponentProtocol {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a `DetectLanguagesLLMTask` with the required parameters.
    ///
    /// - Parameters:
    ///    - name: Optionally pass the name of the task.
    ///    - llmService: The LLM service used for language detection.
    ///    - strings: The list of strings to analyze. Defaults to `nil` (can be resolved dynamically).
    ///    - maxTokens: The maximum number of tokens allowed for the response. Defaults to 500.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(
        name: String? = nil,
        llmService: LLMServiceProtocol,
        strings: [String]? = nil,
        maxTokens: Int = 500,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Detect languages for the provided strings",
            inputs: inputs
        ) { inputs in
            /// Resolve the strings from the inputs or use the provided parameter
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []

            guard !resolvedStrings.isEmpty else {
                logger?.error("DetectLanguagesLLMTask [execute] No strings provided for language detection", category: "DetectLanguagesLLMTask")
                throw NSError(domain: "DetectLanguagesLLMTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "No strings provided for language detection."])
            }

            let jsonInput: [String: Any] = [
                "strings": resolvedStrings
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedStrings.joined(separator: "\n")

            // Build the detection prompt
            let detectionPrompt = """
            You are a language detection expert. Identify the language(s) of the provided strings using ISO 639-1 language codes.

            Format the results as a single valid JSON object where:
            - Each key is an EXACT original string from the input.
            - Each value is its detected ISO 639-1 language code (e.g., "en", "fr", "es").

            Expected Output JSON structure:
            {
              "original string 1": "en",
              "original string 2": "fr"
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
                    LLMMessage(role: .system, content: "You are a language detection expert. You will receive a JSON object containing strings to detect. You MUST respond ONLY with a valid JSON object mapping original strings to their detected language codes. No conversation, no thoughts, no markdown."),
                    LLMMessage(role: .user, content: detectionPrompt),
                ],
                maxTokens: maxTokens
            )

            do {
                let response = try await llmService.sendRequest(request)

                let fullResponse = response.text
                let (thoughts, rawResponse) = fullResponse.extractThoughtsAndStripJSON()

                // Parse the response into a dictionary
                guard let data = rawResponse.data(using: .utf8),
                      let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    logger?.error("DetectLanguagesLLMTask [execute] Failed to parse JSON response: \(rawResponse)", category: "DetectLanguagesLLMTask")
                    throw NSError(
                        domain: "DetectLanguagesLLMTask",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response as JSON."]
                    )
                }

                // Handle both formats: wrapped in "languages" or direct mapping
                if let wrappedLanguages = jsonResponse["languages"] as? [String: String] {
                    // Already wrapped format: {"languages": {"text": "en"}}
                    return [
                        "languages": wrappedLanguages,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else if let directLanguages = jsonResponse as? [String: String] {
                    // Direct format: {"text": "en"}
                    return [
                        "languages": directLanguages,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else {
                    throw NSError(
                        domain: "DetectLanguagesLLMTask",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected format for language detection response."]
                    )
                }
            } catch {
                throw error
            }
        }
    }

    /// Converts this `DetectLanguagesLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
