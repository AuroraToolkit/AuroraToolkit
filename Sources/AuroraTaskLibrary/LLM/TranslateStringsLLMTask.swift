//
//  TranslateStringsLLMTask.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/3/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `TranslateStringsLLMTask` translates a list of strings into a specified target language using an LLM service.
///
/// - **Inputs**
///    - `strings`: The list of strings to translate.
///    - `targetLanguage`: The target language for the translation (e.g., "fr" for French, "es" for Spanish).
///    - `sourceLanguage`: The source language of the strings (optional). Defaults to `nil` (infers the language if not provided).
///    - `maxTokens`: The maximum number of tokens to generate in the response. Defaults to `500`.
/// - **Outputs**
///    - `translations`: A dictionary where keys are the original strings and values are the translated strings.
///    - `thoughts`: An array of strings containing the LLM's chain-of-thought entries, if any.
///    - `rawResponse`: The original unmodified raw response text from the LLM.
///
/// ### Use Cases
/// - Translate user-generated content into a standard language for consistency in applications.
/// - Provide multi-language support for articles, reviews, or other content.
/// - Enable real-time translation of chat messages in global communication tools.
///
/// ### Example:
/// **Input Strings:**
/// - "Hello, how are you?"
/// - "This is an example sentence."
///
/// **Target Language:**
/// - French
///
/// **Output JSON:**
/// ```
/// {
///    "Hello, how are you?": "Bonjour, comment ça va?",
///    "This is an example sentence.": "Ceci est une phrase d'exemple."
/// }
/// ```
public class TranslateStringsLLMTask: WorkflowComponentProtocol {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a new `TranslateStringsLLMTask`.
    ///
    /// - Parameters:
    ///    - name: The name of the task.
    ///    - llmService: The LLM service used for translation.
    ///    - strings: The list of strings to translate.
    ///    - targetLanguage: The target language for the translation (e.g., "fr" for French).
    ///    - sourceLanguage: The source language of the strings (optional). Defaults to `nil` (infers the language if not provided).
    ///    - maxTokens: The maximum number of tokens to generate in the response. Defaults to 500.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(
        name: String? = nil,
        llmService: LLMServiceProtocol,
        strings: [String]? = nil,
        targetLanguage: String,
        sourceLanguage: String? = nil,
        maxTokens: Int = 500,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Translate strings into the target language using the LLM service",
            inputs: inputs
        ) { inputs in
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []

            guard !resolvedStrings.isEmpty else {
                logger?.error("TranslateStringsLLMTask [execute] No strings provided for translation", category: "TranslateStringsLLMTask")
                throw NSError(
                    domain: "TranslateStringsLLMTask",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No strings provided for translation."]
                )
            }

            let resolvedTargetLanguage = inputs.resolve(key: "targetLanguage", fallback: targetLanguage)
            let resolvedSourceLanguage = inputs.resolve(key: "sourceLanguage", fallback: sourceLanguage)

            let jsonInput: [String: Any] = [
                "strings": resolvedStrings,
                "targetLanguage": resolvedTargetLanguage,
                "sourceLanguage": resolvedSourceLanguage as Any
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedStrings.joined(separator: "\n")

            let translationPrompt = """
            You are a professional translator. Translate the provided list of strings into the target language.

            Format the results as a single valid JSON object where:
            - Each key is an EXACT original string from the input.
            - Each value is its translated version.

            Expected Output JSON structure:
            {
              "original string 1": "translated string 1",
              "original string 2": "translated string 2"
            }

            Important:
            1. Return ONLY the JSON object.
            2. Do not include markdown code fences (like ```json), explanations, or any other text.
            3. Preserve all punctuation and casing from the original strings.
            4. Translate ALL strings provided in the input.

            Input data:
            \(jsonString)
            """

            let request = LLMRequest(
                messages: [
                    LLMMessage(role: .system, content: "You are a professional translation expert. You will receive a JSON object containing strings to translate. You MUST respond ONLY with a valid JSON object mapping original strings to their translations. No conversation, no thoughts, no markdown."),
                    LLMMessage(role: .user, content: translationPrompt),
                ],
                maxTokens: maxTokens
            )

            do {
                let response = try await llmService.sendRequest(request)

                let fullResponse = response.text
                let (thoughts, rawResponse) = fullResponse.extractThoughtsAndStripJSON()

                guard let data = rawResponse.data(using: .utf8),
                      let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    logger?.error("TranslateStringsLLMTask [execute] Failed to parse JSON response: \(rawResponse)", category: "TranslateStringsLLMTask")
                    throw NSError(
                        domain: "TranslateStringsLLMTask",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response: \(response.text)"]
                    )
                }

                // Handle both formats: wrapped in "translations" or direct mapping
                if let wrappedTranslations = jsonResponse["translations"] as? [String: String] {
                    // Already wrapped format: {"translations": {"original": "translated"}}
                    return [
                        "translations": wrappedTranslations,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else if let directTranslations = jsonResponse as? [String: String] {
                    // Direct format: {"original": "translated"}
                    return [
                        "translations": directTranslations,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else {
                    throw NSError(
                        domain: "TranslateStringsLLMTask",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected format for translation response."]
                    )
                }
            } catch {
                throw error
            }
        }
    }

    /// Converts this `TranslateStringsLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
