//
//  GenerateTitlesLLMTask.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/4/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `GenerateTitlesTask` generates succinct and informative titles for a given list of strings using an LLM service.
///
/// - **Inputs**
///    - `strings`: The list of strings to generate titles for.
///    - `languages`: An optional array of languages (ISO 639-1 format) for the generated titles. Defaults to English if not provided.
///    - `maxTokens`: Maximum tokens for the LLM response. Defaults to `100`.
/// - **Outputs**
///    - `titles`: A dictionary where keys are the original strings and values are dictionaries of generated titles keyed by language.
///    - `thoughts`: An array of strings containing the LLM's chain-of-thought entries, if any.
///    - `rawResponse`: The original unmodified raw response text from the LLM.
///
/// ### Use Cases
/// - Generate multilingual headlines for articles, blog posts, or content summaries.
/// - Suggest titles for user-generated content or creative works in different locales.
/// - Simplify and condense complex information into concise titles.
public class GenerateTitlesLLMTask: WorkflowComponentProtocol {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a new `GenerateTitlesLLMTask`.
    ///
    /// - Parameters:
    ///    - name: Optionally pass the name of the task.
    ///    - llmService: The LLM service to use for title generation.
    ///    - strings: The list of strings to generate titles for. Defaults to `nil` (can be resolved dynamically).
    ///    - languages: An optional array of languages (ISO 639-1 format) for the titles. Defaults to English if not provided.
    ///    - maxTokens: The maximum number of tokens for each title. Defaults to `100`.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(
        name: String? = nil,
        llmService: LLMServiceProtocol,
        strings: [String]? = nil,
        languages: [String]? = nil,
        maxTokens: Int = 500,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Generate succinct and informative titles for a list of strings using an LLM service.",
            inputs: inputs
        ) { inputs in
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []
            let resolvedLanguages = inputs.resolve(key: "languages", fallback: languages) ?? ["en"]
            let resolvedMaxTokens = inputs.resolve(key: "maxTokens", fallback: maxTokens)

            guard !resolvedStrings.isEmpty else {
                logger?.error("GenerateTitlesLLMTask [execute] No strings provided for title generation", category: "GenerateTitlesLLMTask")
                throw NSError(
                    domain: "GenerateTitlesLLMTask",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No strings provided for title generation."]
                )
            }

            let jsonInput: [String: Any] = [
                "texts": resolvedStrings,
                "languages": resolvedLanguages
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedStrings.joined(separator: "\n")

            // Build the prompt
            let prompt = """
            You are an expert editor. Generate a succinct, informative, and engaging title for each of the provided texts in the requested languages.

            Format the results as a single valid JSON object where:
            - Each key is an EXACT original text from the input.
            - Each value is a dictionary where keys are language codes and values are the generated titles.

            Expected Output JSON structure:
            {
              "original text 1": {
                "en": "Title in English",
                "es": "Título en Español"
              }
            }

            Important:
            1. Return ONLY the JSON object.
            2. Do not include markdown code fences (like ```json), explanations, or any other text.
            3. Generate titles for ALL texts and ALL languages provided in the input.

            Input data (JSON):
            \(jsonString)
            """

            let request = LLMRequest(
                messages: [
                    LLMMessage(role: .system, content: "You are a professional editor and title generation expert. You will receive a JSON object containing texts and requested languages. You MUST respond ONLY with a valid JSON object mapping original texts to their generated titles. No conversation, no thoughts, no markdown."),
                    LLMMessage(role: .user, content: prompt),
                ],
                maxTokens: resolvedMaxTokens
            )

            do {
                let response = try await llmService.sendRequest(request)

                let fullResponse = response.text
                let (thoughts, rawResponse) = fullResponse.extractThoughtsAndStripJSON()

                guard let data = rawResponse.data(using: .utf8),
                      let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    logger?.error("GenerateTitlesLLMTask [execute] Failed to parse JSON response: \(rawResponse)", category: "GenerateTitlesLLMTask")
                    throw NSError(
                        domain: "GenerateTitlesLLMTask",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response as JSON."]
                    )
                }

                // Handle both formats: wrapped in "titles" or direct mapping
                if let wrappedTitles = jsonResponse["titles"] {
                    return [
                        "titles": wrappedTitles,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                } else {
                    // Direct format - jsonResponse IS the titles
                    return [
                        "titles": jsonResponse,
                        "thoughts": thoughts,
                        "rawResponse": fullResponse,
                    ]
                }
            } catch {
                throw error
            }
        }
    }

    /// Converts this `GenerateTitlesLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
