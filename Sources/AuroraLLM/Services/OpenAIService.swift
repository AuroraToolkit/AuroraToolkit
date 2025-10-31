//
//  OpenAIService.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 9/1/24.
//

import AuroraCore
import Foundation
import os.log

/// `OpenAIService` implements the `LLMServiceProtocol` to interact with the OpenAI API.
/// This service allows flexible configuration for different models and settings, and now provides
/// enhanced error handling using `LLMServiceError`.
public class OpenAIService: LLMServiceProtocol {
    /// A logger for recording information and errors within the `AnthropicService`.
    private let logger: CustomLogger?

    /// The name of the service vendor, required by the protocol.
    public let vendor = "OpenAI"

    /// The name of the service instance, which can be customized during initialization
    public var name: String

    /// The base url for the OpenAI API.
    public var baseURL: String

    /// The maximum context window size (total tokens, input + output) supported by the service, defaults to 128k.
    public var contextWindowSize: Int

    /// The maximum number of tokens allowed for output (completion) in a single request, defaults to 4k.
    public var maxOutputTokens: Int

    /// Specifies the policy to handle input tokens when they exceed the service's input token limit, defaults to `.adjustToServiceLimits`.
    public var inputTokenPolicy: TokenAdjustmentPolicy

    /// Specifies the policy to handle output tokens when they exceed the service's max output token limit, defaults to `adjustToServiceLimits`.
    public var outputTokenPolicy: TokenAdjustmentPolicy

    /// The default system prompt for this service, used to set the behavior or persona of the model.
    public var systemPrompt: String?

    /// The API key for authenticating requests, stored in memory to avoid keychain access during requests
    private let apiKey: String?

    /// The URL session used to send basic requests.
    var urlSession: URLSession

    /// Initializes a new `OpenAIService` instance with the given API key.
    ///
    /// - Parameters:
    ///    - name: The name of the service instance (default is `"OpenAI"`).
    ///    - apiKey: The API key used for authenticating requests to the OpenAI API.
    ///    - baseURL: The base URL for the OpenAI API. Defaults to "https://api.openai.com".
    ///    - contextWindowSize: The size of the context window used by the service. Defaults to 128k.
    ///    - maxOutputTokens: The maximum number of tokens allowed in a request. Defaults to 16k.
    ///    - inputTokenPolicy: The policy to handle input tokens exceeding the service's limit. Defaults to `.adjustToServiceLimits`.
    ///    - outputTokenPolicy: The policy to handle output tokens exceeding the service's limit. Defaults to `.adjustToServiceLimits`.
    ///    - systemPrompt: The default system prompt for this service, used to set the behavior or persona of the model.
    ///    - urlSession: The `URLSession` instance used for network requests. Defaults to a `.default` configuration.
    ///    - logger: An optional `CustomLogger` instance for logging. Defaults to `nil`.
    public init(name: String = "OpenAI", baseURL: String = "https://api.openai.com", apiKey: String?, contextWindowSize: Int = 128_000, maxOutputTokens: Int = 16384, inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits, outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits, systemPrompt: String? = nil, urlSession: URLSession = URLSession(configuration: .default), logger: CustomLogger? = nil) {
        self.name = name
        self.baseURL = baseURL
        self.contextWindowSize = contextWindowSize
        self.maxOutputTokens = maxOutputTokens
        self.inputTokenPolicy = inputTokenPolicy
        self.outputTokenPolicy = outputTokenPolicy
        self.systemPrompt = systemPrompt
        self.urlSession = urlSession
        self.logger = logger
        // Store API key in memory and optionally save to keychain for persistence
        self.apiKey = apiKey ?? SecureStorage.getAPIKey(for: name)
        if let apiKey = self.apiKey {
            try? SecureStorage.saveAPIKey(apiKey, for: name)
        }
    }

    // MARK: - Transport Resolution

    private enum Transport {
        case responses
        case legacyChat
    }

    private func resolveTransport(for model: String?, options: LLMRequestOptions?) -> Transport {
        // 1) Explicit option
        if let explicit = options?.transport {
            switch explicit {
            case .responses: return .responses
            case .legacyChat: return .legacyChat
            case .auto: break
            }
        }

        // 2) Env override
        if let env = ProcessInfo.processInfo.environment["AURORA_OPENAI_TRANSPORT"]?.lowercased() {
            if env == "responses" { return .responses }
            if env == "chat" || env == "chatcompletions" || env == "legacychat" || env == "legacy_chat" { return .legacyChat }
        }

        // 3) Model capability map (default)
        if let model = model?.lowercased() {
            if model.hasPrefix("gpt-5") || model.hasPrefix("o3") {
                return .responses
            }
        }
        return .legacyChat
    }

    /// Prepares input for Responses API as an array of message objects
    /// Returns tuple: (instructions: String?, input: [[String: String]])
    private func prepareResponsesInput(from request: LLMRequest) -> (instructions: String?, input: [[String: String]]) {
        // Extract system prompt as instructions parameter
        let effectiveSystem = resolveSystemPrompt(from: request, serviceSystemPrompt: systemPrompt)
        
        // Convert non-system messages to array format (matching Chat Completions style)
        let nonSystem = request.messages.filter { $0.role != .system }
        let inputArray = nonSystem.map { ["role": $0.role.rawValue, "content": $0.content] }
        
        return (instructions: effectiveSystem, input: inputArray)
    }

    // MARK: - Non-streaming Request

    /// Sends a request to the OpenAI API asynchronously without streaming.
    ///
    /// - Parameter request: The `LLMRequest` containing the messages and model configuration.
    ///
    /// - Returns: The `LLMResponseProtocol` containing the generated text or an error if the request fails.
    /// - Throws: `LLMServiceError` if the request encounters an issue (e.g., missing API key, invalid response, etc.).
    public func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        try validateStreamingConfig(request, expectStreaming: false)

        let transport = resolveTransport(for: request.model, options: request.options)

        // Use in-memory API key to avoid blocking keychain access
        guard let apiKey = apiKey else {
            throw LLMServiceError.missingAPIKey
        }

        guard var components = URLComponents(string: baseURL) else {
            throw LLMServiceError.invalidURL
        }

        var body: [String: Any] = [:]

        switch transport {
        case .legacyChat:
            components.path = "/v1/chat/completions"
            // Use helper function for consistent system prompt handling
            let messagesPayload = prepareOpenAIMessagesPayload(from: request, serviceSystemPrompt: systemPrompt)
            body = [
                "model": request.model ?? "gpt-4o-mini",
                "messages": messagesPayload,
                "max_tokens": request.maxTokens,
                "temperature": request.temperature,
                "top_p": request.options?.topP ?? 1.0,
                "frequency_penalty": request.options?.frequencyPenalty ?? 0.0,
                "presence_penalty": request.options?.presencePenalty ?? 0.0,
                "stop": request.options?.stopSequences ?? [],
                "stream": false,
            ]
        case .responses:
            components.path = "/v1/responses"
            let (instructions, inputArray) = prepareResponsesInput(from: request)
            let model = (request.model ?? "gpt-5-nano").lowercased()
            body = [
                "model": request.model ?? "gpt-5-nano",
                "input": inputArray,
                "max_output_tokens": request.maxTokens,
            ]
            // Use instructions parameter for system prompts (per Responses API spec)
            if let instructions = instructions, !instructions.isEmpty {
                body["instructions"] = instructions
            }
            // Add reasoning settings for GPT-5 family (required parameter)
            if model.hasPrefix("gpt-5") {
                body["reasoning"] = ["effort": "low"]
            }
            // Note: Temperature is not supported by gpt-5 models in Responses API
            // and we exclude it to minimize unnecessary parameters
        }

        guard let url = components.url else { throw LLMServiceError.invalidURL }

        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        logger?.debug("OpenAIService [sendRequest] Transport=\(transport == .responses ? "responses" : "legacyChat"). Keys: \(body.keys)", category: "OpenAIService")

        let (data, response) = try await urlSession.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorBody = String(data: data, encoding: .utf8) ?? "Non-UTF8 error body"
            logger?.error("OpenAIService [sendRequest] Error response (\(statusCode)): \(errorBody)", category: "OpenAIService")
            throw LLMServiceError.invalidResponse(statusCode: statusCode)
        }

        switch transport {
        case .legacyChat:
            let decodedResponse = try JSONDecoder().decode(OpenAILLMResponse.self, from: data)
            return decodedResponse.changingVendor(to: vendor)
        case .responses:
            let decoded = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: data)
            return decoded.changingVendor(to: vendor)
        }
    }

    // MARK: - Streaming Request

    /// Sends a request to the OpenAI API asynchronously with streaming support.
    ///
    /// - Parameters:
    ///    - request: The `LLMRequest` containing the messages and model configuration.
    ///    - onPartialResponse: A closure that handles partial responses during streaming.
    ///
    /// - Returns: The `LLMResponseProtocol` containing the final text generated by the LLM.
    /// - Throws: `LLMServiceError` if the request encounters an issue (e.g., missing API key, invalid response, etc.).
    public func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: ((String) -> Void)?) async throws -> LLMResponseProtocol {
        try validateStreamingConfig(request, expectStreaming: true)

        let transport = resolveTransport(for: request.model, options: request.options)

        // URL and request setup
        guard var components = URLComponents(string: baseURL) else {
            throw LLMServiceError.invalidURL
        }

        var body: [String: Any] = [:]

        switch transport {
        case .legacyChat:
            components.path = "/v1/chat/completions"
            let messagesPayload = prepareOpenAIMessagesPayload(from: request, serviceSystemPrompt: systemPrompt)
            body = [
                "model": request.model ?? "gpt-4o-mini",
                "messages": messagesPayload,
                "max_tokens": request.maxTokens,
                "temperature": request.temperature,
                "top_p": request.options?.topP ?? 1.0,
                "frequency_penalty": request.options?.frequencyPenalty ?? 0.0,
                "presence_penalty": request.options?.presencePenalty ?? 0.0,
                "stop": request.options?.stopSequences ?? [],
                "stream": true,
            ]
        case .responses:
            components.path = "/v1/responses"
            let (instructions, inputArray) = prepareResponsesInput(from: request)
            let model = (request.model ?? "gpt-5-nano").lowercased()
            body = [
                "model": request.model ?? "gpt-5-nano",
                "input": inputArray,
                "max_output_tokens": request.maxTokens,
                "stream": true,
            ]
            // Use instructions parameter for system prompts (per Responses API spec)
            if let instructions = instructions, !instructions.isEmpty {
                body["instructions"] = instructions
            }
            // Add reasoning settings for GPT-5 family (required parameter)
            if model.hasPrefix("gpt-5") {
                body["reasoning"] = ["effort": "low"]
            }
            // Note: Temperature is not supported by gpt-5 models in Responses API
            // and we exclude it to minimize unnecessary parameters
        }

        guard let url = components.url else { throw LLMServiceError.invalidURL }

        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if transport == .responses { urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept") }

        logger?.debug("OpenAIService [sendStreamingRequest] Transport=\(transport == .responses ? "responses" : "legacyChat"). Keys: \(body.keys).", category: "OpenAIService")

        // Use in-memory API key to avoid blocking keychain access
        guard let apiKey = apiKey else {
            throw LLMServiceError.missingAPIKey
        }
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        return try await withCheckedThrowingContinuation { continuation in
            switch transport {
            case .legacyChat:
                let streamingDelegate = StreamingDelegate(
                    vendor: vendor,
                    model: request.model ?? "gpt-4o-mini",
                    logger: logger,
                    onPartialResponse: onPartialResponse ?? { _ in },
                    continuation: continuation
                )
                let session = URLSession(configuration: .default, delegate: streamingDelegate, delegateQueue: nil)
                let task = session.dataTask(with: urlRequest)
                task.resume()
            case .responses:
                let streamingDelegate = ResponsesStreamingDelegate(
                    vendor: vendor,
                    model: request.model ?? "gpt-5-nano",
                    logger: logger,
                    onPartialResponse: onPartialResponse ?? { _ in },
                    continuation: continuation
                )
                let session = URLSession(configuration: .default, delegate: streamingDelegate, delegateQueue: nil)
                let task = session.dataTask(with: urlRequest)
                task.resume()
            }
        }
    }

    class StreamingDelegate: NSObject, URLSessionDataDelegate {
        private let vendor: String
        private let model: String
        private let onPartialResponse: (String) -> Void
        private let continuation: CheckedContinuation<LLMResponseProtocol, Error>
        private var accumulatedContent = ""
        private var finalResponse: LLMResponseProtocol?
        private let logger: CustomLogger?

        init(vendor: String,
             model: String,
             logger: CustomLogger? = nil,
             onPartialResponse: @escaping (String) -> Void,
             continuation: CheckedContinuation<LLMResponseProtocol, Error>)
        {
            self.vendor = vendor
            self.model = model
            self.logger = logger
            self.onPartialResponse = onPartialResponse
            self.continuation = continuation
        }

        func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
            guard let responseText = String(data: data, encoding: .utf8) else { return }

            logger?.debug("Streaming response received. Processing...", category: "OpenAIService.StreamingDelegate")

            for line in responseText.split(separator: "\n") {
                if line == "data: [DONE]" {
                    // Finalize the response
                    let usage = OpenAILLMResponse.Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)
                    let finalResponse = OpenAILLMResponse(
                        choices: [OpenAILLMResponse.Choice(
                            delta: nil,
                            message: OpenAILLMResponse.Choice.Message(role: "assistant", content: accumulatedContent),
                            finishReason: "stop"
                        )],
                        usage: usage,
                        vendor: vendor,
                        model: model
                    )
                    continuation.resume(returning: finalResponse)
                    return
                }

                // Remove `data:` prefix and decode JSON
                if line.starts(with: "data:") {
                    let jsonString = line.replacingOccurrences(of: "data: ", with: "")

                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let partialResponse = try JSONDecoder().decode(OpenAILLMResponse.self, from: jsonData)

                            // Append content from `delta`
                            if let partialContent = partialResponse.choices.first?.delta?.content {
                                accumulatedContent += partialContent
                                onPartialResponse(partialContent)
                            }
                        } catch {
                            logger?.error("OpenAIService Failed to decode partial response: \(error)", category: "OpenAIService.StreamingDelegate")
                        }
                    }
                }
            }
        }

        func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                continuation.resume(throwing: error)
            }
        }
    }

    class ResponsesStreamingDelegate: NSObject, URLSessionDataDelegate {
        private let vendor: String
        private let model: String
        private let onPartialResponse: (String) -> Void
        private let continuation: CheckedContinuation<LLMResponseProtocol, Error>
        private var accumulatedContent = ""
        private var buffer = Data()
        private let logger: CustomLogger?

        struct AnyEvent: Decodable {
            let type: String?
            let delta: String?
        }

        init(vendor: String,
             model: String,
             logger: CustomLogger? = nil,
             onPartialResponse: @escaping (String) -> Void,
             continuation: CheckedContinuation<LLMResponseProtocol, Error>)
        {
            self.vendor = vendor
            self.model = model
            self.logger = logger
            self.onPartialResponse = onPartialResponse
            self.continuation = continuation
        }

        func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
            guard let responseText = String(data: data, encoding: .utf8) else { return }

            logger?.debug("Responses streaming chunk received.", category: "OpenAIService.ResponsesStreamingDelegate")

            for line in responseText.split(separator: "\n") {
                if line == "data: [DONE]" { finalizeAndReturn(); return }
                if line.hasPrefix("data:") {
                    let jsonString = line.replacingOccurrences(of: "data: ", with: "")
                    if let jsonData = jsonString.data(using: .utf8) {
                        if let event = try? JSONDecoder().decode(AnyEvent.self, from: jsonData) {
                            if let t = event.type, t.contains("response.output_text.delta"), let d = event.delta, !d.isEmpty {
                                accumulatedContent += d
                                onPartialResponse(d)
                            } else if let t = event.type, t == "response.completed" {
                                finalizeAndReturn(); return
                            }
                        }
                    }
                }
            }
        }

        private func finalizeAndReturn() {
            let usage = OpenAILLMResponse.Usage(promptTokens: 0, completionTokens: 0, totalTokens: 0)
            let finalResponse = OpenAILLMResponse(
                choices: [OpenAILLMResponse.Choice(
                    delta: nil,
                    message: OpenAILLMResponse.Choice.Message(role: "assistant", content: accumulatedContent),
                    finishReason: "stop"
                )],
                usage: usage,
                vendor: vendor,
                model: model
            )
            continuation.resume(returning: finalResponse)
        }

        func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error { continuation.resume(throwing: error) }
        }
    }
}

// MARK: - Responses API Models (minimal)

fileprivate struct OpenAIResponsesResponse: Codable, LLMResponseProtocol {
    struct OutputItem: Codable {
        struct ContentPart: Codable {
            let type: String?
            let text: String?
        }
        let content: [ContentPart]?
    }

    let id: String?
    var vendor: String?
    let model: String?
    let output: [OutputItem]?

    var text: String {
        let parts = output?.flatMap { $0.content ?? [] } ?? []
        let texts = parts.compactMap { $0.text }
        return texts.joined()
    }

    var tokenUsage: LLMTokenUsage? { nil }
}
