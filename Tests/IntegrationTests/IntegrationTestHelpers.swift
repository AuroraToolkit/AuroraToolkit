//
//  IntegrationTestHelpers.swift
//  AuroraToolkit Integration Tests
//
//  Created for enhanced integration testing with Apple Foundation Model support
//

import Foundation
import XCTest
#if canImport(FoundationModels)
import FoundationModels
#endif
@testable import AuroraCore
@testable import AuroraLLM

/// Test helper that provides an LLM service for integration tests.
///
/// This helper attempts to use Apple Foundation Model when available (iOS 26+, macOS 26+),
/// and falls back to a mock service when Apple Foundation Model is not available (e.g., in CI/CD).
///
/// **Usage:**
/// ```swift
/// let service = try IntegrationTestHelpers.getLLMService()
/// let response = try await service.sendRequest(request)
/// ```
enum IntegrationTestHelpers {
    
    /// Returns an LLM service for integration testing.
    ///
    /// - Returns: A Apple Foundation Model service if available, otherwise a mock service
    /// - Throws: XCTSkip if neither service is available (shouldn't happen in practice)
    static func getLLMService() throws -> LLMServiceProtocol {
        // Try Apple Foundation Model first (iOS 26+, macOS 26+)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            #if canImport(FoundationModels)
            if let foundationService = FoundationModelService.createIfAvailable() {
                return foundationService
            }
            #endif
        }
        
        // Fall back to mock service for CI/CD or when Apple Foundation Model unavailable
        let mockResponse = IntegrationMockLLMResponse(
            text: "This is a mock response for integration testing. The test is running in an environment where Apple Foundation Model is not available.",
            model: "mock-model",
            tokenUsage: LLMTokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)
        )
        
        return IntegrationMockLLMService(
            name: "IntegrationTestMockLLM",
            vendor: "Mock",
            expectedResult: .success(mockResponse)
        )
    }
    
    /// Checks if Apple Foundation Model is available for testing.
    ///
    /// - Returns: `true` if Apple Foundation Model is available, `false` otherwise
    static func isFoundationModelAvailable() -> Bool {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            #if canImport(FoundationModels)
            return FoundationModelService.isAvailable()
            #else
            return false
            #endif
        }
        return false
    }
    
    /// Creates a simple test request for integration testing.
    ///
    /// - Parameter content: The prompt content
    /// - Returns: A configured LLMRequest
    static func makeTestRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            maxTokens: 256
        )
    }
}

// MARK: - Mock Helpers for Integration Tests

/// Mock LLM response for integration tests when Apple Foundation Model is unavailable
private struct IntegrationMockLLMResponse: LLMResponseProtocol {
    var text: String
    var model: String?
    var tokenUsage: LLMTokenUsage?
    var vendor: String?
    
    var id: String? { nil }
    var finishReason: String? { "stop" }
    var systemFingerprint: String? { nil }
    
    init(text: String, model: String, tokenUsage: LLMTokenUsage?) {
        self.text = text
        self.model = model
        self.tokenUsage = tokenUsage
        self.vendor = "Mock"
    }
}

/// Mock LLM service for integration tests when Apple Foundation Model is unavailable
private final class IntegrationMockLLMService: LLMServiceProtocol, @unchecked Sendable {
    var name: String
    var vendor: String
    var apiKey: String? = nil
    var requiresAPIKey = false
    var contextWindowSize: Int = 8192
    var maxOutputTokens: Int = 4096
    var inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var systemPrompt: String? = nil
    var defaultModel: String = "mock-model"
    
    private let expectedResult: Result<LLMResponseProtocol, Error>
    
    init(name: String, vendor: String, expectedResult: Result<LLMResponseProtocol, Error>) {
        self.name = name
        self.vendor = vendor
        self.expectedResult = expectedResult
    }
    
    func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: ((String) -> Void)?) async throws -> LLMResponseProtocol {
        if let onPartialResponse = onPartialResponse {
            switch expectedResult {
            case .success(let response):
                // Simulate streaming by calling the callback with the response text
                onPartialResponse(response.text)
                return response
            case .failure(let error):
                throw error
            }
        }
        
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

