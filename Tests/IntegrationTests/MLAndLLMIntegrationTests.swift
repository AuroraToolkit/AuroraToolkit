//
//  MLAndLLMIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests for ML + LLM workflows
//

import XCTest
import NaturalLanguage
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraML
@testable import AuroraTaskLibrary

/// Integration tests that verify ML and LLM modules work together.
final class MLAndLLMIntegrationTests: XCTestCase {
    
    // MARK: - ML Classification + LLM Summarization
    
    /// Tests a workflow that uses ML classification followed by LLM summarization.
    func testMLClassificationThenLLMSummarization() async throws {
        let llmService = try IntegrationTestHelpers.getLLMService()
        
        // Create ML tagging service (using on-device ML)
        let taggingService = TaggingService(
            name: "TestTagging",
            schemes: [.nameType, .lexicalClass],
            logger: nil
        )
        
        var workflow = Workflow(
            name: "ML + LLM Integration",
            description: "Classify text with ML, then summarize with LLM"
        ) {
            // Step 1: Tag text with ML (on-device)
            Workflow.Task(name: "TagText") { inputs in
                let text = "Swift programming language is excellent for iOS development"
                let response = try await taggingService.run(
                    request: MLRequest(inputs: ["strings": [text]])
                )
                let tags = response.outputs["tags"] as? [[Tag]] ?? []
                return ["tags": tags]
            }
            
            // Step 2: Summarize with LLM
            Workflow.Task(name: "SummarizeWithLLM") { inputs in
                let request = IntegrationTestHelpers.makeTestRequest(
                    content: "Summarize: Swift programming language is excellent for iOS development"
                )
                let response = try await llmService.sendRequest(request)
                return ["summary": response.text]
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
        let tags = workflow.outputs["TagText.tags"] as? [[Tag]]
        let summary = workflow.outputs["SummarizeWithLLM.summary"] as? String
        
        XCTAssertNotNil(tags, "Should have ML tags")
        XCTAssertNotNil(summary, "Should have LLM summary")
        XCTAssertFalse(summary?.isEmpty ?? true, "Summary should not be empty")
    }
    
    // MARK: - ML Embedding + LLM Analysis
    
    /// Tests creating embeddings with ML and then using LLM for analysis.
    func testMLEmbeddingThenLLMAnalysis() async throws {
        let llmService = try IntegrationTestHelpers.getLLMService()
        let embeddingService = ML.embeddings
        
        var workflow = Workflow(
            name: "Embedding + LLM Analysis",
            description: "Create embeddings, then analyze with LLM"
        ) {
            // Step 1: Create embeddings
            Workflow.Task(name: "CreateEmbeddings") { _ in
                let text = "Machine learning is transforming software development"
                let response = try await embeddingService.run(
                    request: MLRequest(inputs: ["strings": [text]])
                )
                let embeddings = response.outputs["embeddings"] as? [[Double]] ?? []
                return ["embeddings": embeddings, "originalText": text]
            }
            
            // Step 2: Analyze with LLM
            Workflow.Task(name: "AnalyzeWithLLM") { inputs in
                let originalText = inputs["originalText"] as? String ?? ""
                let request = IntegrationTestHelpers.makeTestRequest(
                    content: "Analyze this statement: \(originalText)"
                )
                let response = try await llmService.sendRequest(request)
                return ["analysis": response.text]
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete successfully, but got state: \(state)")
        }
        
        // Verify we got embeddings and analysis
        let embeddings = workflow.outputs["CreateEmbeddings.embeddings"] as? [[Double]]
        let analysis = workflow.outputs["AnalyzeWithLLM.analysis"] as? String
        
        XCTAssertNotNil(embeddings, "Should have embeddings")
        XCTAssertNotNil(analysis, "Should have LLM analysis")
    }
    
    // MARK: - ML TaskLibrary + LLM Integration
    
    /// Tests using ML tasks from TaskLibrary with LLM services.
    func testMLTaskLibraryWithLLM() async throws {
        let llmService = try IntegrationTestHelpers.getLLMService()
        Tasks.configure(with: llmService)
        
        // Test ML sentiment analysis task
        let texts = ["I love this product!", "This is terrible."]
        let sentiments = try await Tasks.analyzeSentiment(texts)
        
        XCTAssertEqual(sentiments.count, texts.count, "Should get sentiment for each text")
        
        // Verify all responses are valid
        for sentiment in sentiments {
            XCTAssertFalse(sentiment.isEmpty, "Sentiment should not be empty")
        }
    }
}

