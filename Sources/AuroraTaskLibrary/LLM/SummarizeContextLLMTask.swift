//
//  SummarizeContextLLMTask.swift
//
//
//  Created by Dan Murrell Jr on 9/2/24.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `SummarizeContextTask` is responsible for summarizing context items within a `ContextController` using the connected LLM service.
///
/// - **Inputs**
///    - `ContextController`: The context controller containing the context to be summarized.
///    - `SummaryType`: The type of summary to be performed (e.g., context, general text).
///    - `SummarizerOptions`: Additional summarizer configuration options (e.g. model, temperature).
/// - **Outputs**
///    - `summarizedContext`: The context containing the summarized content.
///
/// This task can be integrated in a workflow where context items need to be summarized.
public class SummarizeContextLLMTask: WorkflowComponent {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Optional logger for logging events and errors.
    private var logger: CustomLogger?

    /// Initializes a new `SummarizeContextLLMTask` instance.
    ///
    /// - Parameters:
    ///    - name: Optionally pass the name of the task.
    ///    - contextController: The `ContextController` instance containing the context to be summarized.
    ///    - summaryType: The type of summary to be performed (`single` or `multiple`).
    ///    - options: Optional `SummarizerOptions` to provide additional configuration options (e.g., model, temperature).
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional `CustomLogger` for logging events and errors.
    public init(
        name: String? = nil,
        contextController: ContextController,
        summaryType: SummaryType = .multiple,
        options: SummarizerOptions? = nil,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: "Summarize the content in the context controller",
            inputs: inputs
        ) { inputs in
            // Retrieve all context items to be summarized
            let itemsToSummarize = contextController.getItems().map { $0.text }

            // If there are no items, do nothing
            guard !itemsToSummarize.isEmpty else {
                logger?.debug("SummarizeContextLLMTask [execute] No context items to summarize", category: "SummarizeContextLLMTask")
                return [:]
            }

            /// Resolve the options from the inputs if it exists, otherwise use the provided `options` parameter or default
            let options = inputs.resolve(key: "options", fallback: options) ?? SummarizerOptions()

            // Summarize the items based on the summary type
            let summarizer = contextController.getSummarizer()
            switch summaryType {
            case .single:
                // Create a single combined summary
                let combinedSummary = try await summarizer.summarize(itemsToSummarize.joined(separator: "\n"), options: options, logger: logger)
                contextController.addItem(content: combinedSummary, isSummary: true)
                return ["summarizedContext": [combinedSummary]]

            case .multiple:
                // Create individual summaries for each item
                let summaries = try await summarizer.summarizeGroup(itemsToSummarize, type: .multiple, options: options, logger: logger)
                for summary in summaries {
                    contextController.addItem(content: summary, isSummary: true)
                }
                return ["summarizedContext": summaries]
            }
        }
    }

    /// Converts this `SummarizeContextLLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
