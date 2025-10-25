//
//  AuroraCoreConvenience.swift
//  AuroraCore
//
//  Created on 1/15/25.
//

import Foundation

/// Convenience APIs for AuroraCore to simplify common workflow and task creation patterns.
///
/// This module provides simplified APIs that reduce boilerplate while maintaining the full power
/// of the AuroraCore workflow system. It follows the same "simple surface, powerful engine" 
/// philosophy as Apple's FoundationModels SDK.
public struct AuroraCore {
    
    // MARK: - Workflow Convenience APIs
    
    /// Creates a simple workflow with minimal boilerplate.
    ///
    /// - Parameters:
    ///   - name: The name of the workflow
    ///   - description: Optional description (defaults to empty string)
    ///   - logger: Optional logger (defaults to nil)
    ///   - content: The workflow builder content
    /// - Returns: A configured Workflow instance
    public static func workflow(
        _ name: String,
        description: String = "",
        logger: CustomLogger? = nil,
        @WorkflowBuilder _ content: () -> [Workflow.Component]
    ) -> Workflow {
        return Workflow(name: name, description: description, logger: logger, content)
    }
    
    /// Creates a simple workflow with automatic naming.
    ///
    /// - Parameters:
    ///   - description: Optional description (defaults to empty string)
    ///   - logger: Optional logger (defaults to nil)
    ///   - content: The workflow builder content
    /// - Returns: A configured Workflow instance with auto-generated name
    public static func workflow(
        description: String = "",
        logger: CustomLogger? = nil,
        @WorkflowBuilder _ content: () -> [Workflow.Component]
    ) -> Workflow {
        let name = "Workflow_\(UUID().uuidString.prefix(8))"
        return Workflow(name: name, description: description, logger: logger, content)
    }
    
    // MARK: - Task Convenience APIs
    
    /// Creates a simple task with minimal boilerplate.
    ///
    /// - Parameters:
    ///   - name: The name of the task
    ///   - description: Optional description (defaults to empty string)
    ///   - inputs: Optional inputs dictionary
    ///   - executeBlock: The task execution logic
    /// - Returns: A configured Workflow.Task instance
    public static func task(
        _ name: String,
        description: String = "",
        inputs: [String: Any?] = [:],
        execute: @escaping ([String: Any]) async throws -> [String: Any]
    ) -> Workflow.Task {
        return Workflow.Task(
            name: name,
            description: description,
            inputs: inputs,
            executeBlock: execute
        )
    }
    
    /// Creates a simple task with automatic naming.
    ///
    /// - Parameters:
    ///   - description: Optional description (defaults to empty string)
    ///   - inputs: Optional inputs dictionary
    ///   - executeBlock: The task execution logic
    /// - Returns: A configured Workflow.Task instance with auto-generated name
    public static func task(
        description: String = "",
        inputs: [String: Any?] = [:],
        execute: @escaping ([String: Any]) async throws -> [String: Any]
    ) -> Workflow.Task {
        let name = "Task_\(UUID().uuidString.prefix(8))"
        return Workflow.Task(
            name: name,
            description: description,
            inputs: inputs,
            executeBlock: execute
        )
    }
    
    // MARK: - Common Workflow Patterns
    
    // Note: Array-based workflow patterns are not implemented due to WorkflowBuilder limitations.
    // Users can create sequential workflows by listing tasks directly in the builder.
    // Users can create parallel workflows by using Workflow.TaskGroup directly.
    
    // MARK: - Utility Functions
    
    /// Creates a simple delay task for workflow timing.
    ///
    /// - Parameters:
    ///   - duration: The delay duration in seconds
    ///   - name: Optional task name
    /// - Returns: A configured Workflow.Task that delays execution
    public static func delay(
        _ duration: TimeInterval,
        name: String? = nil
    ) -> Workflow.Task {
        let taskName = name ?? "Delay_\(Int(duration))s"
        return Workflow.Task(name: taskName, description: "Delay execution for \(duration) seconds") { _ in
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            return ["delay_completed": true, "duration": duration]
        }
    }
    
    /// Creates a simple print task for debugging workflows.
    ///
    /// - Parameters:
    ///   - message: The message to print
    ///   - name: Optional task name
    /// - Returns: A configured Workflow.Task that prints a message
    public static func print(
        _ message: String,
        name: String? = nil
    ) -> Workflow.Task {
        let taskName = name ?? "Print_\(UUID().uuidString.prefix(4))"
        return Workflow.Task(name: taskName, description: "Print message: \(message)") { _ in
            print(message)
            return ["message_printed": message]
        }
    }
    
    /// Creates a simple conditional task for workflow logic.
    ///
    /// - Parameters:
    ///   - name: The name of the conditional task
    ///   - condition: The condition to evaluate
    ///   - trueTask: Task to execute if condition is true
    ///   - falseTask: Optional task to execute if condition is false
    /// - Returns: A configured Workflow.Logic component
    public static func conditional(
        _ name: String,
        condition: @escaping () -> Bool,
        trueTask: Workflow.Task,
        falseTask: Workflow.Task? = nil
    ) -> Workflow.Logic {
        return Workflow.Logic(name: name, description: "Conditional execution") {
            if condition() {
                return [trueTask.toComponent()]
            } else if let falseTask = falseTask {
                return [falseTask.toComponent()]
            } else {
                return []
            }
        }
    }
}

// MARK: - Workflow Extensions

extension Workflow {
    /// Convenience method to start a workflow and return its outputs.
    ///
    /// - Returns: The workflow outputs after completion
    /// - Throws: Any error that occurred during workflow execution
    public mutating func run() async throws -> [String: Any] {
        await start()
        return outputs
    }
    
    /// Convenience method to start a workflow and return a specific output.
    ///
    /// - Parameter key: The output key to retrieve
    /// - Returns: The specific output value, or nil if not found
    /// - Throws: Any error that occurred during workflow execution
    public mutating func run<T>(output key: String) async throws -> T? {
        await start()
        return outputs[key] as? T
    }
}
