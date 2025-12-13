//
//  StrictRoutingExample.swift
//  AuroraExamples
//
//  Created by Dan Murrell Jr on 12/12/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// An example demonstrating how to use strict model routing to target specific LLM services.
struct StrictRoutingExample {
    func execute() async {
        print("🧪 Strict Routing Example")
        print("------------------------")
        
        // Initialize the LLMManager
        let manager = LLMManager(logger: CustomLogger.shared)

        // 1. Setup Services with specific supported models
        
        // OpenAI Service supporting GPT-4 variants
        let openAIService = MockLLMService(
            name: "OpenAI Service",
            vendor: "OpenAI",
            defaultModel: "gpt-4",
            supportedModels: ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo"],
            expectedResult: .success(MockLLMResponse(text: "I am OpenAI.", vendor: "OpenAI"))
        )
        
        // Anthropic Service supporting Claude variants
        let anthropicService = MockLLMService(
            name: "Anthropic Service",
            vendor: "Anthropic",
            defaultModel: "claude-3-opus",
            supportedModels: ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"],
            expectedResult: .success(MockLLMResponse(text: "I am Anthropic.", vendor: "Anthropic"))
        )
        
        // Local Service supporting Llama
        let localService = MockLLMService(
            name: "Local Service",
            vendor: "Ollama",
            defaultModel: "llama3",
            supportedModels: ["llama3", "mistral"],
            expectedResult: .success(MockLLMResponse(text: "I am Local.", vendor: "Ollama"))
        )
        
        // Fallback Service (Generic)
        let fallbackService = MockLLMService(
            name: "Fallback Service",
            vendor: "Generic",
            defaultModel: "generic-model",
            supportedModels: [],
            expectedResult: .success(MockLLMResponse(text: "I am Fallback.", vendor: "Generic"))
        )

        // 2. Register Services
        manager.registerService(openAIService)
        manager.registerService(anthropicService)
        manager.registerService(localService)
        manager.registerFallbackService(fallbackService)

        print("\nRegistered Services:")
        print("- OpenAI: \(openAIService.supportedModels)")
        print("- Anthropic: \(anthropicService.supportedModels)")
        print("- Local: \(localService.supportedModels)")
        print("- Fallback: Default")

        // 3. Test Scenarios
        
        // Scenario A: Route to OpenAI via "gpt-4-turbo" (Strict)
        await testScenario(
            manager: manager,
            description: "Scenario A: Request 'gpt-4-turbo' (Strict)",
            model: "gpt-4-turbo",
            strict: true,
            expectedVendor: "OpenAI"
        )
        
        // Scenario B: Route to Anthropic via "claude-3-haiku" (Strict)
        await testScenario(
            manager: manager,
            description: "Scenario B: Request 'claude-3-haiku' (Strict)",
            model: "claude-3-haiku",
            strict: true,
            expectedVendor: "Anthropic"
        )
        
        // Scenario C: Route to Local via "mistral" (Strict)
        await testScenario(
            manager: manager,
            description: "Scenario C: Request 'mistral' (Strict)",
            model: "mistral",
            strict: true,
            expectedVendor: "Ollama"
        )
        
        // Scenario D: Request unknown model (Strict) -> Expect NIL (Failure)
        await testScenario(
            manager: manager,
            description: "Scenario D: Request 'gemini-1.5-pro' (Strict - Unsupported)",
            model: "gemini-1.5-pro",
            strict: true,
            expectedVendor: nil // Expecting nil response
        )
        
        // Scenario E: Request unknown model (Non-Strict) -> Expect Fallback (or Active)
        // Note: Non-strict routing falls back to the active service (first registered usually, or manually set) or fallback service logic.
        // In LLMManager, if no specific routing options are set, it usually defaults to Active service. 
        // If we send empty routings [], it goes to Active.
        // The fallback service is used if active fails or isn't set, or specifically requested in some logic flows.
        // In our Manager implementation, `routeRequest` with no routing args sends empty routings.
        await testScenario(
            manager: manager,
            description: "Scenario E: Request 'gemini-1.5-pro' (Non-Strict)",
            model: "gemini-1.5-pro",
            strict: false,
            expectedVendor: "OpenAI" // First registered service (OpenAI) becomes active by default if not specified
        )
    }
    
    private func testScenario(
        manager: LLMManager,
        description: String,
        model: String,
        strict: Bool,
        expectedVendor: String?
    ) async {
        print("\n📝 \(description)")
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: "Hello")], model: model)
        
        // Routings: if strict, we use .models([model]).
        // The manager.routeRequest method doesn't take a 'strict' bool directly exposed in the same way the test helper used it,
        // but `LLMManager.routeRequest` usually determines routings via DomainRouter or uses passed defaults.
        // To verify "Strict" routing as per our implementation, we explicitly pass the routing option.
        
        let routings: [LLMManager.Routing] = strict ? [.models([model])] : []
        
        let response = await manager.sendRequest(request, routings: routings)
        
        if let response = response {
            print("   ✅ Received response from: \(response.vendor ?? "Unknown")")
            if let expected = expectedVendor {
                if response.vendor == expected {
                    print("   🎉 SUCCESS: Routed correctly to \(expected)")
                } else {
                    print("   ⚠️ FAILURE: Expected \(expected), got \(response.vendor ?? "nil")")
                }
            } else {
                print("   ⚠️ FAILURE: Expected nil (no service), but got response from \(response.vendor ?? "nil")")
            }
        } else {
            print("   🚫 No response received (nil)")
            if expectedVendor == nil {
                print("   🎉 SUCCESS: Correctly returned nil for unsupported model in strict mode")
            } else {
                print("   ⚠️ FAILURE: Expected \(expectedVendor!), got nil")
            }
        }
    }
}

// Reuse Mock Service and Response for this example
private final class MockLLMService: LLMServiceProtocol, @unchecked Sendable {
    var name: String
    var vendor: String
    var apiKey: String?
    var requiresAPIKey = false
    var contextWindowSize: Int
    var maxOutputTokens: Int
    var inputTokenPolicy: TokenAdjustmentPolicy
    var outputTokenPolicy: TokenAdjustmentPolicy
    var systemPrompt: String?
    var defaultModel: String
    var supportedModels: [String] = []
    private let expectedResult: Result<LLMResponseProtocol, Error>
    private let streamingExpectedResult: String?

    init(name: String, vendor: String = "MockLLM", apiKey: String? = nil, requiresAPIKey: Bool = false, contextWindowSize: Int = 8192, maxOutputTokens: Int = 4096, inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits, outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits, systemPrompt: String? = nil, defaultModel: String = "mock-model", supportedModels: [String] = [], expectedResult: Result<LLMResponseProtocol, Error>, streamingExpectedResult: String? = nil) {
        self.name = name
        self.vendor = vendor
        self.apiKey = apiKey
        self.requiresAPIKey = requiresAPIKey
        self.contextWindowSize = contextWindowSize
        self.maxOutputTokens = maxOutputTokens
        self.inputTokenPolicy = inputTokenPolicy
        self.outputTokenPolicy = outputTokenPolicy
        self.systemPrompt = systemPrompt
        self.defaultModel = defaultModel
        self.supportedModels = Array(Set(supportedModels + [defaultModel]))
        self.expectedResult = expectedResult
        self.streamingExpectedResult = streamingExpectedResult
    }

    func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        switch expectedResult {
        case let .success(response): return response
        case let .failure(error): throw error
        }
    }

    func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: (@Sendable (String) -> Void)?) async throws -> LLMResponseProtocol {
        if let streamingExpectedResult = streamingExpectedResult, let onPartialResponse = onPartialResponse {
            onPartialResponse(streamingExpectedResult)
        }
        switch expectedResult {
        case let .success(response): return response
        case let .failure(error): throw error
        }
    }
}

private struct MockLLMResponse: LLMResponseProtocol {
    public var text: String
    public var vendor: String?
    public var model: String?
    public var tokenUsage: LLMTokenUsage?

    public init(text: String, vendor: String = "Test Vendor", model: String? = "MockLLM", tokenUsage: LLMTokenUsage? = nil) {
        self.text = text
        self.vendor = vendor
        self.model = model
        self.tokenUsage = tokenUsage
    }
}
