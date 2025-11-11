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
/// This struct provides easy-to-use static methods for the most common LLM operations,
/// reducing the complexity of the standard AuroraLLM API for typical use cases.
///
/// The convenience APIs will use your explicitly configured service first (via `LLM.configure(with: service)`).
/// If no service is configured, they will fall back to Apple's Foundation Model (on iOS 26+/macOS 26+).
/// If neither is available, you must configure a default service.
///
/// ### Example Usage
/// ```swift
/// // Simple message sending (uses configured service first, then Apple Foundation Model)
/// let response = try await LLM.send("Hello, world!")
///
/// // Streaming response
/// try await LLM.stream("Tell me a story") { partial in
///     print(partial)
/// }
///
/// // Configure a default service if Apple Foundation Model is not available
/// LLM.configure(with: LLM.anthropic)
///
/// // Using specific service
/// let response = try await LLM.send("Hello", to: LLM.anthropic)
/// ```
public struct LLM {
    
    // MARK: - Default Service Management
    
    /// Actor to manage the default service state in a concurrency-safe manner
    private actor DefaultServiceManager {
        private var service: LLMServiceProtocol?
        
        func set(_ service: LLMServiceProtocol) {
            self.service = service
        }
        
        func get() -> LLMServiceProtocol? {
            return service
        }
    }
    
    /// The configured default service manager for convenience operations
    private static let defaultServiceManager = DefaultServiceManager()
    
    /// Get the default service for convenience operations
    /// - Returns: The configured service first, then Apple Foundation Model if available
    /// - Throws: `LLMServiceError.noDefaultServiceConfigured` if no service is available
    public static func getDefaultService() async throws -> LLMServiceProtocol {
        if let defaultService = await defaultServiceManager.get() {
            return defaultService
        }

        // Next, try to use Apple Foundation Model if available
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            if let foundationService = FoundationModelService.createIfAvailable() {
                return foundationService
            }
        }
        
        // If default or Apple Foundation Model is not available, throw `noDefaultServiceConfigured` error
        throw LLMServiceError.noDefaultServiceConfigured
    }
    
    // MARK: - Service Access
    
    /// Pre-configured Anthropic service for simple usage (uses ProcessInfo environment for API key)
    public static var anthropic: AnthropicService {
        return AnthropicService.default
    }
    
    /// Pre-configured OpenAI service for simple usage (uses ProcessInfo environment for API key)
    public static var openai: OpenAIService {
        return OpenAIService.default
    }
    
    /// Pre-configured Google service for simple usage (uses ProcessInfo environment for API key)
    public static var google: GoogleService {
        return GoogleService.default
    }
    
    /// Pre-configured Ollama service for simple usage
    public static var ollama: OllamaService {
        return OllamaService.default
    }
    
    /// Pre-configured Apple Foundation Model service for simple usage (if available)
    @available(iOS 26, macOS 26, visionOS 26, *)
    public static var foundation: FoundationModelService? {
        return FoundationModelService.default
    }
    
    // MARK: - Configuration
    
    /// Configure the default service for simple operations
    /// - Parameter service: The LLM service to use as default
    public static func configure(with service: LLMServiceProtocol) async {
        await defaultServiceManager.set(service)
    }
    
    // MARK: - Simple Send Methods
    
    /// Send a simple message using the default service (configured service, or Apple Foundation Model if available)
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails or no default service is configured
    public static func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let service = try await getDefaultService()
        return try await send(message, to: service, maxTokens: maxTokens)
    }
    
    /// Send a simple message to a specific service and get a response
    /// - Parameters:
    ///   - message: The message to send
    ///   - service: The service to use
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public static func send(_ message: String, to service: LLMServiceProtocol, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await service.sendRequest(request)
        return response.text
    }
    
    // MARK: - Streaming Methods
    
    /// Send a message with streaming response using the default service, or Apple Foundation Model if available
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails or no default service is configured
    public static func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let service = try await getDefaultService()
        return try await stream(message, to: service, onPartialResponse: onPartialResponse, maxTokens: maxTokens)
    }
    
    /// Send a message with streaming response to a specific service
    /// - Parameters:
    ///   - message: The message to send
    ///   - service: The service to use
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public static func stream(_ message: String, to service: LLMServiceProtocol, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
        let response = try await service.sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

// MARK: - Service Extensions

extension AnthropicService {
    /// Default Anthropic service instance (uses ProcessInfo environment for API key)
    public static var `default`: AnthropicService {
        let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        return AnthropicService(name: "DefaultAnthropic", apiKey: apiKey)
    }
    
    /// Create a new AnthropicService instance with an explicit API key
    /// - Parameter key: The API key to use
    /// - Returns: A new AnthropicService instance with the provided key
    public func apiKey(_ key: String) -> AnthropicService {
        return AnthropicService(
            name: self.name,
            apiKey: key,
            defaultModel: self.defaultModel,
            contextWindowSize: self.contextWindowSize,
            maxOutputTokens: self.maxOutputTokens,
            inputTokenPolicy: self.inputTokenPolicy,
            outputTokenPolicy: self.outputTokenPolicy,
            systemPrompt: self.systemPrompt,
            urlSession: self.urlSession,
            logger: self.logger
        )
    }
    
    /// Send a simple message and get a response
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

extension OpenAIService {
    /// Default OpenAI service instance (uses ProcessInfo environment for API key)
    public static var `default`: OpenAIService {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        return OpenAIService(name: "DefaultOpenAI", apiKey: apiKey)
    }
    
    /// Create a new OpenAIService instance with an explicit API key
    /// - Parameter key: The API key to use
    /// - Returns: A new OpenAIService instance with the provided key
    public func apiKey(_ key: String) -> OpenAIService {
        return OpenAIService(
            name: self.name,
            baseURL: self.baseURL,
            apiKey: key,
            defaultModel: self.defaultModel,
            contextWindowSize: self.contextWindowSize,
            maxOutputTokens: self.maxOutputTokens,
            inputTokenPolicy: self.inputTokenPolicy,
            outputTokenPolicy: self.outputTokenPolicy,
            systemPrompt: self.systemPrompt,
            urlSession: self.urlSession,
            logger: self.logger
        )
    }
    
    /// Send a simple message and get a response
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}

extension GoogleService {
    /// Default Google service instance (uses ProcessInfo environment for API key)
    public static var `default`: GoogleService {
        let apiKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"]
        return GoogleService(name: "DefaultGoogle", apiKey: apiKey)
    }
    
    /// Create a new GoogleService instance with an explicit API key
    /// - Parameter key: The API key to use
    /// - Returns: A new GoogleService instance with the provided key
    public func apiKey(_ key: String) -> GoogleService {
        return GoogleService(
            name: self.name,
            apiKey: key,
            defaultModel: self.defaultModel,
            contextWindowSize: self.contextWindowSize,
            maxOutputTokens: self.maxOutputTokens,
            inputTokenPolicy: self.inputTokenPolicy,
            outputTokenPolicy: self.outputTokenPolicy,
            systemPrompt: self.systemPrompt,
            urlSession: self.urlSession,
            logger: self.logger
        )
    }
    
    /// Send a simple message and get a response
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
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
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
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
    /// - Parameters:
    ///   - message: The message to send
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The response text
    /// - Throws: An error if the request fails
    public func send(_ message: String, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens)
        let response = try await sendRequest(request)
        return response.text
    }
    
    /// Send a message with streaming response
    /// - Parameters:
    ///   - message: The message to send
    ///   - onPartialResponse: Closure called with each partial response
    ///   - maxTokens: Maximum number of tokens to generate (default: 1024)
    /// - Returns: The complete response text
    /// - Throws: An error if the request fails
    public func stream(_ message: String, onPartialResponse: @escaping (String) -> Void, maxTokens: Int = 1024) async throws -> String {
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], maxTokens: maxTokens, stream: true)
        let response = try await sendStreamingRequest(request, onPartialResponse: onPartialResponse)
        return response.text
    }
}
