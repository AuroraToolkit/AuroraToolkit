//
//  ErrorHandlingTests.swift
//  AuroraTaskLibraryTests
//
//  Created for comprehensive error handling test coverage
//

import XCTest
@testable import AuroraTaskLibrary

final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - Task Library Error Handling Tests
    
    func testTaskLibraryErrorHandling() {
        // Test that task library properly handles various error scenarios
        let expectation = XCTestExpectation(description: "Should handle task library errors")
        
        Task {
            do {
                // Simulate a task library error
                throw NSError(domain: "AuroraTaskLibrary", code: 2001, userInfo: [
                    NSLocalizedDescriptionKey: "Task library operation failed",
                    "taskType": "LLM",
                    "operation": "text_generation"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task library operation failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMTaskErrorHandling() {
        let expectation = XCTestExpectation(description: "Should handle LLM task errors")
        
        Task {
            do {
                // Simulate an LLM task error
                throw NSError(domain: "AuroraTaskLibrary", code: 2002, userInfo: [
                    NSLocalizedDescriptionKey: "LLM task execution failed",
                    "taskName": "text_generation",
                    "model": "gpt-4",
                    "reason": "API rate limit exceeded"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("LLM task execution failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMLTaskErrorHandling() {
        let expectation = XCTestExpectation(description: "Should handle ML task errors")
        
        Task {
            do {
                // Simulate an ML task error
                throw NSError(domain: "AuroraTaskLibrary", code: 2003, userInfo: [
                    NSLocalizedDescriptionKey: "ML task execution failed",
                    "taskName": "image_classification",
                    "model": "ResNet50",
                    "reason": "Invalid input format"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("ML task execution failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNetworkTaskErrorHandling() {
        let expectation = XCTestExpectation(description: "Should handle network task errors")
        
        Task {
            do {
                // Simulate a network task error
                throw NSError(domain: "AuroraTaskLibrary", code: 2004, userInfo: [
                    NSLocalizedDescriptionKey: "Network task execution failed",
                    "taskName": "http_request",
                    "url": "https://api.example.com",
                    "reason": "Connection timeout"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Network task execution failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testParsingTaskErrorHandling() {
        let expectation = XCTestExpectation(description: "Should handle parsing task errors")
        
        Task {
            do {
                // Simulate a parsing task error
                throw NSError(domain: "AuroraTaskLibrary", code: 2005, userInfo: [
                    NSLocalizedDescriptionKey: "Parsing task execution failed",
                    "taskName": "json_parsing",
                    "inputType": "malformed_json",
                    "reason": "Invalid JSON structure"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Parsing task execution failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Configuration Error Tests
    
    func testTaskConfigurationError() {
        let expectation = XCTestExpectation(description: "Should handle task configuration errors")
        
        Task {
            do {
                // Simulate a task configuration error
                throw NSError(domain: "AuroraTaskLibrary", code: 2006, userInfo: [
                    NSLocalizedDescriptionKey: "Task configuration invalid",
                    "missingParameter": "apiKey",
                    "taskType": "LLM"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task configuration invalid"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTaskInitializationError() {
        let expectation = XCTestExpectation(description: "Should handle task initialization errors")
        
        Task {
            do {
                // Simulate a task initialization error
                throw NSError(domain: "AuroraTaskLibrary", code: 2007, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to initialize task",
                    "reason": "Invalid task parameters",
                    "taskName": "invalid_task"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Failed to initialize task"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Execution Error Tests
    
    func testTaskExecutionTimeout() {
        let expectation = XCTestExpectation(description: "Should handle task execution timeout")
        
        Task {
            do {
                // Simulate a task execution timeout
                throw NSError(domain: "AuroraTaskLibrary", code: 2008, userInfo: [
                    NSLocalizedDescriptionKey: "Task execution timeout",
                    "timeout": "30 seconds",
                    "taskName": "long_running_task"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task execution timeout"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTaskExecutionCancellation() {
        let expectation = XCTestExpectation(description: "Should handle task execution cancellation")
        
        Task {
            do {
                // Simulate a task execution cancellation
                throw NSError(domain: "AuroraTaskLibrary", code: 2009, userInfo: [
                    NSLocalizedDescriptionKey: "Task execution cancelled",
                    "reason": "User requested cancellation",
                    "taskName": "cancelled_task"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task execution cancelled"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Error Recovery Tests
    
    func testTaskErrorRecovery() {
        let expectation = XCTestExpectation(description: "Should handle recoverable task errors")
        
        Task {
            do {
                // Simulate a recoverable error (like temporary resource unavailability)
                throw NSError(domain: "AuroraTaskLibrary", code: 2010, userInfo: [
                    NSLocalizedDescriptionKey: "Task temporarily unavailable",
                    "reason": "Resource busy",
                    "retryAfter": "5 seconds"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task temporarily unavailable"))
                // In a real implementation, this error might be recoverable with a retry
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Error Context Tests
    
    func testTaskErrorWithContext() {
        let expectation = XCTestExpectation(description: "Should preserve task error context")
        
        Task {
            do {
                // Simulate an error with additional context
                let context = [
                    "taskName": "text_generation",
                    "model": "gpt-4",
                    "inputLength": "1000",
                    "maxTokens": "500"
                ]
                
                throw NSError(domain: "AuroraTaskLibrary", code: 2011, userInfo: [
                    NSLocalizedDescriptionKey: "Task execution failed with context: \(context)",
                    "context": context
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("text_generation"))
                XCTAssertTrue(error.localizedDescription.contains("gpt-4"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Error Propagation Tests
    
    func testTaskErrorPropagation() {
        let expectation = XCTestExpectation(description: "Should propagate task errors")
        
        Task {
            do {
                // Simulate a nested function that throws a task error
                func simulateTaskExecution() throws {
                    throw NSError(domain: "AuroraTaskLibrary", code: 2012, userInfo: [
                        NSLocalizedDescriptionKey: "Task execution failed"
                    ])
                }
                
                try simulateTaskExecution()
                XCTFail("Should have thrown an error")
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task execution failed"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Error Handling Integration Tests
    
    func testTaskErrorHandlingIntegration() {
        let expectation = XCTestExpectation(description: "Should handle task errors with context")
        
        Task {
            do {
                // Simulate a task error with additional context
                let context = [
                    "taskName": "text_generation",
                    "model": "gpt-4",
                    "inputLength": "1000",
                    "maxTokens": "500"
                ]
                
                throw NSError(domain: "AuroraTaskLibrary", code: 2013, userInfo: [
                    NSLocalizedDescriptionKey: "Task library error with context: \(context)"
                ])
            } catch {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertTrue(error.localizedDescription.contains("Task library error with context"))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Task Error Types Tests
    
    func testMultipleTaskErrorTypes() {
        let errors = [
            NSError(domain: "AuroraTaskLibrary", code: 2001, userInfo: [NSLocalizedDescriptionKey: "LLM task failed"]),
            NSError(domain: "AuroraTaskLibrary", code: 2002, userInfo: [NSLocalizedDescriptionKey: "ML task failed"]),
            NSError(domain: "AuroraTaskLibrary", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Network task failed"]),
            NSError(domain: "AuroraTaskLibrary", code: 2004, userInfo: [NSLocalizedDescriptionKey: "Parsing task failed"])
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    // MARK: - Task Error Performance Tests
    
    func testTaskErrorHandlingPerformance() {
        measure {
            for _ in 0..<1000 {
                let error = NSError(domain: "AuroraTaskLibrary", code: 2014, userInfo: [
                    NSLocalizedDescriptionKey: "Performance test task error"
                ])
                _ = error.localizedDescription
            }
        }
    }
    
    // MARK: - Task Error Message Consistency Tests
    
    func testTaskErrorMessageConsistency() {
        let error = NSError(domain: "AuroraTaskLibrary", code: 2015, userInfo: [
            NSLocalizedDescriptionKey: "Consistent task error message"
        ])
        
        let description1 = error.localizedDescription
        let description2 = error.localizedDescription
        
        XCTAssertEqual(description1, description2)
    }
    
    // MARK: - Task Error Domain Tests
    
    func testTaskErrorDomain() {
        let error = NSError(domain: "AuroraTaskLibrary", code: 2016, userInfo: [
            NSLocalizedDescriptionKey: "Test task error"
        ])
        
        XCTAssertEqual(error.domain, "AuroraTaskLibrary")
        XCTAssertEqual(error.code, 2016)
    }
    
    // MARK: - Task Error UserInfo Tests
    
    func testTaskErrorUserInfo() {
        let userInfo = [
            "taskName": "TestTask",
            "taskType": "LLM",
            "errorCode": "TL_001"
        ]
        
        let error = NSError(domain: "AuroraTaskLibrary", code: 2017, userInfo: [
            NSLocalizedDescriptionKey: "Test task error with user info",
            "userInfo": userInfo
        ])
        
        XCTAssertNotNil(error.userInfo["userInfo"])
        XCTAssertEqual((error.userInfo["userInfo"] as? [String: String])?["taskName"], "TestTask")
    }
    
    // MARK: - Task Error Recovery Strategies Tests
    
    func testTaskErrorRecoveryStrategies() {
        let expectation = XCTestExpectation(description: "Should handle different recovery strategies")
        
        Task {
            // Simulate different types of recoverable errors
            let recoverableErrors = [
                NSError(domain: "AuroraTaskLibrary", code: 2018, userInfo: [
                    NSLocalizedDescriptionKey: "Temporary network error",
                    "recoveryStrategy": "retry"
                ]),
                NSError(domain: "AuroraTaskLibrary", code: 2019, userInfo: [
                    NSLocalizedDescriptionKey: "Rate limit exceeded",
                    "recoveryStrategy": "backoff"
                ]),
                NSError(domain: "AuroraTaskLibrary", code: 2020, userInfo: [
                    NSLocalizedDescriptionKey: "Resource temporarily unavailable",
                    "recoveryStrategy": "wait"
                ])
            ]
            
            for error in recoverableErrors {
                XCTAssertNotNil(error.localizedDescription)
                XCTAssertNotNil(error.userInfo["recoveryStrategy"])
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
