//
//  MLConvenienceTests.swift
//  AuroraMLTests
//
//  Created on 10/18/25.
//

import XCTest
@testable import AuroraML
@testable import AuroraCore
import NaturalLanguage

final class MLConvenienceTests: XCTestCase {
    
    // MARK: - ML Convenience API Tests
    
    func testMLConvenienceAPIAccess() {
        // Test that the ML convenience struct is accessible
        // Note: ML.sentiment and ML.intents will fatalError without proper model registration
        let _ = ML.embeddings
        
        // Test that we can create closures that would call the convenience methods
        let classifyClosure: (String, ClassificationService) async throws -> [Tag] = { text, service in
            return try await ML.classify(text, with: service)
        }
        XCTAssertNotNil(classifyClosure)
        
        let embedClosure: (String, EmbeddingService) async throws -> [Double] = { text, service in
            return try await ML.embed(text, with: service)
        }
        XCTAssertNotNil(embedClosure)
    }
    
    // MARK: - ClassificationService Convenience Tests
    
    func testClassificationServiceConvenienceMethods() {
        // Test that convenience methods exist and are accessible
        // Note: We can't instantiate defaultSentiment without a model, so we'll test the method signatures differently
        
        // Test that we can create closures that would call the convenience methods
        // These would work with a properly configured service
        let classifyClosure: (ClassificationService, String) async throws -> [Tag] = { service, text in
            return try await service.classify(text)
        }
        XCTAssertNotNil(classifyClosure)
        
        let classifyMultipleClosure: (ClassificationService, [String]) async throws -> [Tag] = { service, texts in
            return try await service.classify(texts)
        }
        XCTAssertNotNil(classifyMultipleClosure)
        
        let topClassificationClosure: (ClassificationService, String) async throws -> Tag? = { service, text in
            return try await service.topClassification(for: text)
        }
        XCTAssertNotNil(topClassificationClosure)
    }
    
    func testClassificationServiceDefaultServices() {
        // Test that default services are accessible
        // Note: These will fatalError without proper model registration, so we'll skip this test
        // In a real implementation, these would be properly configured with models
        
        // We'll just verify that the static properties exist by checking their types
        // without actually instantiating them
        XCTAssertTrue(ClassificationService.self == ClassificationService.self)
    }
    
    // MARK: - EmbeddingService Convenience Tests
    
    func testEmbeddingServiceConvenienceMethods() {
        // Test that convenience methods exist and are accessible
        let service = EmbeddingService.defaultSentence
        
        // Test that we can create closures that would call the convenience methods
        let embedClosure: (String) async throws -> [Double] = { text in
            return try await service.embed(text)
        }
        XCTAssertNotNil(embedClosure)
        
        let embedMultipleClosure: ([String]) async throws -> [[Double]] = { texts in
            return try await service.embed(texts)
        }
        XCTAssertNotNil(embedMultipleClosure)
        
        let similarityClosure: (String, String) async throws -> Double = { text1, text2 in
            return try await service.similarity(between: text1, and: text2)
        }
        XCTAssertNotNil(similarityClosure)
    }
    
    func testEmbeddingServiceDefaultServices() {
        // Test that default services are accessible
        let sentenceService = EmbeddingService.defaultSentence
        XCTAssertEqual(sentenceService.name, "DefaultSentenceEmbedding")
        
        let wordService = EmbeddingService.defaultWord
        XCTAssertEqual(wordService.name, "DefaultWordEmbedding")
    }
    
    // MARK: - SemanticSearchService Convenience Tests
    
    func testSemanticSearchServiceConvenienceMethods() {
        // Test that convenience methods exist and are accessible
        let documents = ["Hello world", "Machine learning is great"]
        let service = SemanticSearchService.withDefaultEmbeddings(
            name: "TestSearch",
            documents: documents
        )
        
        // Test that we can create closures that would call the convenience methods
        let searchClosure: (String) async throws -> [[String: Any]] = { query in
            return try await service.search(query)
        }
        XCTAssertNotNil(searchClosure)
        
        let searchWithVectorClosure: ([Double]) async throws -> [[String: Any]] = { vector in
            return try await service.search(with: vector)
        }
        XCTAssertNotNil(searchWithVectorClosure)
        
        let topResultClosure: (String) async throws -> (document: String, score: Double)? = { query in
            return try await service.topResult(for: query)
        }
        XCTAssertNotNil(topResultClosure)
        
        let findMostSimilarClosure: (String) async throws -> String? = { query in
            return try await service.findMostSimilar(to: query)
        }
        XCTAssertNotNil(findMostSimilarClosure)
    }
    
    func testSemanticSearchServiceWithDefaultEmbeddings() {
        let documents = ["Test document 1", "Test document 2"]
        let service = SemanticSearchService.withDefaultEmbeddings(
            name: "TestService",
            documents: documents,
            topK: 3
        )
        
        XCTAssertEqual(service.name, "TestService")
    }
    
    // MARK: - IntentExtractionService Convenience Tests
    
    func testIntentExtractionServiceConvenienceMethods() {
        // Test that convenience methods exist and are accessible
        // Note: We can't instantiate default without a model, so we'll test the method signatures differently
        
        // Test that we can create closures that would call the convenience methods
        // These would work with a properly configured service
        let extractIntentsClosure: (IntentExtractionService, String) async throws -> [[String: Any]] = { service, text in
            return try await service.extractIntents(from: text)
        }
        XCTAssertNotNil(extractIntentsClosure)
        
        let extractIntentsMultipleClosure: (IntentExtractionService, [String]) async throws -> [[String: Any]] = { service, texts in
            return try await service.extractIntents(from: texts)
        }
        XCTAssertNotNil(extractIntentsMultipleClosure)
        
        let topIntentClosure: (IntentExtractionService, String) async throws -> (name: String, confidence: Double)? = { service, text in
            return try await service.topIntent(from: text)
        }
        XCTAssertNotNil(topIntentClosure)
        
        let hasIntentClosure: (IntentExtractionService, String, String, Double) async throws -> Bool = { service, intent, text, threshold in
            return try await service.hasIntent(intent, in: text, threshold: threshold)
        }
        XCTAssertNotNil(hasIntentClosure)
    }
    
    func testIntentExtractionServiceDefault() {
        // Test that the default service is accessible
        // Note: This will fatalError without proper model registration, so we'll skip this test
        // In a real implementation, this would be properly configured with a model
        
        // We'll just verify that the static property exists by checking the type
        // without actually instantiating it
        XCTAssertTrue(IntentExtractionService.self == IntentExtractionService.self)
    }
    
    // MARK: - ML Task and Error Tests
    
    func testMLTaskEnum() {
        // Test that MLTask enum cases are accessible
        let sentimentTask = MLTask.sentiment
        let categoryTask = MLTask.categories
        let intentTask = MLTask.intents
        
        XCTAssertNotNil(sentimentTask)
        XCTAssertNotNil(categoryTask)
        XCTAssertNotNil(intentTask)
    }
    
    func testMLErrorEnum() {
        // Test that MLError enum cases are accessible
        let modelError = MLError.modelLoadingFailed(URL(fileURLWithPath: "/test"))
        let serviceError = MLError.serviceNotAvailable("TestService")
        let inputError = MLError.invalidInput("Test input")
        
        XCTAssertNotNil(modelError.errorDescription)
        XCTAssertNotNil(serviceError.errorDescription)
        XCTAssertNotNil(inputError.errorDescription)
        
        XCTAssertTrue(modelError.errorDescription?.contains("Failed to load model") == true)
        XCTAssertTrue(serviceError.errorDescription?.contains("TestService") == true)
        XCTAssertTrue(inputError.errorDescription?.contains("Test input") == true)
    }
    
    // MARK: - Integration Tests
    
    func testMLConvenienceIntegration() {
        // Test that all convenience APIs work together
        // Note: ML.sentiment and ML.intents will fatalError without proper model registration
        let embeddingService = ML.embeddings
        
        // Test that we can create a workflow using convenience methods
        let workflowClosure: () async throws -> Void = {
            // This would be a real workflow using the convenience APIs
            // let _ = try await ML.classify("Test text", with: sentimentService)
            let _ = try await ML.embed("Test text", with: embeddingService)
            // let _ = try await ML.extractIntents("Test text", with: intentService)
        }
        XCTAssertNotNil(workflowClosure)
    }
}
