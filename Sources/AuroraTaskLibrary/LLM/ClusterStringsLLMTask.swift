//
//  ClusterStringsLLMTask.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/1/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `ClusterStringsTask` groups strings into clusters based on semantic similarity, without requiring predefined categories.
///
/// - **Inputs**
///    - `strings`: The list of strings to cluster.
///    - `maxClusters`: Optional maximum number of clusters to create. If not provided, the LLM determines the optimal number dynamically.
/// - **Outputs**
///    - `clusters`: A dictionary where keys are cluster IDs or inferred names, and values are lists of strings belonging to each cluster.
///    - `thoughts`: An array of strings containing the LLM's chain-of-thought entries, if any.
///    - `rawResponse`: The original unmodified raw response text from the LLM.
///
/// ### Use Cases:
/// - **Customer Feedback Analysis**: Grouping customer reviews or feedback to identify trends.
/// - **Content Clustering**: Organizing blog posts, news articles, or research papers into topic-based clusters.
/// - **Unsupervised Data Exploration**: Automatically grouping strings for exploratory analysis when categories are unknown.
/// - **Semantic Deduplication**: Identifying and grouping similar strings to detect duplicates or near-duplicates.
///
/// ### Example:
/// **Input Strings:**
/// - "The stock market dropped today."
/// - "AI is transforming software development."
/// - "The S&P 500 index fell by 2%."
///
/// **Output JSON:**
/// ```
/// {
///   "Cluster 1": ["The stock market dropped today.", "The S&P 500 index fell by 2%."],
///   "Cluster 2": ["AI is transforming software development."]
/// }
/// ```
public class ClusterStringsLLMTask: WorkflowComponentProtocol {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a new `ClusterStringsLLMTask`.
    ///
    /// - Parameters:
    ///    - name: The name of the task.
    ///    - llmService: The LLM service used for clustering.
    ///    - strings: The list of strings to cluster.
    ///    - maxClusters: Optional maximum number of clusters to create.
    ///    - maxTokens: The maximum number of tokens to generate in the response. Defaults to 500.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    public init(
        name: String? = nil,
        llmService: LLMServiceProtocol,
        strings: [String]? = nil,
        maxClusters: Int? = nil,
        maxTokens: Int = 500,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Cluster strings into groups based on semantic similarity.",
            inputs: inputs
        ) { inputs in
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []
            guard !resolvedStrings.isEmpty else {
                logger?.error("ClusterStringsLLMTask [execute] No strings provided for clustering", category: "ClusterStringsLLMTask")
                throw NSError(
                    domain: "ClusterStringsLLMTask",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "No strings provided for clustering."]
                )
            }

            let resolvedMaxClusters = inputs.resolve(key: "maxClusters", fallback: maxClusters)

            let jsonInput: [String: Any] = [
                "strings": resolvedStrings,
                "maxClusters": resolvedMaxClusters as Any
            ]
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? resolvedStrings.joined(separator: "\n")

            let clusteringPrompt = """
            You are an expert data analyst. Cluster the provided list of strings based on semantic similarity.

            Format the results as a single valid JSON object where keys are cluster IDs (e.g., "Cluster 1", "Cluster 2") and values are arrays of strings belonging to each cluster.

            Expected Output JSON structure:
            {
              "Cluster 1": ["original string 1", "original string 2"],
              "Cluster 2": ["original string 3"]
            }

            Important:
            1. Return ONLY the JSON object.
            2. Do not include markdown code fences (like ```json), explanations, or any other text.
            3. Ensure ALL input strings are assigned to exactly one cluster.
            4. Do not modify the strings in any way (preserve punctuation and casing exactly).
            \(resolvedMaxClusters != nil ? "5. Limit the number of clusters to \(resolvedMaxClusters!)." : "")

            Input data (JSON):
            \(jsonString)
            """

            let request = LLMRequest(
                messages: [
                    LLMMessage(role: .system, content: "You are a professional data analysis expert. You will receive a JSON object containing strings to cluster. You MUST respond ONLY with a valid JSON object mapping cluster names to arrays of original strings. No conversation, no thoughts, no markdown."),
                    LLMMessage(role: .user, content: clusteringPrompt),
                ],
                maxTokens: maxTokens
            )

            do {
                let response = try await llmService.sendRequest(request)

                let fullResponse = response.text
                let (thoughts, rawResponse) = fullResponse.extractThoughtsAndStripJSON()

                guard let data = rawResponse.data(using: .utf8),
                      let clusters = try? JSONSerialization.jsonObject(with: data) as? [String: [String]]
                else {
                    logger?.error("ClusterStringsLLMTask [execute] Failed to parse JSON response: \(rawResponse)", category: "ClusterStringsLLMTask")
                    throw NSError(
                        domain: "ClusterStringsLLMTask",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response as JSON."]
                    )
                }
                return [
                    "clusters": clusters,
                    "thoughts": thoughts,
                    "rawResponse": fullResponse,
                ]
            } catch {
                throw error
            }
        }
    }

    /// Converts this `ClusterStringsLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
