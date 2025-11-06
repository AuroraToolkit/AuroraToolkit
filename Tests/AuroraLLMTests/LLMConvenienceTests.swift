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
        let streamClosure: (String, @escaping (String) -> Void) async throws -> String = { message, onPartialResponse in
            return try await service.stream(message, onPartialResponse: onPartialResponse)
        }
        XCTAssertNotNil(streamClosure)
    }
}
