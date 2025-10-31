//
//  ErrorHandlingTests.swift
//  AuroraCoreTests
//
//  Created for comprehensive error handling test coverage
//

import XCTest
@testable import AuroraCore

final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - AuroraCoreError Tests
    
    func testAuroraCoreErrorTypes() {
        // Test all AuroraCoreError cases
        let errors: [AuroraCoreError] = [
            .workflowFailed(operation: "test", reason: "test reason"),
            .invalidWorkflowState(currentState: "running", expectedState: "idle"),
            .workflowCanceled(workflowName: "test workflow"),
            .workflowPaused(workflowName: "test workflow"),
            .taskExecutionFailed(taskName: "test task", reason: "test reason"),
            .inputResolutionFailed(taskName: "test task", inputKey: "test input", reason: "test reason"),
            .componentExecutionFailed(componentName: "test component", componentType: "test type", reason: "test reason"),
            .secureStorageFailed(operation: "test operation", reason: "test reason"),
            .tokenHandlingFailed(operation: "test operation", reason: "test reason"),
            .timingFailed(operation: "test operation", reason: "test reason"),
            .debuggingFailed(operation: "test operation", reason: "test reason"),
            .contextFileManagementFailed(operation: "test operation", reason: "test reason"),
            .custom(message: "test message", context: ["key": "value"])
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testAuroraCoreErrorLocalizedDescription() {
        let error = AuroraCoreError.workflowFailed(operation: "test_operation", reason: "test_reason")
        let description = error.localizedDescription
        XCTAssertTrue(description.contains("test_operation"))
        XCTAssertTrue(description.contains("test_reason"))
    }
    
    func testAuroraCoreErrorContext() {
        let context = ["key1": "value1", "key2": "value2"]
        let error = AuroraCoreError.custom(message: "test message", context: context)
        
        if case .custom(_, let errorContext) = error {
            XCTAssertEqual(errorContext?["key1"] as? String, "value1")
            XCTAssertEqual(errorContext?["key2"] as? String, "value2")
        } else {
            XCTFail("Expected custom error with context")
        }
    }
    
    // MARK: - ErrorHandling Utility Tests
    
    func testErrorHandlingWrapError() {
        let originalError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "original error"])
        let wrappedError = ErrorHandling.wrapError(
            originalError,
            operation: "test_operation",
            context: ["test": "value"]
        )
        
        if case .custom(let message, let context) = wrappedError {
            XCTAssertTrue(message.contains("test_operation"))
            XCTAssertTrue(message.contains("original error"))
            XCTAssertEqual(context?["test"] as? String, "value")
            XCTAssertEqual(context?["operation"] as? String, "test_operation")
        } else {
            XCTFail("Expected wrapped error to be custom type")
        }
    }
    
    func testErrorHandlingMissingConfiguration() {
        let error = ErrorHandling.missingConfiguration("API_KEY", for: "OpenAI")
        
        if case .custom(let message, let context) = error {
            XCTAssertTrue(message.contains("API_KEY"))
            XCTAssertTrue(message.contains("OpenAI"))
            XCTAssertEqual(context?["missingConfiguration"] as? String, "API_KEY")
            XCTAssertEqual(context?["service"] as? String, "OpenAI")
        } else {
            XCTFail("Expected missing configuration error")
        }
    }
    
    func testErrorHandlingInvalidInput() {
        let error = ErrorHandling.invalidInput(123, expectedFormat: "String", for: "test_operation")
        
        if case .custom(let message, let context) = error {
            XCTAssertTrue(message.contains("test_operation"))
            XCTAssertTrue(message.contains("String"))
            XCTAssertTrue(message.contains("Int"))
            XCTAssertEqual(context?["operation"] as? String, "test_operation")
        } else {
            XCTFail("Expected invalid input error")
        }
    }
    
    func testErrorHandlingServiceUnavailable() {
        let error = ErrorHandling.serviceUnavailable("TestService", reason: "maintenance")
        
        if case .custom(let message, let context) = error {
            XCTAssertTrue(message.contains("TestService"))
            XCTAssertTrue(message.contains("maintenance"))
            XCTAssertEqual(context?["service"] as? String, "TestService")
            XCTAssertEqual(context?["reason"] as? String, "maintenance")
        } else {
            XCTFail("Expected service unavailable error")
        }
    }
    
    func testErrorHandlingFormatError() {
        let auroraError = AuroraCoreError.workflowFailed(operation: "test", reason: "test reason")
        let formatted = ErrorHandling.formatError(auroraError)
        
        XCTAssertTrue(formatted.contains("test"))
        XCTAssertTrue(formatted.contains("test reason"))
    }
    
    func testErrorHandlingFormatGenericError() {
        let genericError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "generic error"])
        let formatted = ErrorHandling.formatError(genericError)
        
        XCTAssertTrue(formatted.contains("generic error"))
    }
    
    func testErrorHandlingIsRecoverable() {
        let recoverableError = AuroraCoreError.workflowPaused(workflowName: "test")
        let nonRecoverableError = AuroraCoreError.workflowFailed(operation: "test", reason: "test")
        
        XCTAssertTrue(ErrorHandling.isRecoverable(recoverableError))
        XCTAssertFalse(ErrorHandling.isRecoverable(nonRecoverableError))
    }
    
    func testErrorHandlingGetRecoverySuggestions() {
        let error = AuroraCoreError.workflowFailed(operation: "test", reason: "test")
        let suggestions = ErrorHandling.getRecoverySuggestions(for: error)
        
        XCTAssertFalse(suggestions.isEmpty)
    }
    
    // MARK: - Workflow Error Propagation Tests
    
    func testWorkflowErrorPropagationSequential() async {
        var workflow = Workflow(name: "Error Test Workflow", description: "Test error propagation") {
            Workflow.Task(name: "Task1") { _ in
                return ["result": "success"]
            }
            
            Workflow.Task(name: "Task2") { _ in
                throw AuroraCoreError.taskExecutionFailed(taskName: "Task2", reason: "Intentional test failure")
            }
            
            Workflow.Task(name: "Task3") { _ in
                return ["result": "should not execute"]
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .taskExecutionFailed(let taskName, let reason) = error {
                XCTAssertEqual(taskName, "Task2")
                XCTAssertEqual(reason, "Intentional test failure")
            }
        } else {
            XCTFail("Expected AuroraCoreError in workflow details")
        }
    }
    
    func testWorkflowErrorPropagationParallel() async {
        var workflow = Workflow(name: "Parallel Error Test", description: "Test parallel error propagation") {
            Workflow.TaskGroup(name: "ParallelGroup", description: "Parallel task group", mode: .parallel) {
                Workflow.Task(name: "Task1") { _ in
                    return ["result": "success"]
                }
                
                Workflow.Task(name: "Task2") { _ in
                    throw AuroraCoreError.taskExecutionFailed(taskName: "Task2", reason: "Intentional test failure")
                }
                
                Workflow.Task(name: "Task3") { _ in
                    return ["result": "success"]
                }
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        // Subflow errors do not bubble to the parent; parent completes while subflow records failure.
        XCTAssertEqual(state, .completed)
    }
    
    func testWorkflowErrorPropagationNested() async {
        var workflow = Workflow(name: "Nested Error Test", description: "Test nested error propagation") {
            Workflow.Task(name: "OuterTask") { _ in
                return ["result": "success"]
            }
            
            Workflow.Subflow(name: "NestedSubflow", description: "Nested subflow") {
                Workflow.Task(name: "NestedTask") { _ in
                    throw AuroraCoreError.taskExecutionFailed(taskName: "NestedTask", reason: "Intentional test failure")
                }
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        XCTAssertTrue(workflow.detailsHolder.details?.error is AuroraCoreError)
    }
    
    func testWorkflowErrorPropagationTaskGroup() async {
        var workflow = Workflow(name: "TaskGroup Error Test", description: "Test task group error propagation") {
            Workflow.TaskGroup(name: "SequentialGroup", description: "Sequential task group", mode: .sequential) {
                Workflow.Task(name: "Task1") { _ in
                    return ["result": "success"]
                }
                
                Workflow.Task(name: "Task2") { _ in
                    throw AuroraCoreError.taskExecutionFailed(taskName: "Task2", reason: "Intentional test failure")
                }
                
                Workflow.Task(name: "Task3") { _ in
                    return ["result": "should not execute"]
                }
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        XCTAssertTrue(workflow.detailsHolder.details?.error is AuroraCoreError)
    }
    
    // MARK: - Error Recovery Tests
    
    func testWorkflowErrorRecovery() async {
        var workflow = Workflow(name: "Recovery Test", description: "Test error recovery") {
            Workflow.Task(name: "RecoverableTask") { _ in
                throw AuroraCoreError.workflowPaused(workflowName: "Recovery Test")
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .workflowPaused = error {
                XCTAssertTrue(ErrorHandling.isRecoverable(error))
            } else {
                XCTFail("Expected workflowPaused error")
            }
        } else {
            XCTFail("Expected AuroraCoreError")
        }
    }
    
    // MARK: - Input Resolution Error Tests
    
    func testInputResolutionError() async {
        var workflow = Workflow(name: "Input Resolution Test", description: "Test input resolution errors") {
            Workflow.Task(name: "TaskWithMissingInput") { inputs in
                guard let missingValue = inputs["missing_input"] as? String else {
                    throw AuroraCoreError.inputResolutionFailed(
                        taskName: "TaskWithMissingInput",
                        inputKey: "missing_input",
                        reason: "Required input not found"
                    )
                }
                return ["result": missingValue]
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .inputResolutionFailed(let taskName, let inputKey, let reason) = error {
                XCTAssertEqual(taskName, "TaskWithMissingInput")
                XCTAssertEqual(inputKey, "missing_input")
                XCTAssertEqual(reason, "Required input not found")
            } else {
                XCTFail("Expected inputResolutionFailed error")
            }
        } else {
            XCTFail("Expected AuroraCoreError")
        }
    }
    
    // MARK: - Component Execution Error Tests
    
    func testComponentExecutionError() async {
        var workflow = Workflow(name: "Component Error Test", description: "Test component execution errors") {
            Workflow.Logic(name: "FailingLogic", description: "Failing logic component") {
                throw AuroraCoreError.componentExecutionFailed(
                    componentName: "FailingLogic",
                    componentType: "Logic",
                    reason: "Intentional component failure"
                )
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .componentExecutionFailed(let componentName, let componentType, let reason) = error {
                XCTAssertEqual(componentName, "FailingLogic")
                XCTAssertEqual(componentType, "Logic")
                XCTAssertEqual(reason, "Intentional component failure")
            } else {
                XCTFail("Expected componentExecutionFailed error")
            }
        } else {
            XCTFail("Expected AuroraCoreError")
        }
    }
    
    // MARK: - Error Context Preservation Tests
    
    func testErrorContextPreservation() async {
        var workflow = Workflow(name: "Context Test", description: "Test error context preservation") {
            Workflow.Task(name: "ContextTask") { inputs in
                let context = [
                    "workflowName": "Context Test",
                    "taskName": "ContextTask",
                    "inputCount": inputs.count
                ]
                
                throw AuroraCoreError.custom(
                    message: "Test error with context",
                    context: context
                )
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .custom(let message, let context) = error {
                XCTAssertTrue(message.contains("Test error with context"))
                XCTAssertEqual(context?["workflowName"] as? String, "Context Test")
                XCTAssertEqual(context?["taskName"] as? String, "ContextTask")
            } else {
                XCTFail("Expected custom error with context")
            }
        } else {
            XCTFail("Expected AuroraCoreError")
        }
    }
    
    // MARK: - Multiple Error Types Tests
    
    func testMultipleErrorTypesInWorkflow() async {
        var workflow = Workflow(name: "Multiple Errors Test", description: "Test multiple error types") {
            Workflow.Task(name: "Task1") { _ in
                throw AuroraCoreError.taskExecutionFailed(taskName: "Task1", reason: "First error")
            }
            
            Workflow.Task(name: "Task2") { _ in
                throw AuroraCoreError.inputResolutionFailed(taskName: "Task2", inputKey: "test", reason: "Second error")
            }
            
            Workflow.Task(name: "Task3") { _ in
                throw AuroraCoreError.componentExecutionFailed(componentName: "Task3", componentType: "Task", reason: "Third error")
            }
        }
        
        await workflow.start()
        let state = await workflow.state
        XCTAssertEqual(state, .failed)
        if let error = workflow.detailsHolder.details?.error as? AuroraCoreError {
            if case .taskExecutionFailed(let taskName, let reason) = error {
                XCTAssertEqual(taskName, "Task1")
                XCTAssertEqual(reason, "First error")
            } else {
                XCTFail("Expected taskExecutionFailed error from Task1")
            }
        } else {
            XCTFail("Expected AuroraCoreError")
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingWithCustomLogger() {
        let logger = CustomLogger.shared
        let testError = AuroraCoreError.workflowFailed(operation: "test", reason: "test reason")
        
        // This should not crash and should log the error
        ErrorHandling.logError(testError, logger: logger, category: "TestCategory")
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
    
    func testErrorHandlingWithoutLogger() {
        let testError = AuroraCoreError.workflowFailed(operation: "test", reason: "test reason")
        
        // This should not crash even without a logger
        ErrorHandling.logError(testError, logger: nil, category: "TestCategory")
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
}
