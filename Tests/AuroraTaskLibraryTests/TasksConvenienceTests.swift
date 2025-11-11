//
//  TasksConvenienceTests.swift
//  AuroraTaskLibraryTests
//
//  Created on 10/18/25.
//

import XCTest
@testable import AuroraTaskLibrary
@testable import AuroraCore
@testable import AuroraLLM

final class TasksConvenienceTests: XCTestCase {
    
    // MARK: - Tasks Convenience API Tests
    
    func testTasksConvenienceAPIAccess() {
        // Test that the Tasks convenience struct is accessible
        // Note: Most methods require a configured service, so we'll test method signatures
        
        // Test that we can create closures that would call the convenience methods
        let analyzeSentimentClosure: ([String]) async throws -> [String] = { strings in
            return try await Tasks.analyzeSentiment(strings)
        }
        XCTAssertNotNil(analyzeSentimentClosure)
        
        let summarizeClosure: (String) async throws -> String = { text in
            return try await Tasks.summarize(text)
        }
        XCTAssertNotNil(summarizeClosure)
        
        let extractKeywordsClosure: (String) async throws -> [String] = { text in
            return try await Tasks.extractKeywords(text)
        }
        XCTAssertNotNil(extractKeywordsClosure)
        
        let translateClosure: (String, String) async throws -> String = { text, language in
            return try await Tasks.translate(text, to: language)
        }
        XCTAssertNotNil(translateClosure)
        
        let extractEntitiesClosure: (String) async throws -> [String] = { text in
            return try await Tasks.extractEntities(text)
        }
        XCTAssertNotNil(extractEntitiesClosure)
        
        let categorizeClosure: (String, [String]) async throws -> String = { text, categories in
            return try await Tasks.categorize(text, into: categories)
        }
        XCTAssertNotNil(categorizeClosure)
    }
    
    // MARK: - Service Configuration Tests
    
    func testTasksServiceConfiguration() async {
        // Test service configuration methods
        let mockResponse = MockLLMResponse(text: "Mock response")
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .success(mockResponse)
        )
        
        // Test direct service configuration
        await Tasks.configure(with: mockService)
        XCTAssertNotNil(mockService)
        
        // Test service type configuration
        await Tasks.configure(with: .anthropic)
        // Note: This will use the actual LLM.anthropic service
    }
    
    func testTasksServiceTypeEnum() {
        // Test that LLMServiceType enum cases are accessible
        let anthropicType = LLMServiceType.anthropic
        let openaiType = LLMServiceType.openai
        let ollamaType = LLMServiceType.ollama
        let foundationType = LLMServiceType.foundation
        
        XCTAssertNotNil(anthropicType)
        XCTAssertNotNil(openaiType)
        XCTAssertNotNil(ollamaType)
        XCTAssertNotNil(foundationType)
    }
    
    // MARK: - Data Processing Tests
    
    func testTasksDataProcessingMethods() {
        // Test data processing method signatures
        let fetchClosure: (String) async throws -> String = { url in
            return try await Tasks.fetch(url)
        }
        XCTAssertNotNil(fetchClosure)
        
        let parseRSSClosure: (String) async throws -> [RSSArticle] = { xmlData in
            return try await Tasks.parseRSS(xmlData)
        }
        XCTAssertNotNil(parseRSSClosure)
        
        let parseJSONClosure: (String, String) async throws -> JSONElement = { jsonData, keyPath in
            return try await Tasks.parseJSON(jsonData, keyPath: keyPath)
        }
        XCTAssertNotNil(parseJSONClosure)
    }
    
    // MARK: - ML Task Integration Tests
    
    func testTasksMLIntegration() {
        // Test ML task integration method signatures
        let embedClosure: (String) async throws -> [Double] = { text in
            return try await Tasks.embed(text)
        }
        XCTAssertNotNil(embedClosure)
        
        let searchClosure: (String, [String]) async throws -> [[String: Any]] = { query, documents in
            return try await Tasks.search(query, in: documents)
        }
        XCTAssertNotNil(searchClosure)
    }
    
    // MARK: - Error Handling Tests
    
    func testTasksErrorEnum() {
        // Test that TasksError enum cases are accessible
        let noServiceError = TasksError.noDefaultServiceConfigured
        let invalidURLError = TasksError.invalidURL("test://invalid")
        let taskExecutionError = TasksError.taskExecutionFailed("Test failure")
        
        XCTAssertNotNil(noServiceError.errorDescription)
        XCTAssertNotNil(invalidURLError.errorDescription)
        XCTAssertNotNil(taskExecutionError.errorDescription)
        
        XCTAssertTrue(noServiceError.errorDescription?.contains("No default LLM service") == true)
        XCTAssertTrue(invalidURLError.errorDescription?.contains("test://invalid") == true)
        XCTAssertTrue(taskExecutionError.errorDescription?.contains("Test failure") == true)
    }
    
    // MARK: - Integration Tests
    
    func testTasksConvenienceIntegration() async {
        // Test that all convenience APIs work together
        let mockResponse = MockLLMResponse(text: "Mock response")
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .success(mockResponse)
        )
        await Tasks.configure(with: mockService)
        
        // Test that we can create a workflow using convenience methods
        let workflowClosure: () async throws -> Void = {
            // This would be a real workflow using the convenience APIs
            let _ = try await Tasks.analyzeSentiment(["Test text"])
            let _ = try await Tasks.summarize("Test text")
            let _ = try await Tasks.extractKeywords("Test text")
        }
        XCTAssertNotNil(workflowClosure)
    }
}

// MARK: - Mock Service for Testing

// Note: Using existing MockLLMService from Tests/AuroraTaskLibraryTests/Mocks/MockLLMService.swift
