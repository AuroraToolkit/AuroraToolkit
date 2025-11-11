//
//  AuroraCoreError.swift
//
//
//  Created on 10/26/25.
//

import Foundation

/// `AuroraCoreError` defines a comprehensive set of error types that can occur within AuroraCore operations.
/// These errors provide detailed information about failure points and support proper error handling.
///
/// Conforms to `Sendable` for Swift 6 concurrency safety. The `custom` case uses `[String: String]` for context
/// to ensure all associated values are Sendable-safe.
public enum AuroraCoreError: Error, LocalizedError, Sendable {
    /// Error thrown when a workflow operation fails.
    case workflowFailed(operation: String, reason: String)
    
    /// Error thrown when a workflow is in an invalid state for the requested operation.
    case invalidWorkflowState(currentState: String, expectedState: String)
    
    /// Error thrown when a workflow is canceled during execution.
    case workflowCanceled(workflowName: String)
    
    /// Error thrown when a workflow is paused and cannot proceed.
    case workflowPaused(workflowName: String)
    
    /// Error thrown when a task execution fails.
    case taskExecutionFailed(taskName: String, reason: String)
    
    /// Error thrown when task inputs cannot be resolved.
    case inputResolutionFailed(taskName: String, inputKey: String, reason: String)
    
    /// Error thrown when a component cannot be executed.
    case componentExecutionFailed(componentName: String, componentType: String, reason: String)
    
    /// Error thrown when secure storage operations fail.
    case secureStorageFailed(operation: String, reason: String)
    
    /// Error thrown when token handling operations fail.
    case tokenHandlingFailed(operation: String, reason: String)
    
    /// Error thrown when timing operations fail.
    case timingFailed(operation: String, reason: String)
    
    /// Error thrown when debugging operations fail.
    case debuggingFailed(operation: String, reason: String)
    
    /// Error thrown when context file management operations fail.
    case contextFileManagementFailed(operation: String, reason: String)
    
    /// Custom error type for providing more descriptive error messages.
    /// - Note: Context values must be strings for Sendable compliance. Use `String(describing:)` to convert other types.
    case custom(message: String, context: [String: String]? = nil)
    
    public var errorDescription: String? {
        switch self {
        case .workflowFailed(let operation, let reason):
            return "Workflow operation '\(operation)' failed: \(reason)"
        case .invalidWorkflowState(let currentState, let expectedState):
            return "Invalid workflow state: current '\(currentState)', expected '\(expectedState)'"
        case .workflowCanceled(let workflowName):
            return "Workflow '\(workflowName)' was canceled"
        case .workflowPaused(let workflowName):
            return "Workflow '\(workflowName)' is paused and cannot proceed"
        case .taskExecutionFailed(let taskName, let reason):
            return "Task '\(taskName)' execution failed: \(reason)"
        case .inputResolutionFailed(let taskName, let inputKey, let reason):
            return "Failed to resolve input '\(inputKey)' for task '\(taskName)': \(reason)"
        case .componentExecutionFailed(let componentName, let componentType, let reason):
            return "\(componentType) component '\(componentName)' execution failed: \(reason)"
        case .secureStorageFailed(let operation, let reason):
            return "Secure storage operation '\(operation)' failed: \(reason)"
        case .tokenHandlingFailed(let operation, let reason):
            return "Token handling operation '\(operation)' failed: \(reason)"
        case .timingFailed(let operation, let reason):
            return "Timing operation '\(operation)' failed: \(reason)"
        case .debuggingFailed(let operation, let reason):
            return "Debugging operation '\(operation)' failed: \(reason)"
        case .contextFileManagementFailed(let operation, let reason):
            return "Context file management operation '\(operation)' failed: \(reason)"
        case .custom(let message, let context):
            if let context = context, !context.isEmpty {
                let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                return "\(message) (Context: \(contextString))"
            }
            return message
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .workflowFailed(_, let reason),
             .taskExecutionFailed(_, let reason),
             .inputResolutionFailed(_, _, let reason),
             .componentExecutionFailed(_, _, let reason),
             .secureStorageFailed(_, let reason),
             .tokenHandlingFailed(_, let reason),
             .timingFailed(_, let reason),
             .debuggingFailed(_, let reason),
             .contextFileManagementFailed(_, let reason):
            return reason
        case .invalidWorkflowState(let currentState, let expectedState):
            return "Expected state '\(expectedState)' but found '\(currentState)'"
        case .workflowCanceled(let workflowName):
            return "Workflow '\(workflowName)' was canceled by user or system"
        case .workflowPaused(let workflowName):
            return "Workflow '\(workflowName)' is paused and waiting for resume"
        case .custom(let message, _):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .workflowFailed:
            return "Check workflow configuration and ensure all required inputs are provided"
        case .invalidWorkflowState:
            return "Ensure workflow is in the correct state before performing the operation"
        case .workflowCanceled:
            return "Restart the workflow if cancellation was unintentional"
        case .workflowPaused:
            return "Resume the workflow using the resume() method"
        case .taskExecutionFailed:
            return "Check task implementation and ensure all dependencies are met"
        case .inputResolutionFailed:
            return "Verify input keys exist in workflow outputs and check dynamic reference syntax"
        case .componentExecutionFailed:
            return "Check component configuration and ensure all required parameters are provided"
        case .secureStorageFailed:
            return "Check keychain access permissions and ensure the service name is valid"
        case .tokenHandlingFailed:
            return "Verify input text and token limits are reasonable"
        case .timingFailed:
            return "Check system clock and timing configuration"
        case .debuggingFailed:
            return "Check logging configuration and file system permissions"
        case .contextFileManagementFailed:
            return "Check file system permissions and ensure the context directory exists"
        case .custom:
            return "Review the error context and check system configuration"
        }
    }
}

// MARK: - Error Code Constants

/// Standardized error codes for AuroraCore operations
public struct AuroraCoreErrorCode {
    public static let workflowFailed = 1000
    public static let invalidWorkflowState = 1001
    public static let workflowCanceled = 1002
    public static let workflowPaused = 1003
    public static let taskExecutionFailed = 1004
    public static let inputResolutionFailed = 1005
    public static let componentExecutionFailed = 1006
    public static let secureStorageFailed = 1007
    public static let tokenHandlingFailed = 1008
    public static let timingFailed = 1009
    public static let debuggingFailed = 1010
    public static let contextFileManagementFailed = 1011
    public static let custom = 1099
}
