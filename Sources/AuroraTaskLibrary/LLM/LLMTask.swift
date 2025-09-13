//
//  LLMTask.swift
//
//
//  Created by Dan Murrell Jr on 9/1/24.
//

import AuroraCore
import AuroraLLM
import Foundation

/// `LLMTask` sends a prompt to a Large Language Model (LLM) service and returns a response.
///
/// - **Inputs**
///    - `llmRequest`: The request object containing the prompt and configuration for the LLM service.
/// - **Outputs**
///    - `response`: The response from the LLM service.
///
/// This task is designed to be part of a workflow where the result from an LLM is used in further tasks.
///
/// - Note: This class works with any service that conforms to `LLMServiceProtocol`.
public class LLMTask: WorkflowComponent {
    /// The wrapped task.
    private let task: Workflow.Task
    /// Logger for debugging and monitoring.
    private let logger: CustomLogger?

    /// Initializes a new `LLMTask`.
    ///
    /// - Parameters:
    ///    - name: The name of the task.
    ///    - description: A detailed description of the task.
    ///    - llmService: The LLM service that will handle the request.
    ///    - request: The `LLMRequest` containing the prompt and configuration for the LLM service.
    ///    - inputs: Additional inputs for the task. Defaults to an empty dictionary.
    ///    - logger: Optional logger for debugging and monitoring. Defaults to `nil`.
    ///
    /// - Note: The `inputs` array can contain direct values for keys like `request`, or dynamic references that will be resolved at runtime.
    public init(
        name: String? = nil,
        description: String? = nil,
        llmService: LLMServiceProtocol,
        request: LLMRequest? = nil,
        inputs: [String: Any?] = [:],
        logger: CustomLogger? = nil
    ) {
        self.logger = logger

        task = Workflow.Task(
            name: name ?? String(describing: Self.self),
            description: description ?? "Send a prompt to the LLM service",
            inputs: inputs
        ) { inputs in
            let resolvedRequest = inputs["request"] as? LLMRequest ?? request

            guard let request = resolvedRequest else {
                logger?.error("LLMTask [execute] No LLMRequest provided", category: "LLMTask")
                throw NSError(
                    domain: "LLMTask",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "LLMRequest is missing."]
                )
            }

            do {
                let response = try await llmService.sendRequest(request)
                return ["response": response.text]
            } catch {
                throw error
            }
        }
    }

    /// Converts this `LLMTask` to a `Workflow.Component`.
    public func toComponent() -> Workflow.Component {
        .task(task)
    }
}
