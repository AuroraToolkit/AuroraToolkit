//
//  LLMConvenienceTests.swift
//  AuroraLLMTests
//
//  Created on 10/18/25.
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM

final class LLMConvenienceTests: XCTestCase {
    
    func testLLMConvenienceAPIAccess() {
        // Test that we can access the convenience APIs
        let anthropic = LLM.anthropic
        let openai = LLM.openai
        let ollama = LLM.ollama
        
        XCTAssertEqual(anthropic.name, "DefaultAnthropic")
        XCTAssertEqual(openai.name, "DefaultOpenAI")
        XCTAssertEqual(ollama.name, "DefaultOllama")
    }
    
    func testAnthropicServiceConvenienceMethods() {
        let service = LLM.anthropic
        
        // Test that the convenience methods exist and have correct signatures
        // We can't actually call them without API keys, but we can verify they exist
        XCTAssertNotNil(service)
        XCTAssertEqual(service.vendor, "Anthropic")
    }
    
    func testOpenAIServiceConvenienceMethods() {
        let service = LLM.openai
        
        // Test that the convenience methods exist and have correct signatures
        XCTAssertNotNil(service)
        XCTAssertEqual(service.vendor, "OpenAI")
    }
    
    func testOllamaServiceConvenienceMethods() {
        let service = LLM.ollama
        
        // Test that the convenience methods exist and have correct signatures
        XCTAssertNotNil(service)
        XCTAssertEqual(service.vendor, "Ollama")
    }
    
    @available(iOS 26, macOS 26, visionOS 26, *)
    func testFoundationModelServiceConvenienceMethods() {
        let service = LLM.foundation
        
        // Apple Foundation Model service may be nil if not available
        if let service = service {
            XCTAssertEqual(service.vendor, "Apple")
        }
    }
    
    func testLLMStaticSendMethod() {
        // Test that the static send method exists and has correct signature
        // We can't actually call it without API keys, but we can verify the method exists
        let service = LLM.anthropic
        XCTAssertNotNil(service)
        
        // Test that we can create a closure that would call the convenience method
        // This validates the method signature exists and is accessible
        let sendClosure: (String) async throws -> String = { message in
            return try await service.send(message)
        }
        XCTAssertNotNil(sendClosure)
    }
    
    func testLLMStaticStreamMethod() {
        // Test that the static stream method exists and has correct signature
        let service = LLM.anthropic
        XCTAssertNotNil(service)
        
        // Test that we can create a closure that would call the convenience method
        // This validates the method signature exists and is accessible
        let streamClosure: (String, @escaping @Sendable (String) -> Void) async throws -> String = { message, onPartialResponse in
            return try await service.stream(message, onPartialResponse: onPartialResponse)
        }
        XCTAssertNotNil(streamClosure)
    }
    
    func testModelParameterInSendMethod() async throws {
        // Test that the model parameter is correctly passed through to the service
        let mockResponse = MockLLMResponse(text: "Test response", vendor: "MockLLM", model: "test-model")
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .success(mockResponse)
        )
        
        // Test send with model parameter using LLM.send static method
        let response = try await LLM.send("Test message", to: mockService, model: "custom-model")
        XCTAssertEqual(response, "Test response")
        
        // Verify the request was made with the correct model
        XCTAssertEqual(mockService.receivedRequests.count, 1)
        XCTAssertEqual(mockService.receivedRequests.first?.model, "custom-model")
    }
    
    func testModelParameterInStreamMethod() async throws {
        // Test that the model parameter is correctly passed through to the service in streaming
        let mockResponse = MockLLMResponse(text: "Streaming response", vendor: "MockLLM", model: "test-model")
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .success(mockResponse),
            streamingExpectedResult: "Streaming response"
        )
        
        actor PartialResponseCollector {
            private var partial: String?
            
            func set(_ value: String) {
                partial = value
            }
            
            func get() -> String? {
                return partial
            }
        }
        
        let collector = PartialResponseCollector()
        let response = try await LLM.stream("Test message", to: mockService, model: "custom-model") { partial in
            Task { @Sendable in
                await collector.set(partial)
            }
        }
        
        // Give the Task a moment to complete
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        XCTAssertEqual(response, "Streaming response")
        let receivedPartial = await collector.get()
        XCTAssertEqual(receivedPartial, "Streaming response")
        
        // Verify the request was made with the correct model
        XCTAssertEqual(mockService.receivedStreamingRequests.count, 1)
        XCTAssertEqual(mockService.receivedStreamingRequests.first?.model, "custom-model")
    }
    
    func testUnavailableModelFailsGracefully() async {
        // Test that requesting an unavailable model fails gracefully with appropriate error
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .failure(LLMServiceError.invalidResponse(statusCode: 404))
        )
        
        do {
            _ = try await LLM.send("Test message", to: mockService, model: "nonexistent-model")
            XCTFail("Expected error to be thrown for unavailable model")
        } catch let error as LLMServiceError {
            // Verify we get the expected error type
            if case .invalidResponse(let statusCode) = error {
                XCTAssertEqual(statusCode, 404, "Expected 404 status code for unavailable model")
            } else {
                XCTFail("Expected invalidResponse error, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
        
        // Verify the request was attempted
        XCTAssertEqual(mockService.receivedRequests.count, 1)
        XCTAssertEqual(mockService.receivedRequests.first?.model, "nonexistent-model")
    }
    
    func testUnavailableModelInStreamFailsGracefully() async {
        // Test that requesting an unavailable model in streaming fails gracefully
        let mockService = MockLLMService(
            name: "TestService",
            expectedResult: .failure(LLMServiceError.invalidResponse(statusCode: 404))
        )
        
        actor PartialResponseCollector {
            private var partial: String?
            
            func set(_ value: String) {
                partial = value
            }
            
            func get() -> String? {
                return partial
            }
        }
        
        let collector = PartialResponseCollector()
        do {
            _ = try await LLM.stream("Test message", to: mockService, model: "nonexistent-model") { partial in
                Task { @Sendable in
                    await collector.set(partial)
                }
            }
            XCTFail("Expected error to be thrown for unavailable model")
        } catch let error as LLMServiceError {
            // Verify we get the expected error type
            if case .invalidResponse(let statusCode) = error {
                XCTAssertEqual(statusCode, 404, "Expected 404 status code for unavailable model")
            } else {
                XCTFail("Expected invalidResponse error, got \(error)")
            }
        } catch {
            XCTFail("Expected LLMServiceError, got \(error)")
        }
        
        // Verify no partial response was received
        let receivedPartial = await collector.get()
        XCTAssertNil(receivedPartial)
        
        // Verify the request was attempted
        XCTAssertEqual(mockService.receivedStreamingRequests.count, 1)
        XCTAssertEqual(mockService.receivedStreamingRequests.first?.model, "nonexistent-model")
    }
    
    func testDefaultModelWhenModelNotSpecified() async throws {
        // Test that when model is not specified, the service's default model is used
        let mockResponse = MockLLMResponse(text: "Test response", vendor: "MockLLM", model: "default-model")
        let mockService = MockLLMService(
            name: "TestService",
            defaultModel: "default-model",
            expectedResult: .success(mockResponse)
        )
        
        // Test send without model parameter using LLM.send static method
        let response = try await LLM.send("Test message", to: mockService)
        XCTAssertEqual(response, "Test response")
        
        // Verify the request was made with nil model (service will use default)
        XCTAssertEqual(mockService.receivedRequests.count, 1)
        XCTAssertNil(mockService.receivedRequests.first?.model)
    }
}
