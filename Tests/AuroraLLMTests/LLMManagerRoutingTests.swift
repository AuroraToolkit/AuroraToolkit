//
//  LLMManagerRoutingTests.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 12/12/25.
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM

final class LLMManagerRoutingTests: XCTestCase {

    var manager: LLMManager!

    override func setUp() {
        super.setUp()
        manager = LLMManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testServiceExposure() {
        // Given
        let service = MockLLMService(
            name: "TestService",
            supportedModels: ["model-a", "model-b"],
            expectedResult: .success(MockLLMResponse(text: "Test"))
        )
        manager.registerService(service)

        // Then
        // This test primarily validates that `services` is public and accessible
        XCTAssertEqual(manager.services.count, 1)
        XCTAssertNotNil(manager.services["testservice"])
        
        // Verify supportedModels visibility
        let registeredService = manager.services["testservice"]?.service as? MockLLMService
        XCTAssertEqual(registeredService?.supportedModels.sorted(), ["model-a", "model-b", "mock-model"].sorted()) // mock-model added by default
    }

    func testModelRouting_Match() async {
        // Given
        let gptService = MockLLMService(
            name: "GPTService",
            supportedModels: ["gpt-4", "gpt-3.5"],
            expectedResult: .success(MockLLMResponse(text: "GPT Response"))
        )
        let claudeService = MockLLMService(
            name: "ClaudeService",
            supportedModels: ["claude-3-opus", "claude-3-sonnet"],
            expectedResult: .success(MockLLMResponse(text: "Claude Response"))
        )

        manager.registerService(claudeService)
        manager.registerService(gptService) // Register second to ensure it's not just picking the first one by chance (though logic should handle it)

        let request = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")])

        // When
        let response = await manager.sendRequest(request, routings: [.models(["gpt-4"])])

        // Then
        XCTAssertEqual(response?.text, "GPT Response")
    }

    func testModelRouting_NoMatch() async {
        // Given
        let gptService = MockLLMService(
            name: "GPTService",
            supportedModels: ["gpt-4"],
            expectedResult: .success(MockLLMResponse(text: "GPT Response"))
        )
        
        manager.registerService(gptService)

        let request = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")])

        // When
        // Request a model that is NOT supported
        let response = await manager.sendRequest(request, routings: [.models(["claude-3-opus"])])

        // Then
        XCTAssertNil(response, "Should return nil if no service supports the requested model")
    }

    func testModelRouting_CaseInsensitive() async {
        // Given
        let gptService = MockLLMService(
            name: "GPTService",
            supportedModels: ["GPT-4"],
            expectedResult: .success(MockLLMResponse(text: "GPT Response"))
        )
        
        manager.registerService(gptService)

        let request = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")])

        // When
        let response = await manager.sendRequest(request, routings: [.models(["gpt-4"])])

        // Then
        XCTAssertEqual(response?.text, "GPT Response", "Routing should be case-insensitive")
    }
    
    func testModelRouting_MultiplePreferences() async {
         // Given
         let gptService = MockLLMService(
             name: "GPTService",
             supportedModels: ["gpt-4"],
             expectedResult: .success(MockLLMResponse(text: "GPT Response"))
         )
         
         manager.registerService(gptService)

         let request = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")])

         // When
         // Provide multiple preferred models, one of which exists
         let response = await manager.sendRequest(request, routings: [.models(["non-existent", "gpt-4"])])

         // Then
        XCTAssertEqual(response?.text, "GPT Response", "Should route if AT LEAST ONE model is supported")
    }

    func testStrictRouting_WithFallback() async {
        // Given
        let ollama = MockLLMService(
            name: "Ollama", 
            supportedModels: ["llama3"], 
            expectedResult: .success(MockLLMResponse(text: "Ollama"))
        )
        let fallback = MockLLMService(
            name: "Fallback", 
            expectedResult: .success(MockLLMResponse(text: "Fallback"))
        )
        
        manager.registerService(ollama)
        manager.registerFallbackService(fallback)
        
        let request = LLMRequest(messages: [], model: "unknown-model")
        
        // Case 1: STRICT MODE (Explicitly requesting a specific model routing)
        // Should return nil because the model is not supported, ignoring fallback
        let strictResponse = await manager.sendRequest(request, routings: [.models(["unknown-model"])])
        XCTAssertNil(strictResponse, "Strict routing should fail for unknown model, even if fallback exists")
        
        // Case 2: NON-STRICT MODE (No specific routing constraints)
        // Should use active service (Ollama) because no strict routing rules prevent it
        let fallbackResponse = await manager.sendRequest(request, routings: [])
        XCTAssertEqual(fallbackResponse?.text, "Ollama", "Non-strict should use active service (Ollama) by default")
    }
}
