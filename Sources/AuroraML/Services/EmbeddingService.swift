//
//  EmbeddingService.swift
//  AuroraML
//
//  Created by Dan Murrell Jr on 05/15/25.
//

import AuroraCore
import Foundation
import NaturalLanguage

/// A service that converts text into fixed-length vector embeddings using Apple's `NLEmbedding`.
///
/// - **Inputs**
///    - `strings`: `[String]` of texts to embed.
/// - **Outputs**
///    - `embeddings`: `[[Double]]` — an array (one per input string) of floating-point vectors.
///
/// ### Example
/// ```swift
/// // load the built-in sentence embedding for English
/// guard let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) else {
///    fatalError("Embedding model unavailable")
/// }
/// let enbeddingService = EmbeddingService(
///    name: "EnglishSentenceEmbedding",
///    embedding: sentenceEmbedding
/// )
/// let texts = ["Hello world", "How are you?"]
/// let resp = try await enbeddingService.run(
///    request: MLRequest(inputs: ["strings": texts])
/// )
/// let vectors = resp.outputs["embeddings"] as! [[Double]]
/// // vectors[0].count == sentenceEmbedding.dimension
/// ```
public final class EmbeddingService: MLServiceProtocol {
    public var name: String
    public let embedding: NLEmbedding
    private let logger: CustomLogger?

    /// - Parameters:
    ///    - name: Identifier for this service.
    ///    - embedding: An `NLEmbedding` instance (e.g. `.wordEmbedding(for:)` or `.sentenceEmbedding(for:)`).
    ///    - logger: Optional logger for debugging.
    public init(name: String, embedding: NLEmbedding, logger: CustomLogger? = nil) {
        self.name = name
        self.embedding = embedding
        self.logger = logger
    }

    public func run(request: MLRequest) async throws -> MLResponse {
        guard let texts = request.inputs["strings"] as? [String] else {
            logger?.error("Missing 'strings' input", category: name)
            throw NSError(
                domain: name,
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Input 'strings' missing"]
            )
        }

        var allVectors = [[Double]]()
        for text in texts {
            guard let vec = embedding.vector(for: text) else {
                logger?.error("Failed to embed text: \(text)", category: name)
                throw NSError(
                    domain: name,
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Embedding failed for text: \(text)"]
                )
            }
            allVectors.append(vec)
        }

        return MLResponse(outputs: ["embeddings": allVectors], info: nil)
    }
}

// MARK: - Convenience Extensions

extension EmbeddingService {
    /// Default sentence embedding service using Apple's built-in English sentence embeddings
    public static var defaultSentence: EmbeddingService {
        guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            fatalError("English sentence embedding not available")
        }
        return EmbeddingService(
            name: "DefaultSentenceEmbedding",
            embedding: embedding,
            logger: CustomLogger.shared
        )
    }
    
    /// Default word embedding service using Apple's built-in English word embeddings
    public static var defaultWord: EmbeddingService {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            fatalError("English word embedding not available")
        }
        return EmbeddingService(
            name: "DefaultWordEmbedding",
            embedding: embedding,
            logger: CustomLogger.shared
        )
    }
    
    /// Generate embedding for a single text string
    /// - Parameter text: The text to embed
    /// - Returns: The embedding vector
    /// - Throws: An error if embedding generation fails
    public func embed(_ text: String) async throws -> [Double] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await run(request: request)
        let embeddings = response.outputs["embeddings"] as? [[Double]] ?? []
        return embeddings.first ?? []
    }
    
    /// Generate embeddings for multiple text strings
    /// - Parameter texts: Array of texts to embed
    /// - Returns: Array of embedding vectors (one per input text)
    /// - Throws: An error if embedding generation fails
    public func embed(_ texts: [String]) async throws -> [[Double]] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await run(request: request)
        return response.outputs["embeddings"] as? [[Double]] ?? []
    }
    
    /// Calculate cosine similarity between two texts
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Cosine similarity score between 0 and 1
    /// - Throws: An error if embedding generation fails
    public func similarity(between text1: String, and text2: String) async throws -> Double {
        let embeddings = try await embed([text1, text2])
        guard embeddings.count == 2 else {
            throw MLError.invalidInput("Failed to generate embeddings for both texts")
        }
        
        let vec1 = embeddings[0]
        let vec2 = embeddings[1]
        
        // Calculate cosine similarity
        let dot = zip(vec1, vec2).map(*).reduce(0, +)
        let mag1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let mag2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))
        
        return (mag1 > 0 && mag2 > 0) ? dot / (mag1 * mag2) : 0
    }
}
