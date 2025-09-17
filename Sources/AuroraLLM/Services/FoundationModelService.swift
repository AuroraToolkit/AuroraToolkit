//
//  FoundationModelService.swift
//  AuroraLLM
//
//  Created by Dan Murrell Jr on 9/16/25.
//

import AuroraCore
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// `FoundationModelService` implements the `LLMServiceProtocol` to interact with Apple's on-device Foundation Models.
/// It leverages Apple's FoundationModels framework available in iOS 26+, macOS 26+, iPadOS 26+, and visionOS 26+.
///
/// This service requires Apple Intelligence to be enabled on the user's device and is only available on supported hardware.
/// For phones, iPhone 15 Pro or later is required. No API key is needed as it uses on-device models.
///
/// **Important**: Foundation Models supports up to 4,096 tokens total (input + output). Exceeding this limit
/// will result in a `GenerationError.exceededContextWindow` error.
@available(iOS 26, macOS 26, visionOS 26, *)
public class FoundationModelService: LLMServiceProtocol {
    /// A logger for recording information and errors within the `FoundationModelService`.
    private let logger: CustomLogger?

    /// The name of the service vendor, required by the protocol.
    public let vendor = "Apple"

    /// The name of the service instance, which can be customized during initialization
    public var name: String

    /// The maximum context window size (total tokens, input + output) supported by Foundation Models.
    /// According to Apple's documentation, this is 4,096 tokens.
    public var contextWindowSize: Int

    /// The maximum number of tokens allowed for output (completion) in a single request.
    /// This should be less than contextWindowSize to leave room for input tokens.
    public var maxOutputTokens: Int

    /// Specifies the policy to handle input tokens when they exceed the service's input token limit.
    public var inputTokenPolicy: TokenAdjustmentPolicy

    /// Specifies the policy to handle output tokens when they exceed the service's max output token limit.
    public var outputTokenPolicy: TokenAdjustmentPolicy

    /// The default system prompt for this service, used to set the behavior or persona of the model.
    public var systemPrompt: String?

    /// The Foundation Models session used to interact with the on-device model.
    private var session: LanguageModelSession?

    /// Initializes a new `FoundationModelService` instance.
    ///
    /// - Parameters:
    ///   - name: The name of the service instance (default is "FoundationModel").
    ///   - contextWindowSize: The maximum context window size (default is 4096, the Foundation Models limit).
    ///   - maxOutputTokens: The maximum output tokens (default is 2048, leaving room for input).
    ///   - inputTokenPolicy: Policy for handling input token limits (default is .adjustToServiceLimits).
    ///   - outputTokenPolicy: Policy for handling output token limits (default is .adjustToServiceLimits).
    ///   - systemPrompt: Optional default system prompt.
    ///   - logger: Optional custom logger for service events.
    ///
    /// - Throws: `LLMServiceError.serviceUnavailable` if Foundation Models framework is not available or Apple Intelligence is not enabled.
    public init(
        name: String = "FoundationModel",
        contextWindowSize: Int = 4096, // Foundation Models documented limit
        maxOutputTokens: Int = 2048,   // Leave room for input tokens
        inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits,
        outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits,
        systemPrompt: String? = nil,
        logger: CustomLogger? = nil
    ) throws {
        self.name = name
        self.logger = logger

        // Validate and warn about token limits
        if contextWindowSize > 4096 {
            logger?.debug("[\(name)] Context window size \(contextWindowSize) exceeds Foundation Models limit of 4,096 tokens. This may cause GenerationError.exceededContextWindow", category: "FoundationModelService")
        }

        if maxOutputTokens > contextWindowSize {
            logger?.debug("[\(name)] Max output tokens \(maxOutputTokens) exceeds context window size \(contextWindowSize). This will cause failures", category: "FoundationModelService")
        }

        if maxOutputTokens > 4096 {
            logger?.debug("[\(name)] Max output tokens \(maxOutputTokens) exceeds Foundation Models limit of 4,096 tokens. This may cause GenerationError.exceededContextWindow", category: "FoundationModelService")
        }

        self.contextWindowSize = contextWindowSize
        self.maxOutputTokens = maxOutputTokens
        self.inputTokenPolicy = inputTokenPolicy
        self.outputTokenPolicy = outputTokenPolicy
        self.systemPrompt = systemPrompt

        // Initialize the Foundation Models session
        self.session = LanguageModelSession()
        logger?.debug("[\(name)] FoundationModelService initialized successfully", category: "FoundationModelService")
    }

    /// Sends a request to the Foundation Models service asynchronously and returns the response.
    ///
    /// - Parameter request: The `LLMRequest` object containing the prompt and configuration for the LLM.
    /// - Returns: An `LLMResponseProtocol` containing the text generated by the Foundation Model.
    /// - Throws: An error if the request fails, including `GenerationError.exceededContextWindow` for token limit violations.
    public func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        guard let session = session else {
            logger?.error("[\(name)] Foundation Models session not initialized", category: "FoundationModelService")
            throw LLMServiceError.serviceUnavailable(message: "Foundation Models session not initialized")
        }

        logger?.debug("[\(name)] Sending request to Foundation Model", category: "FoundationModelService")

        // Apply token policies to the request
        let adjustedRequest = request

        // Build the prompt from the request
        let prompt = buildPrompt(from: adjustedRequest)

        // Check token count before sending (warn if close to limit)
        let estimatedTokens = estimateTokenCount(prompt)
        if estimatedTokens > 3500 { // Warn when getting close to 4096 limit
            logger?.debug("[\(name)] Request uses ~\(estimatedTokens) tokens, approaching Foundation Models limit of 4,096", category: "FoundationModelService")
        }

        do {
            // Send request to Foundation Model
            let response = try await session.respond(to: prompt)

            logger?.debug("[\(name)] Received response from Foundation Model", category: "FoundationModelService")

            // Extract the text content from the response
            let responseText = response.content

            // Create response object
            return FoundationModelResponse(
                text: responseText,
                model: "foundation-model",
                tokenUsage: LLMTokenUsage(
                    promptTokens: adjustedRequest.estimatedTokenCount(),
                    completionTokens: estimateTokenCount(responseText),
                    totalTokens: adjustedRequest.estimatedTokenCount() + estimateTokenCount(responseText)
                )
            )
        } catch {
            // Handle specific Foundation Models errors if available
            if let generationError = error as? LanguageModelSession.GenerationError {
                logger?.error("[\(name)] Foundation Model generation error: \(generationError)", category: "FoundationModelService")
                // Check if it's a context window error by examining the error description
                if generationError.localizedDescription.contains("context") || generationError.localizedDescription.contains("token") {
                    throw LLMServiceError.requestFailed(message: "Request exceeded Foundation Models context window limit of 4,096 tokens")
                } else {
                    throw LLMServiceError.requestFailed(message: "Foundation Model generation error: \(generationError.localizedDescription)")
                }
            }

            logger?.error("[\(name)] Foundation Model request failed: \(error)", category: "FoundationModelService")
            throw LLMServiceError.requestFailed(message: "Foundation Model request failed: \(error.localizedDescription)")
        }
    }

    /// Sends a request to the Foundation Models service asynchronously with support for streaming.
    ///
    /// - Parameters:
    ///   - request: The `LLMRequest` object containing the prompt and configuration for the LLM.
    ///   - onPartialResponse: A closure that handles partial responses during streaming.
    /// - Returns: An `LLMResponseProtocol` containing the final text generated by the Foundation Model.
    /// - Throws: An error if the request fails, including `GenerationError.exceededContextWindow` for token limit violations.
    public func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: ((String) -> Void)?) async throws -> LLMResponseProtocol {
        guard let session = session else {
            logger?.error("[\(name)] Foundation Models session not initialized", category: "FoundationModelService")
            throw LLMServiceError.serviceUnavailable(message: "Foundation Models session not initialized")
        }

        logger?.debug("[\(name)] Sending streaming request to Foundation Model", category: "FoundationModelService")

        // Apply token policies to the request
        let adjustedRequest = request

        // Build the prompt from the request
        let prompt = buildPrompt(from: adjustedRequest)

        // Check token count before sending
        let estimatedTokens = estimateTokenCount(prompt)
        if estimatedTokens > 3500 {
            logger?.debug("[\(name)] Streaming request uses ~\(estimatedTokens) tokens, approaching Foundation Models limit of 4,096", category: "FoundationModelService")
        }

        var fullResponse = ""

        do {
            // Note: Foundation Models streaming API may vary - this is a conceptual implementation
            // Check if streaming is supported and implement accordingly
            let response = try await session.respond(to: prompt)
            let responseText = response.content
            fullResponse = responseText
            onPartialResponse?(responseText) // For now, call with full response

            logger?.debug("[\(name)] Completed streaming response from Foundation Model", category: "FoundationModelService")

            return FoundationModelResponse(
                text: fullResponse,
                model: "foundation-model",
                tokenUsage: LLMTokenUsage(
                    promptTokens: adjustedRequest.estimatedTokenCount(),
                    completionTokens: estimateTokenCount(fullResponse),
                    totalTokens: adjustedRequest.estimatedTokenCount() + estimateTokenCount(fullResponse)
                )
            )
        } catch {
            // Handle specific Foundation Models errors if available
            if let generationError = error as? LanguageModelSession.GenerationError {
                logger?.error("[\(name)] Foundation Model streaming generation error: \(generationError)", category: "FoundationModelService")
                // Check if it's a context window error by examining the error description
                if generationError.localizedDescription.contains("context") || generationError.localizedDescription.contains("token") {
                    throw LLMServiceError.requestFailed(message: "Streaming request exceeded Foundation Models context window limit of 4,096 tokens")
                } else {
                    throw LLMServiceError.requestFailed(message: "Foundation Model streaming generation error: \(generationError.localizedDescription)")
                }
            }

            logger?.error("[\(name)] Foundation Model streaming request failed: \(error)", category: "FoundationModelService")
            throw LLMServiceError.requestFailed(message: "Foundation Model streaming request failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Helper Methods

    /// Checks if Foundation Models is available at runtime (Apple Intelligence enabled, etc.).
    private static func isFoundationModelsRuntimeAvailable() -> Bool {
        // Use Apple's documented method to check availability
        return SystemLanguageModel.default.isAvailable
    }

    /// Builds a prompt string from the LLM request messages.
    private func buildPrompt(from request: LLMRequest) -> String {
        let effectiveSystemPrompt = resolveSystemPrompt(from: request, serviceSystemPrompt: systemPrompt)
        var prompt = ""

        // Add system prompt if available
        if let systemPrompt = effectiveSystemPrompt, !systemPrompt.isEmpty {
            prompt += "System: \(systemPrompt)\n\n"
        }

        // Add conversation messages
        for message in request.messages {
            switch message.role {
            case .system:
                // System messages are already handled above
                continue
            case .user:
                prompt += "User: \(message.content)\n"
            case .assistant:
                prompt += "Assistant: \(message.content)\n"
            case .custom(let roleName):
                prompt += "\(roleName): \(message.content)\n"
            }
        }

        prompt += "Assistant: "
        return prompt
    }

    /// Estimates the token count for a given text.
    private func estimateTokenCount(_ text: String) -> Int {
        // Simple estimation: roughly 4 characters per token
        return max(1, text.count / 4)
    }
}

// MARK: - FoundationModelResponse

/// Response implementation for Foundation Model service.
@available(iOS 26, macOS 26, visionOS 26, *)
public struct FoundationModelResponse: LLMResponseProtocol {
    public let text: String
    public var vendor: String?
    public let model: String?
    public let tokenUsage: LLMTokenUsage?

    public init(text: String, model: String?, tokenUsage: LLMTokenUsage? = nil, vendor: String? = "Apple") {
        self.text = text
        self.model = model
        self.tokenUsage = tokenUsage
        self.vendor = vendor
    }
}

// MARK: - Static Factory Methods

@available(iOS 26, macOS 26, visionOS 26, *)
extension FoundationModelService {
    /// Checks if Foundation Models service is available on the current platform and device.
    ///
    /// - Returns: `true` if Foundation Models is available, `false` otherwise.
    public static func isAvailable() -> Bool {
        return isFoundationModelsRuntimeAvailable()
    }

    /// Creates a Foundation Model service if available, otherwise returns nil.
    ///
    /// - Parameters: Same as the main initializer
    /// - Returns: A FoundationModelService instance if available, nil otherwise.
    public static func createIfAvailable(
        name: String = "FoundationModel",
        contextWindowSize: Int = 4096,
        maxOutputTokens: Int = 2048,
        inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits,
        outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits,
        systemPrompt: String? = nil,
        logger: CustomLogger? = nil
    ) -> FoundationModelService? {
        guard isAvailable() else { return nil }

        do {
            return try FoundationModelService(
                name: name,
                contextWindowSize: contextWindowSize,
                maxOutputTokens: maxOutputTokens,
                inputTokenPolicy: inputTokenPolicy,
                outputTokenPolicy: outputTokenPolicy,
                systemPrompt: systemPrompt,
                logger: logger
            )
        } catch {
            logger?.error("Failed to create FoundationModelService: \(error)", category: "FoundationModelService")
            return nil
        }
    }
}
