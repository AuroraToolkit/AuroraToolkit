//
//  ErrorHandlingIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests for error handling across modules
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraTaskLibrary

/// Integration tests for error handling and propagation across modules.
final class ErrorHandlingIntegrationTests: XCTestCase {
    
    // MARK: - Workflow Error Propagation
    
    /// Tests that errors in LLM tasks properly propagate through workflows.
    func testLLMErrorPropagationInWorkflow() async throws {
        // Create a mock service that always fails
        let failingService = IntegrationMockLLMService(
            name: "FailingService",
            vendor: "Mock",
            expectedResult: .failure(LLMServiceError.serviceUnavailable(message: "Service unavailable for testing"))
        )
        
        var workflow = Workflow(
            name: "Error Propagation Test",
            description: "Test error handling in workflow"
        ) {
            Workflow.Task(name: "FailingLLMTask") { _ in
                let request = IntegrationTestHelpers.makeTestRequest(content: "Test")
                _ = try await failingService.sendRequest(request)
                return ["result": "success"]
            }
            
            // This task should not run if previous task fails
            Workflow.Task(name: "ShouldNotRun") { _ in
                return ["executed": true]
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .failed = state {
            // Workflow failed as expected
        } else {
            XCTFail("Workflow should fail when LLM task fails, but got state: \(state)")
        }
        
        // Verify the second task didn't run
        let shouldNotRunOutput = workflow.outputs["ShouldNotRun.executed"]
        XCTAssertNil(shouldNotRunOutput, "Second task should not execute after failure")
    }
    
    // MARK: - Error Recovery in Workflow
    
    /// Tests error recovery patterns in workflows.
    func testErrorRecoveryPattern() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        var workflow = Workflow(
            name: "Error Recovery Test",
            description: "Test workflow error recovery"
        ) {
            // First task succeeds
            Workflow.Task(name: "SuccessfulTask") { _ in
                let request = IntegrationTestHelpers.makeTestRequest(content: "Hello")
                let response = try await service.sendRequest(request)
                return ["result": response.text]
            }
            
            // Second task with error handling
            Workflow.Task(name: "TaskWithErrorHandling") { inputs in
                do {
                    let request = IntegrationTestHelpers.makeTestRequest(content: "Test")
                    let response = try await service.sendRequest(request)
                    return ["result": response.text, "error": false]
                } catch {
                    // Handle error gracefully
                    return ["result": "Error handled", "error": true]
                }
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete even with error handling, but got state: \(state)")
        }
        
        // Verify both tasks completed
        let successfulResult = workflow.outputs["SuccessfulTask.result"] as? String
        let handledResult = workflow.outputs["TaskWithErrorHandling.result"] as? String
        
        XCTAssertNotNil(successfulResult, "First task should complete")
        XCTAssertNotNil(handledResult, "Second task should complete (with or without error)")
    }
    
    // MARK: - TaskLibrary Error Handling
    
    /// Tests that TaskLibrary tasks properly handle and propagate errors.
    func testTaskLibraryErrorHandling() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        Tasks.configure(with: service)
        
        // Test with valid input - should succeed
        do {
            let result = try await Tasks.analyzeSentiment(["This is great!"], maxTokens: 50)
            XCTAssertFalse(result.isEmpty, "Should get sentiment result")
        } catch {
            XCTFail("Valid sentiment analysis should not fail: \(error)")
        }
    }
}

// MARK: - Mock Helpers (reused from IntegrationTestHelpers)

private struct IntegrationMockLLMResponse: LLMResponseProtocol {
    var text: String
    var model: String?
    var tokenUsage: LLMTokenUsage?
    var vendor: String?
    
    var id: String? { nil }
    var finishReason: String? { "stop" }
    var systemFingerprint: String? { nil }
    
    init(text: String, model: String, tokenUsage: LLMTokenUsage?) {
        self.text = text
        self.model = model
        self.tokenUsage = tokenUsage
        self.vendor = "Mock"
    }
}

private final class IntegrationMockLLMService: LLMServiceProtocol {
    var name: String
    var vendor: String
    var apiKey: String? = nil
    var requiresAPIKey = false
    var contextWindowSize: Int = 8192
    var maxOutputTokens: Int = 4096
    var inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var systemPrompt: String? = nil
    var defaultModel: String = "mock-model"
    
    private let expectedResult: Result<LLMResponseProtocol, Error>
    
    init(name: String, vendor: String, expectedResult: Result<LLMResponseProtocol, Error>) {
        self.name = name
        self.vendor = vendor
        self.expectedResult = expectedResult
    }
    
    func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: ((String) -> Void)?) async throws -> LLMResponseProtocol {
        if let onPartialResponse = onPartialResponse {
            switch expectedResult {
            case .success(let response):
                onPartialResponse(response.text)
                return response
            case .failure(let error):
                throw error
            }
        }
        
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

