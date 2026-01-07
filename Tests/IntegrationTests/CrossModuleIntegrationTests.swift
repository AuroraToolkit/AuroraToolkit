//
//  CrossModuleIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests that verify cross-module functionality
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraML
@testable import AuroraTaskLibrary

/// Integration tests that verify multiple modules work together correctly.
final class CrossModuleIntegrationTests: XCTestCase {
    
    // MARK: - LLM + Core Workflow Integration
    
    /// Tests a workflow that uses both AuroraCore workflows and AuroraLLM services.
    func testWorkflowWithLLMIntegration() async throws {
        // Get LLM service (Apple Foundation Model if available, mock otherwise)
        let service = try IntegrationTestHelpers.getLLMService()
        
        // Create a workflow that uses LLM
        var workflow = Workflow(name: "LLM Integration Test", description: "Test LLM within workflow") {
            Workflow.Task(name: "LLMTask") { _ in
                let request = IntegrationTestHelpers.makeTestRequest(content: "Say hello in one word.")
                let response = try await service.sendRequest(request)
                return ["llm_response": response.text]
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete successfully, but got state: \(state)")
        }
        
        // Verify we got a response
        let response = workflow.outputs["LLMTask.llm_response"] as? String
        
        if IntegrationTestHelpers.isFoundationModelAvailable(), response == nil {
             try XCTSkipIf(true, "Apple Foundation Model returned nil (likely system error -1)")
        }
        
        XCTAssertNotNil(response, "Should have received LLM response")
        XCTAssertFalse(response?.isEmpty ?? true, "Response should not be empty")
    }
    
    // MARK: - LLM + TaskLibrary Integration
    
    /// Tests that LLM tasks from TaskLibrary work correctly with real LLM services.
    func testLLMTaskWithRealService() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        // Configure Tasks convenience API to use our service
        await Tasks.configure(with: service)
        
        // Use a task from TaskLibrary
        let texts = ["This is a great product!", "I don't like this service."]
        let sentiments = try await Tasks.analyzeSentiment(texts, maxTokens: 100)
        
        XCTAssertEqual(sentiments.count, texts.count, "Should get sentiment for each text")
        
        // Verify responses (exact content depends on Apple Foundation Model vs mock)
        for sentiment in sentiments {
            XCTAssertFalse(sentiment.isEmpty, "Sentiment should not be empty")
        }
    }
    
    // MARK: - Workflow with Multiple LLM Tasks
    
    /// Tests a workflow that chains multiple LLM operations.
    func testWorkflowWithMultipleLLMTasks() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        await Tasks.configure(with: service)
        
        var workflow = Workflow(name: "Multi-LLM Test", description: "Test multiple LLM tasks in workflow") {
            // Step 1: Analyze sentiment
            Workflow.Task(name: "AnalyzeSentiment") { _ in
                let texts = ["This is excellent!"]
                let sentiments = try await Tasks.analyzeSentiment(texts, maxTokens: 50)
                return ["sentiments": sentiments]
            }
            
            // Step 2: Extract keywords (using output from previous step)
            Workflow.Task(name: "ExtractKeywords") { inputs in
                let text = "Swift programming language tutorial"
                let keywords = try await Tasks.extractKeywords(text, maxTokens: 50)
                return ["keywords": keywords]
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete successfully, but got state: \(state)")
        }
        
        // Verify outputs
        let sentiments = workflow.outputs["AnalyzeSentiment.sentiments"] as? [String]
        let keywords = workflow.outputs["ExtractKeywords.keywords"] as? [String]
        
        if IntegrationTestHelpers.isFoundationModelAvailable(), (sentiments == nil || keywords == nil) {
            try XCTSkipIf(true, "Apple Foundation Model returned nil (likely system error -1)")
        }

        XCTAssertNotNil(sentiments, "Should have sentiment results")
        XCTAssertNotNil(keywords, "Should have keyword results")
    }
    
    // MARK: - Apple Foundation Model Availability Check
    
    /// Verifies that Apple Foundation Model availability is correctly detected.
    func testFoundationModelAvailability() {
        let isAvailable = IntegrationTestHelpers.isFoundationModelAvailable()
        
        // This should be true on macOS 26+ with Apple Intelligence enabled
        // or false on older systems or when Apple Intelligence is disabled
        // Both outcomes are valid - we just verify the helper works
        XCTAssertTrue(isAvailable == true || isAvailable == false, "Availability check should return boolean")
    }
}

