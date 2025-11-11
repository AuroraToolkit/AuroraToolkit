//
//  ErrorHandling.swift
//
//
//  Created on 10/26/25.
//

import Foundation

/// Utility functions for standardized error handling across Aurora modules
public struct ErrorHandling {
    
    /// Creates a standardized error with context information
    /// - Parameters:
    ///   - error: The underlying error
    ///   - operation: The operation that failed
    ///   - context: Additional context information (values will be converted to strings)
    /// - Returns: A standardized error with enhanced context
    public static func wrapError(
        _ error: Error,
        operation: String,
        context: [String: Any]? = nil
    ) -> AuroraCoreError {
        let reason = error.localizedDescription
        var enhancedContext: [String: String] = [:]
        
        // Convert context values to strings for Sendable compliance
        if let context = context {
            for (key, value) in context {
                enhancedContext[key] = String(describing: value)
            }
        }
        
        enhancedContext["underlyingError"] = error.localizedDescription
        enhancedContext["operation"] = operation
        
        return AuroraCoreError.custom(
            message: "\(operation) failed: \(reason)",
            context: enhancedContext
        )
    }
    
    /// Creates a standardized error for missing configuration
    /// - Parameters:
    ///   - configuration: The missing configuration item
    ///   - service: The service that requires the configuration
    /// - Returns: A standardized configuration error
    public static func missingConfiguration(
        _ configuration: String,
        for service: String
    ) -> AuroraCoreError {
        return AuroraCoreError.custom(
            message: "Missing \(configuration) for \(service)",
            context: [
                "missingConfiguration": configuration,
                "service": service,
                "suggestion": "Configure \(configuration) using the appropriate setup method"
            ]
        )
    }
    
    /// Creates a standardized error for invalid input
    /// - Parameters:
    ///   - input: The invalid input value
    ///   - expectedFormat: The expected format or type
    ///   - operation: The operation that received the invalid input
    /// - Returns: A standardized invalid input error
    public static func invalidInput(
        _ input: Any,
        expectedFormat: String,
        for operation: String
    ) -> AuroraCoreError {
        return AuroraCoreError.custom(
            message: "Invalid input for \(operation): expected \(expectedFormat), got \(type(of: input))",
            context: [
                "invalidInput": String(describing: input),
                "expectedFormat": expectedFormat,
                "operation": operation
            ]
        )
    }
    
    /// Creates a standardized error for service unavailability
    /// - Parameters:
    ///   - service: The unavailable service name
    ///   - reason: The reason for unavailability
    /// - Returns: A standardized service unavailability error
    public static func serviceUnavailable(
        _ service: String,
        reason: String
    ) -> AuroraCoreError {
        return AuroraCoreError.custom(
            message: "Service '\(service)' is unavailable: \(reason)",
            context: [
                "service": service,
                "reason": reason,
                "suggestion": "Check service status and configuration"
            ]
        )
    }
    
    /// Logs an error with standardized formatting
    /// - Parameters:
    ///   - error: The error to log
    ///   - logger: Optional logger instance
    ///   - category: Logging category
    public static func logError(
        _ error: Error,
        logger: CustomLogger? = nil,
        category: String = "ErrorHandling"
    ) {
        let errorMessage = formatError(error)
        logger?.error(errorMessage, category: category)
    }
    
    /// Formats an error for consistent display
    /// - Parameter error: The error to format
    /// - Returns: A formatted error string
    public static func formatError(_ error: Error) -> String {
        if let auroraError = error as? AuroraCoreError {
            var message = auroraError.localizedDescription
            if let failureReason = auroraError.failureReason {
                message += " (Reason: \(failureReason))"
            }
            if let recoverySuggestion = auroraError.recoverySuggestion {
                message += " (Suggestion: \(recoverySuggestion))"
            }
            return message
        } else {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    /// Determines if an error is recoverable
    /// - Parameter error: The error to check
    /// - Returns: True if the error is recoverable, false otherwise
    public static func isRecoverable(_ error: Error) -> Bool {
        if let auroraError = error as? AuroraCoreError {
            switch auroraError {
            case .workflowPaused:
                return true
            case .workflowCanceled:
                return false
            case .workflowFailed, .invalidWorkflowState, .taskExecutionFailed,
                 .inputResolutionFailed, .componentExecutionFailed,
                 .secureStorageFailed, .tokenHandlingFailed, .timingFailed,
                 .debuggingFailed, .contextFileManagementFailed, .custom:
                return false
            }
        }
        return false
    }
    
    /// Provides recovery suggestions for an error
    /// - Parameter error: The error to analyze
    /// - Returns: An array of recovery suggestions
    public static func getRecoverySuggestions(for error: Error) -> [String] {
        if let auroraError = error as? AuroraCoreError {
            if let suggestion = auroraError.recoverySuggestion {
                return [suggestion]
            }
        }
        return ["Review the error message and check system configuration"]
    }
}

// MARK: - Error Recovery Utilities

/// Retry configuration for error recovery
public struct RetryConfiguration {
    public let maxAttempts: Int
    public let delay: TimeInterval
    public let backoffMultiplier: Double
    
    public init(maxAttempts: Int = 3, delay: TimeInterval = 1.0, backoffMultiplier: Double = 2.0) {
        self.maxAttempts = maxAttempts
        self.delay = delay
        self.backoffMultiplier = backoffMultiplier
    }
}

/// Executes an operation with retry logic for recoverable errors
/// - Parameters:
///   - operation: The operation to execute
///   - configuration: Retry configuration
///   - isRecoverable: Function to determine if an error is recoverable
/// - Returns: The result of the operation
/// - Throws: The last error if all retries fail
public func executeWithRetry<T>(
    _ operation: () async throws -> T,
    configuration: RetryConfiguration = RetryConfiguration(),
    isRecoverable: (Error) -> Bool = ErrorHandling.isRecoverable
) async throws -> T {
    var lastError: Error?
    var currentDelay = configuration.delay
    
    for attempt in 1...configuration.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            if !isRecoverable(error) || attempt == configuration.maxAttempts {
                throw error
            }
            
            // Wait before retrying
            try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
            currentDelay *= configuration.backoffMultiplier
        }
    }
    
    throw lastError ?? AuroraCoreError.custom(message: "Retry operation failed")
}
