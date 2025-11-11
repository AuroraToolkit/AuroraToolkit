//
//  PerformanceIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests that measure performance of real workflows
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraTaskLibrary

/// Integration tests that measure performance characteristics of workflows.
final class PerformanceIntegrationTests: XCTestCase {
    
    // MARK: - Single LLM Call Performance
    
    /// Measures performance of a single LLM call.
    func testSingleLLMCallPerformance() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        let request = IntegrationTestHelpers.makeTestRequest(content: "Say hello")
        
        let startTime = Date()
        let response = try await service.sendRequest(request)
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertFalse(response.text.isEmpty, "Should get a response")
        
        // Performance assertions
        // Apple Foundation Model typically responds in < 2 seconds
        // Mock should be nearly instant
        if IntegrationTestHelpers.isFoundationModelAvailable() {
            XCTAssertLessThan(duration, 5.0, "Apple Foundation Model should respond within 5 seconds")
        } else {
            XCTAssertLessThan(duration, 0.1, "Mock service should respond nearly instantly")
        }
        
        print("⏱️ Single LLM call took: \(String(format: "%.3f", duration)) seconds")
    }
    
    // MARK: - Workflow Execution Performance
    
    /// Measures performance of a complete workflow execution.
    func testWorkflowExecutionPerformance() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        await Tasks.configure(with: service)
        
        let startTime = Date()
        
        var workflow = Workflow(
            name: "Performance Test Workflow",
            description: "Measure workflow execution time"
        ) {
            Workflow.Task(name: "Task1") { _ in
                let texts = ["Test text 1"]
                let _ = try await Tasks.analyzeSentiment(texts, maxTokens: 50)
                return ["completed": true]
            }
            
            Workflow.Task(name: "Task2") { _ in
                let text = "Test text 2"
                let _ = try await Tasks.extractKeywords(text, maxTokens: 50)
                return ["completed": true]
            }
        }
        
        await workflow.start()
        let duration = Date().timeIntervalSince(startTime)
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete, but got state: \(state)")
        }
        
        // Performance expectations
        if IntegrationTestHelpers.isFoundationModelAvailable() {
            XCTAssertLessThan(duration, 10.0, "Workflow with Apple Foundation Model should complete in < 10 seconds")
        } else {
            XCTAssertLessThan(duration, 1.0, "Workflow with mock should complete quickly")
        }
        
        print("⏱️ Workflow execution took: \(String(format: "%.3f", duration)) seconds")
    }
    
    // MARK: - Multiple Sequential LLM Calls
    
    /// Measures performance of multiple sequential LLM calls.
    func testMultipleSequentialLLMCallsPerformance() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        let startTime = Date()
        
        // Make 3 sequential calls
        for i in 1...3 {
            let request = IntegrationTestHelpers.makeTestRequest(
                content: "Say number \(i) in one word"
            )
            let response = try await service.sendRequest(request)
            XCTAssertFalse(response.text.isEmpty, "Call \(i) should succeed")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Performance expectations
        if IntegrationTestHelpers.isFoundationModelAvailable() {
            XCTAssertLessThan(duration, 15.0, "3 Apple Foundation Model calls should complete in < 15 seconds")
        } else {
            XCTAssertLessThan(duration, 0.5, "3 mock calls should complete quickly")
        }
        
        print("⏱️ 3 sequential LLM calls took: \(String(format: "%.3f", duration)) seconds")
    }
    
    // MARK: - TaskLibrary Performance
    
    /// Measures performance of TaskLibrary convenience methods.
    func testTaskLibraryPerformance() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        await Tasks.configure(with: service)
        
        let startTime = Date()
        
        // Test multiple TaskLibrary operations
        let _ = try await Tasks.analyzeSentiment(["Great product!"], maxTokens: 50)
        let _ = try await Tasks.extractKeywords("Swift programming language", maxTokens: 50)
        let _ = try await Tasks.summarize("This is a test summary of a longer text that needs to be summarized.", maxTokens: 100)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Performance expectations
        if IntegrationTestHelpers.isFoundationModelAvailable() {
            XCTAssertLessThan(duration, 15.0, "Multiple TaskLibrary calls should complete in < 15 seconds")
        } else {
            XCTAssertLessThan(duration, 0.5, "Multiple mock calls should complete quickly")
        }
        
        print("⏱️ TaskLibrary operations took: \(String(format: "%.3f", duration)) seconds")
    }
}

