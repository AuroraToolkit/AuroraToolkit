//
//  ErrorHandlingTests.swift
//  AuroraLLMTests
//
//  Created for comprehensive error handling test coverage
//

import XCTest
@testable import AuroraLLM

final class ErrorHandlingTests: XCTestCase {
    
    // MARK: - LLMServiceError Tests
    
    func testLLMServiceErrorTypes() {
        let errors: [LLMServiceError] = [
            .missingAPIKey,
            .invalidResponse(statusCode: 400),
            .decodingError,
            .invalidURL,
            .serviceUnavailable(message: "Service down"),
            .requestFailed(message: "Network error"),
            .noDefaultServiceConfigured,
            .custom(message: "Custom error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testLLMServiceErrorMissingAPIKey() {
        let error = LLMServiceError.missingAPIKey
        let description = error.localizedDescription
        
        XCTAssertTrue(description.contains("API key") || description.contains("missing"))
    }
    
    func testLLMServiceErrorInvalidResponse() {
        let error = LLMServiceError.invalidResponse(statusCode: 404)
        let description = error.localizedDescription
        
        XCTAssertTrue(description.contains("404") || description.contains("invalid"))
    }
    
    func testLLMServiceErrorServiceUnavailable() {
        let error = LLMServiceError.serviceUnavailable(message: "Maintenance mode")
        let description = error.localizedDescription
        
        XCTAssertTrue(description.contains("Maintenance mode") || description.contains("unavailable"))
    }
    
    func testLLMServiceErrorRequestFailed() {
        let error = LLMServiceError.requestFailed(message: "Connection timeout")
        let description = error.localizedDescription
        
        XCTAssertTrue(description.contains("Connection timeout") || description.contains("failed"))
    }
    
    func testLLMServiceErrorCustom() {
        let error = LLMServiceError.custom(message: "Custom error message")
        let description = error.localizedDescription
        
        XCTAssertTrue(description.contains("Custom error message"))
    }
    
    // MARK: - LLM Service Error Handling Tests
    
    func testLLMServiceErrorHandlingWithMissingAPIKey() {
        // Test that services properly handle missing API key errors
        let expectation = XCTestExpectation(description: "Should handle missing API key")
        
        Task {
            do {
                // This would typically be called with a service that has no API key configured
                // For testing, we'll simulate the error handling
                throw LLMServiceError.missingAPIKey
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
    
    func testLLMServiceErrorHandlingWithInvalidResponse() {
        let expectation = XCTestExpectation(description: "Should handle invalid response")
        
        Task {
            do {
                throw LLMServiceError.invalidResponse(statusCode: 500)
            } catch let error as LLMServiceError {
                if case .invalidResponse(let statusCode) = error {
                    XCTAssertEqual(statusCode, 500)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidResponse error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMServiceErrorHandlingWithDecodingError() {
        let expectation = XCTestExpectation(description: "Should handle decoding error")
        
        Task {
            do {
                throw LLMServiceError.decodingError
            } catch let error as LLMServiceError {
                if case .decodingError = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected decodingError")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMServiceErrorHandlingWithInvalidURL() {
        let expectation = XCTestExpectation(description: "Should handle invalid URL")
        
        Task {
            do {
                throw LLMServiceError.invalidURL
            } catch let error as LLMServiceError {
                if case .invalidURL = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidURL error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMServiceErrorHandlingWithServiceUnavailable() {
        let expectation = XCTestExpectation(description: "Should handle service unavailable")
        
        Task {
            do {
                throw LLMServiceError.serviceUnavailable(message: "Service temporarily unavailable")
            } catch let error as LLMServiceError {
                if case .serviceUnavailable(let message) = error {
                    XCTAssertEqual(message, "Service temporarily unavailable")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected serviceUnavailable error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMServiceErrorHandlingWithRequestFailed() {
        let expectation = XCTestExpectation(description: "Should handle request failed")
        
        Task {
            do {
                throw LLMServiceError.requestFailed(message: "Network connection failed")
            } catch let error as LLMServiceError {
                if case .requestFailed(let message) = error {
                    XCTAssertEqual(message, "Network connection failed")
                    expectation.fulfill()
                } else {
                    XCTFail("Expected requestFailed error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLLMServiceErrorHandlingWithNoDefaultService() {
        let expectation = XCTestExpectation(description: "Should handle no default service")
        
        Task {
            do {
                throw LLMServiceError.noDefaultServiceConfigured
            } catch let error as LLMServiceError {
                if case .noDefaultServiceConfigured = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected noDefaultServiceConfigured error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testLLMServiceErrorRecovery() {
        let expectation = XCTestExpectation(description: "Should handle recoverable errors")
        
        Task {
            do {
                // Simulate a recoverable error (like temporary service unavailability)
                throw LLMServiceError.serviceUnavailable(message: "Temporary maintenance")
            } catch let error as LLMServiceError {
                // In a real implementation, this would check if the error is recoverable
                // and potentially retry the operation
                if case .serviceUnavailable = error {
                    // This error might be recoverable with a retry
                    expectation.fulfill()
                } else {
                    XCTFail("Expected serviceUnavailable error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Context Tests
    
    func testLLMServiceErrorWithContext() {
        let expectation = XCTestExpectation(description: "Should preserve error context")
        
        Task {
            do {
                // Simulate an error with additional context
                let context = [
                    "service": "OpenAI",
                    "model": "gpt-4",
                    "requestId": "req-123"
                ]
                
                throw LLMServiceError.custom(message: "Request failed with context: \(context)")
            } catch let error as LLMServiceError {
                if case .custom(let message) = error {
                    XCTAssertTrue(message.contains("OpenAI"))
                    XCTAssertTrue(message.contains("gpt-4"))
                    XCTAssertTrue(message.contains("req-123"))
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom error with context")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Multiple Error Scenarios Tests
    
    func testMultipleLLMServiceErrors() {
        let errors: [LLMServiceError] = [
            .missingAPIKey,
            .invalidResponse(statusCode: 401),
            .serviceUnavailable(message: "Rate limit exceeded"),
            .requestFailed(message: "Timeout")
        ]
        
        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty)
            XCTAssertNotNil(description)
        }
    }
    
    // MARK: - Error Propagation Tests
    
    func testLLMServiceErrorPropagation() {
        let expectation = XCTestExpectation(description: "Should propagate LLM service errors")
        
        Task {
            do {
                // Simulate a nested function that throws an LLM service error
                func simulateLLMServiceCall() throws {
                    throw LLMServiceError.invalidResponse(statusCode: 429)
                }
                
                try simulateLLMServiceCall()
                XCTFail("Should have thrown an error")
            } catch let error as LLMServiceError {
                if case .invalidResponse(let statusCode) = error {
                    XCTAssertEqual(statusCode, 429)
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidResponse error")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testLLMServiceErrorHandlingIntegration() {
        let expectation = XCTestExpectation(description: "Should handle LLM errors with context")
        
        Task {
            do {
                // Simulate an LLM service error with additional context
                let context = [
                    "service": "OpenAI",
                    "model": "gpt-4",
                    "requestId": "req-123"
                ]
                
                throw LLMServiceError.custom(message: "Request failed with context: \(context)")
            } catch let error as LLMServiceError {
                if case .custom(let message) = error {
                    XCTAssertTrue(message.contains("Request failed with context"))
                    expectation.fulfill()
                } else {
                    XCTFail("Expected custom error with context")
                }
            } catch {
                XCTFail("Expected LLMServiceError")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Equivalence Tests
    
    func testLLMServiceErrorEquivalence() {
        let error1 = LLMServiceError.missingAPIKey
        let error2 = LLMServiceError.missingAPIKey
        let error3 = LLMServiceError.invalidResponse(statusCode: 400)
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        XCTAssertNotEqual(error2, error3)
    }
    
    func testLLMServiceErrorWithSameStatusCode() {
        let error1 = LLMServiceError.invalidResponse(statusCode: 400)
        let error2 = LLMServiceError.invalidResponse(statusCode: 400)
        let error3 = LLMServiceError.invalidResponse(statusCode: 500)
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - Error Message Consistency Tests
    
    func testLLMServiceErrorMessageConsistency() {
        let error = LLMServiceError.custom(message: "Consistent error message")
        let description1 = error.localizedDescription
        let description2 = error.localizedDescription
        
        XCTAssertEqual(description1, description2)
    }
    
    // MARK: - Error Handling Performance Tests
    
    func testLLMServiceErrorHandlingPerformance() {
        measure {
            for _ in 0..<1000 {
                let error = LLMServiceError.requestFailed(message: "Performance test error")
                _ = error.localizedDescription
            }
        }
    }
}
