//
//  LLMConvenience.swift
//  AuroraLLM
//
//  Created on 10/18/25.
//

import AuroraCore
import Foundation

/// Convenience APIs for common LLM operations, providing a FoundationModels-style simple interface.
///
/// This extension provides easy-to-use static methods for the most common LLM operations,
/// reducing the complexity of the standard AuroraLLM API for typical use cases.
public enum LLM {
    
    // MARK: - Service Access
    
    /// Pre-configured Anthropic service for simple usage
    public static var anthropic: AnthropicService {
        return AnthropicService.default
    }
    
    /// Pre-configured OpenAI service for simple usage
    public static var openai: OpenAIService {
        return OpenAIService.default
    }
    
    /// Pre-configured Ollama service for simple usage
    public static var ollama: OllamaService {
        return OllamaService.default
    }
    
    /// Pre-configured Foundation Model service for simple usage (if available)
    @available(iOS 26, macOS 26, visionOS 26, *)
    public static var foundation: FoundationModelService? {
        return FoundationModelService.default
    }
    
    // MARK: - Simple Send Methods
    
    /// Send a simple message to Anthropic and get a response
    /// - Parameter message: The message to send
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public static func send(_ message: String) async throws -> String {
        return try await anthropic.send(message)
    }
    
    /// Send a simple message to a specific service and get a response
    /// - Parameters:
    ///   - message: The message to send
    ///   - service: The service to use
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public static func send(_ message: String, to service: LLMServiceProtocol) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)])
        let response = try await service.sendRequest(request)
        return response.text
    }
    
    // MARK: - Streaming Methods
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public static func stream(_ message: String, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        return try await anthropic.stream(message, onPartialResponse: onPartialResponse)
    }
    
    /// Send a message with streaming response to a specific service
    /// - Parameters:
    ///   - message: The message to send
    ///   - service: The service to use
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public static func stream(_ message: String, to service: LLMServiceProtocol, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)
        let response = try await service.sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

// MARK: - Service Extensions

extension AnthropicService {
    /// Default Anthropic service instance
    public static var `default`: AnthropicService {
        return AnthropicService(name: "DefaultAnthropic", apiKey: SecureStorage.getAPIKey(for: "Anthropic"))
    }
    
    /// Send a simple message and get a response
    /// - Parameter message: The message to send
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)])
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

extension OpenAIService {
    /// Default OpenAI service instance
    public static var `default`: OpenAIService {
        return OpenAIService(name: "DefaultOpenAI", apiKey: SecureStorage.getAPIKey(for: "OpenAI"))
    }
    
    /// Send a simple message and get a response
    /// - Parameter message: The message to send
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)])
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

extension OllamaService {
    /// Default Ollama service instance
    public static var `default`: OllamaService {
        return OllamaService(name: "DefaultOllama")
    }
    
    /// Send a simple message and get a response
    /// - Parameter message: The message to send
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)])
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

@available(iOS 26, macOS 26, visionOS 26, *)
extension FoundationModelService {
    /// Default Foundation Model service instance (if available)
    public static var `default`: FoundationModelService? {
        return FoundationModelService.createIfAvailable()
    }
    
    /// Send a simple message and get a response
    /// - Parameter message: The message to send
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)])
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}
