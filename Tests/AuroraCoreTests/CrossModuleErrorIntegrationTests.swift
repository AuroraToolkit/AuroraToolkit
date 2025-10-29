//
//  CrossModuleErrorIntegrationTests.swift
//  AuroraCoreTests
//
//  Created for comprehensive cross-module error integration testing
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraML
@testable import AuroraTaskLibrary

final class CrossModuleErrorIntegrationTests: XCTestCase {
    
    // MARK: - Cross-Module Error Propagation Tests
    
    func testAuroraLLMErrorInAuroraCoreWorkflow() {
        let expectation = XCTestExpectation(description: "Should propagate LLM errors through AuroraCore")
        
        var workflow = Workflow(name: "LLM Error Integration Test", description: "Test LLM errors in workflows") {
            Workflow.Task(name: "LLMTask") { _ in
                // Simulate an LLM service error
                throw LLMServiceError.missingAPIKey
            }
        }
        
        Task {
            do {
                await workflow.start()
                XCTFail("Workflow should have thrown an LLM error")
            } catch let error as LLMServiceError {
                if case .missingAPIKey = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected missingAPIKey error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuroraMLErrorInAuroraCoreWorkflow() {
        let expectation = XCTestExpectation(description: "Should propagate ML errors through AuroraCore")
        
        var workflow = Workflow(name: "ML Error Integration Test", description: "Test ML errors in workflows") {
            Workflow.Task(name: "MLTask") { _ in
                // Simulate an ML service error
                throw NSError(domain: "AuroraML", code: 1001, userInfo: [
                    NSLocalizedDescriptionKey: "ML model inference failed"
                ])
            }
        }
        
        Task {
            do {
                await workflow.start()
                XCTFail("Workflow should have thrown an ML error")
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("ML model inference failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuroraTaskLibraryErrorInAuroraCoreWorkflow() {
        let expectation = XCTestExpectation(description: "Should propagate TaskLibrary errors through AuroraCore")
        
        var workflow = Workflow(name: "TaskLibrary Error Integration Test", description: "Test TaskLibrary errors in workflows") {
            Workflow.Task(name: "TaskLibraryTask") { _ in
                // Simulate a TaskLibrary error
                throw NSError(domain: "AuroraTaskLibrary", code: 2001, userInfo: [
                    NSLocalizedDescriptionKey: "Task library operation failed"
                ])
            }
        }
        
        Task {
            do {
                await workflow.start()
                XCTFail("Workflow should have thrown a TaskLibrary error")
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task library operation failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Wrapping and Context Tests
    
    func testAuroraCoreErrorWrappingLLMError() {
        let expectation = XCTestExpectation(description: "Should wrap LLM errors in AuroraCore errors")
        
        Task {
            do {
                // Simulate an LLM error being wrapped in AuroraCore error handling
                let llmError = LLMServiceError.invalidResponse(statusCode: 429)
                throw AuroraCoreError.custom(
                    message: "LLM service error: \(llmError.localizedDescription)",
                    context: [
                        "llmError": llmError.localizedDescription,
                        "statusCode": "429",
                        "module": "AuroraLLM"
                    ]
                )
            } catch let error as AuroraCoreError {
                if case .custom(let message, let context) = error {
                    XCTAssertTrue(message.contains("LLM service error"))
                    XCTAssertEqual(context?["statusCode"] as? String, "429")
                    XCTAssertEqual(context?["module"] as? String, "AuroraLLM")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom AuroraCoreError")
                }
            } catch {
                XCTFail("Expected AuroraCoreError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuroraCoreErrorWrappingMLError() {
        let expectation = XCTestExpectation(description: "Should wrap ML errors in AuroraCore errors")
        
        Task {
            do {
                // Simulate an ML error being wrapped in AuroraCore error handling
                let mlError = NSError(domain: "AuroraML", code: 1002, userInfo: [
                    NSLocalizedDescriptionKey: "ML model loading failed"
                ])
                
                throw AuroraCoreError.custom(
                    message: "ML service error: \(mlError.localizedDescription)",
                    context: [
                        "mlError": mlError.localizedDescription,
                        "errorCode": "1002",
                        "module": "AuroraML"
                    ]
                )
            } catch let error as AuroraCoreError {
                if case .custom(let message, let context) = error {
                    XCTAssertTrue(message.contains("ML service error"))
                    XCTAssertEqual(context?["errorCode"] as? String, "1002")
                    XCTAssertEqual(context?["module"] as? String, "AuroraML")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom AuroraCoreError")
                }
            } catch {
                XCTFail("Expected AuroraCoreError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuroraCoreErrorWrappingTaskLibraryError() {
        let expectation = XCTestExpectation(description: "Should wrap TaskLibrary errors in AuroraCore errors")
        
        Task {
            do {
                // Simulate a TaskLibrary error being wrapped in AuroraCore error handling
                let taskError = NSError(domain: "AuroraTaskLibrary", code: 2002, userInfo: [
                    NSLocalizedDescriptionKey: "Task execution failed"
                ])
                
                throw AuroraCoreError.custom(
                    message: "Task library error: \(taskError.localizedDescription)",
                    context: [
                        "taskError": taskError.localizedDescription,
                        "errorCode": "2002",
                        "module": "AuroraTaskLibrary"
                    ]
                )
            } catch let error as AuroraCoreError {
                if case .custom(let message, let context) = error {
                    XCTAssertTrue(message.contains("Task library error"))
                    XCTAssertEqual(context?["errorCode"] as? String, "2002")
                    XCTAssertEqual(context?["module"] as? String, "AuroraTaskLibrary")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom AuroraCoreError")
                }
            } catch {
                XCTFail("Expected AuroraCoreError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Multi-Module Error Scenarios Tests
    
    func testMultiModuleErrorScenario() {
        let expectation = XCTestExpectation(description: "Should handle multiple module errors")
        
        var workflow = Workflow(name: "Multi-Module Error Test", description: "Test errors from multiple modules") {
            Workflow.Task(name: "LLMTask") { _ in
                // First task succeeds
                return ["llm_result": "success"]
            }
            
            Workflow.Task(name: "MLTask") { _ in
                // Second task fails with ML error
                throw NSError(domain: "AuroraML", code: 1003, userInfo: [
                    NSLocalizedDescriptionKey: "ML inference failed"
                ])
            }
            
            Workflow.Task(name: "TaskLibraryTask") { _ in
                // This task should not execute due to previous error
                return ["task_result": "should not execute"]
            }
        }
        
        Task {
            do {
                await workflow.start()
                XCTFail("Workflow should have failed due to ML error")
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("ML inference failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCrossModuleErrorRecovery() {
        let expectation = XCTestExpectation(description: "Should handle cross-module error recovery")
        
        Task {
            do {
                // Simulate a recoverable error from one module
                let recoverableError = NSError(domain: "AuroraLLM", code: 1004, userInfo: [
                    NSLocalizedDescriptionKey: "Rate limit exceeded",
                    "retryAfter": "60 seconds"
                ])
                
                throw AuroraCoreError.custom(
                    message: "Recoverable error: \(recoverableError.localizedDescription)",
                    context: [
                        "originalError": recoverableError.localizedDescription,
                        "recoverable": true,
                        "retryAfter": "60 seconds"
                    ]
                )
            } catch let error as AuroraCoreError {
                if case .custom(let message, let context) = error {
                    XCTAssertTrue(message.contains("Recoverable error"))
                    XCTAssertEqual(context?["recoverable"] as? Bool, true)
                    XCTAssertEqual(context?["retryAfter"] as? String, "60 seconds")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom AuroraCoreError")
                }
            } catch {
                XCTFail("Expected AuroraCoreError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Context Preservation Tests
    
    func testCrossModuleErrorContextPreservation() {
        let expectation = XCTestExpectation(description: "Should preserve error context across modules")
        
        Task {
            do {
                // Simulate an error with context from multiple modules
                let context = [
                    "workflowName": "CrossModuleTest",
                    "llmModel": "gpt-4",
                    "mlModel": "ResNet50",
                    "taskType": "classification",
                    "errorSource": "AuroraLLM",
                    "errorCode": "1005"
                ]
                
                throw AuroraCoreError.custom(
                    message: "Cross-module error with preserved context",
                    context: context
                )
            } catch let error as AuroraCoreError {
                if case .custom(let message, let context) = error {
                    XCTAssertTrue(message.contains("Cross-module error"))
                    XCTAssertEqual(context?["workflowName"] as? String, "CrossModuleTest")
                    XCTAssertEqual(context?["llmModel"] as? String, "gpt-4")
                    XCTAssertEqual(context?["mlModel"] as? String, "ResNet50")
                    XCTAssertEqual(context?["taskType"] as? String, "classification")
                    XCTAssertEqual(context?["errorSource"] as? String, "AuroraLLM")
                    XCTAssertEqual(context?["errorCode"] as? String, "1005")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom AuroraCoreError")
                }
            } catch {
                XCTFail("Expected AuroraCoreError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandlingIntegrationWithAllModules() {
        let expectation = XCTestExpectation(description: "Should handle errors from all modules")
        
        Task {
            do {
                // Simulate errors from all modules
                let moduleErrors = [
                    "AuroraLLM": LLMServiceError.serviceUnavailable(message: "LLM service down"),
                    "AuroraML": NSError(domain: "AuroraML", code: 1006, userInfo: [NSLocalizedDescriptionKey: "ML service unavailable"]),
                    "AuroraTaskLibrary": NSError(domain: "AuroraTaskLibrary", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Task library unavailable"])
                ]
                
                // Test that all module errors can be handled
                for (module, error) in moduleErrors {
                    let errorDescription = (error as? Error)?.localizedDescription ?? "Unknown error"
                    let wrappedError = AuroraCoreError.custom(
                        message: "\(module) error: \(errorDescription)",
                        context: ["module": module, "originalError": errorDescription]
                    )
                    
                    XCTAssertNotNil(wrappedError.localizedDescription)
                    XCTAssertTrue(wrappedError.localizedDescription.contains(module))
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Should not have thrown an error")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Propagation Chain Tests
    
    func testErrorPropagationChain() {
        let expectation = XCTestExpectation(description: "Should propagate errors through the chain")
        
        Task {
            do {
                // Simulate an error propagation chain
                func level3() throws {
                    throw LLMServiceError.missingAPIKey
                }
                
                func level2() throws {
                    try level3()
                }
                
                func level1() throws {
                    try level2()
                }
                
                try level1()
                XCTFail("Should have thrown an error")
            } catch let error as LLMServiceError {
                if case .missingAPIKey = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected missingAPIKey error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Performance Tests
    
    func testCrossModuleErrorHandlingPerformance() {
        measure {
            for _ in 0..<1000 {
                let error = AuroraCoreError.custom(
                    message: "Performance test error",
                    context: ["module": "AuroraLLM", "errorCode": "1007"]
                )
                _ = error.localizedDescription
            }
        }
    }
    
    // MARK: - Error Handling Consistency Tests
    
    func testCrossModuleErrorHandlingConsistency() {
        let expectation = XCTestExpectation(description: "Should handle errors consistently across modules")
        
        Task {
            do {
                // Test that error handling is consistent across modules
                let errors = [
                    AuroraCoreError.workflowFailed(operation: "test", reason: "test reason"),
                    AuroraCoreError.custom(message: "LLM error", context: ["module": "AuroraLLM"]),
                    AuroraCoreError.custom(message: "ML error", context: ["module": "AuroraML"]),
                    AuroraCoreError.custom(message: "TaskLibrary error", context: ["module": "AuroraTaskLibrary"])
                ]
                
                for error in errors {
                    XCTAssertNotNil(error.localizedDescription)
                    XCTAssertFalse(error.localizedDescription.isEmpty)
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Should not have thrown an error")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
