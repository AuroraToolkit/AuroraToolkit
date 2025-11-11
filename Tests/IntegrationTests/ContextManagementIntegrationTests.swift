//
//  ContextManagementIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests for context management across multiple LLM calls
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraTaskLibrary

/// Integration tests for context management and multi-turn conversations.
final class ContextManagementIntegrationTests: XCTestCase {
    
    // MARK: - Multi-Turn Conversation
    
    /// Tests a multi-turn conversation using context management.
    func testMultiTurnConversation() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        // Create a context controller
        let contextController = ContextController(
            llmService: service
        )
        
        // First turn - add context
        contextController.addItem(content: "My name is Alice and I like Swift programming.")
        
        // Get a summary using the summarizer directly
        let summarizer = contextController.getSummarizer()
        let firstResponse = try await summarizer.summarize("My name is Alice and I like Swift programming.", options: nil, logger: nil)
        
        XCTAssertFalse(firstResponse.isEmpty, "First response should not be empty")
        
        // Second turn - add more context
        contextController.addItem(content: "I'm working on an iOS app using AuroraToolkit.")
        let secondResponse = try await summarizer.summarize("I'm working on an iOS app using AuroraToolkit.", options: nil, logger: nil)
        
        XCTAssertFalse(secondResponse.isEmpty, "Second response should not be empty")
        
        // Verify context has items
        let items = contextController.getItems()
        XCTAssertGreaterThanOrEqual(items.count, 2, "Should have at least 2 context items")
    }
    
    // MARK: - Workflow with Context Management
    
    /// Tests a workflow that uses context management across multiple LLM calls.
    func testWorkflowWithContextManagement() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        let contextController = ContextController(llmService: service)
        
        var workflow = Workflow(
            name: "Context Management Workflow",
            description: "Build context across multiple tasks"
        ) {
            // Step 1: Add initial context
            Workflow.Task(name: "AddInitialContext") { _ in
                contextController.addItem(content: "User is interested in AI and machine learning.")
                return ["contextAdded": true]
            }
            
            // Step 2: Ask follow-up question
            Workflow.Task(name: "FollowUpQuestion") { _ in
                let request = IntegrationTestHelpers.makeTestRequest(
                    content: "Based on the context that the user is interested in AI, suggest a learning path."
                )
                let response = try await service.sendRequest(request)
                contextController.addItem(content: response.text)
                return ["suggestion": response.text]
            }
            
            // Step 3: Summarize context using summarizer
            Workflow.Task(name: "SummarizeContext") { _ in
                let summarizer = contextController.getSummarizer()
                let contextItems = contextController.getItems()
                let texts = contextItems.map { $0.text }
                let summaries = try await summarizer.summarizeGroup(texts, type: .single, options: nil, logger: nil)
                let summary = summaries.joined(separator: " ")
                return ["summary": summary]
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
        let suggestion = workflow.outputs["FollowUpQuestion.suggestion"] as? String
        let summary = workflow.outputs["SummarizeContext.summary"] as? String
        
        XCTAssertNotNil(suggestion, "Should have suggestion")
        XCTAssertNotNil(summary, "Should have context summary")
    }
    
    // MARK: - Context Tasks Integration
    
    /// Tests using context management tasks from TaskLibrary.
    func testContextTasksIntegration() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        await Tasks.configure(with: service)
        
        // This tests that context tasks work with real services
        // Note: Actual context save/load requires file system access
        // This test verifies the integration works
        let testText = "This is test context for integration testing."
        
        // Verify we can create a context and summarize it
        let contextController = ContextController(llmService: service)
        contextController.addItem(content: testText)
        
        let summarizer = contextController.getSummarizer()
        let summary = try await summarizer.summarize(testText, options: nil, logger: nil)
        XCTAssertFalse(summary.isEmpty, "Should generate a summary")
    }
}

