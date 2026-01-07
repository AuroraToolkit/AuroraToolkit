//
//  OllamaLLMResponse.swift
//
//
//  Created by Dan Murrell Jr on 9/15/24.
//

import Foundation

/// Represents the response from Ollama's LLM models, conforming to `LLMResponseProtocol`.
///
/// The Ollama Chat API returns a message object containing the role and content, along with model metadata.
public struct OllamaLLMResponse: LLMResponseProtocol, Codable {
    /// The vendor associated with the response.
    public var vendor: String? = "Ollama"

    /// The model used for generating the response, made optional as per the protocol.
    public var model: String?

    ///  The timestamp when the response was created.
    public var createdAt: String?

    /// The generated message returned by the Ollama Chat API.
    public let message: OllamaMessage?

    /// A boolean indicating if the model has finished generating the response.
    public let done: Bool

    /// The number of tokens in the prompt.
    public let promptEvalCount: Int?

    /// The number of tokens in the generated response.
    public let evalCount: Int?

    /// Represents a message in the Ollama chat response.
    public struct OllamaMessage: Codable, Sendable {
        public let role: String
        public let content: String
    }

    /// Token usage provided by the Ollama Chat API.
    public var tokenUsage: LLMTokenUsage? {
        guard let promptTokens = promptEvalCount, let completionTokens = evalCount else {
            return nil
        }
        return LLMTokenUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: promptTokens + completionTokens
        )
    }

    // MARK: - LLMResponseProtocol Conformance

    /// Returns the generated text content from the Ollama response message.
    public var text: String {
        return message?.content ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
        case promptEvalCount = "prompt_eval_count"
        case evalCount = "eval_count"
    }

    public init(
        vendor: String? = "Ollama",
        model: String? = nil,
        createdAt: String? = nil,
        message: OllamaMessage? = nil,
        done: Bool,
        promptEvalCount: Int? = nil,
        evalCount: Int? = nil
    ) {
        self.vendor = vendor
        self.model = model
        self.createdAt = createdAt
        self.message = message
        self.done = done
        self.promptEvalCount = promptEvalCount
        self.evalCount = evalCount
    }
}
