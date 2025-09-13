//
//  SummarizeStringsLLMTask.swift
//  AuroraCore
//
//  Created by Dan Murrell Jr on 12/6/24.
//

import AuroraCore
import AuroraLLM
import Foundation

/// A task that summarizes a list of strings using the LLM service.
///
/// - **Inputs**
///    - `summarizer`: The summarizer to be used for the task.
///    - `summaryType`: The type of summary to be performed (e.g., context, general text).
///    - `SummarizerOptions`: Additional summarizer configuration options (e.g. model, temperature).
///    - `strings`: An array of strings to be summarized.
/// - **Outputs**
///    - `summaries`:  The list of summarized strings.
///
/// This task can be integrated in a workflow where context items need to be summarized.
public class SummarizeStringsLLMTask: WorkflowComponent {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a `SummarizeStringsTask` with the required parameters.
    ///
    /// - Parameters:
    ///    - name: Optionally pass the name of the task.
    ///    - summarizer: The summarizer to be used for the task.
    ///    - summaryType: The type of summary to be performed (e.g., context, general text).
    ///    - strings: The list of strings to be summarized.
    ///    - options: Optional `SummarizerOptions` to provide additional configuration options (e.g., model, temperature).
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    ///
    /// - Note: The `inputs` array can contain direct values for keys like `strings`, or dynamic references that will be resolved at runtime.
    public init(
        name: String? = nil,
        summarizer: SummarizerProtocol,
        summaryType: SummaryType,
        strings: [String]? = nil,
        options: SummarizerOptions? = SummarizerOptions(),
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Summarize a list of strings using the LLM service",
            inputs: inputs
        ) { inputs in
            let resolvedStrings = inputs.resolve(key: "strings", fallback: strings) ?? []

            guard !resolvedStrings.isEmpty else {
                logger?.error("SummarizeStringsLLMTask [execute] No strings provided for summarization", category: "SummarizeStringsLLMTask")
                throw NSError(domain: "SummarizeStringsLLMTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "No strings provided for summarization."])
            }

            let summaries = try await summarizer.summarizeGroup(resolvedStrings, type: summaryType, options: options, logger: logger)
            return ["summaries": summaries]
        }
    }

    /// Converts this `SummarizeStringsLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
