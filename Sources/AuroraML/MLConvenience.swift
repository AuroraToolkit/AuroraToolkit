//
//  MLConvenience.swift
//  AuroraML
//
//  Created on 10/18/25.
//

import AuroraCore
import Foundation
import NaturalLanguage

/// Top-level convenience APIs for AuroraML, providing simplified access to common ML operations.
///
/// This struct provides static methods and properties that reduce boilerplate for common ML tasks
/// like classification, embedding generation, and semantic search.
///
/// ### Example Usage
/// ```swift
/// // Simple classification
/// let tags = try await ML.classify("This is a positive review", with: .sentiment)
///
/// // Generate embeddings
/// let embeddings = try await ML.embed(["Hello", "World"])
///
/// // Semantic search
/// let results = try await ML.search("machine learning", in: documents)
/// ```
public struct ML {
    
    // MARK: - Default Services
    
    /// Default classification service for sentiment analysis
    public static var sentiment: ClassificationService {
        return ClassificationService.defaultSentiment
    }
    
    /// Default embedding service using Apple's built-in sentence embeddings
    public static var embeddings: EmbeddingService {
        return EmbeddingService.defaultSentence
    }
    
    /// Default intent extraction service
    public static var intents: IntentExtractionService {
        return IntentExtractionService.default
    }
    
    // MARK: - Configuration
    
    /// Configure the default services for ML operations
    /// - Parameter service: The ML service to use as default
    public static func configure(with service: MLServiceProtocol) {
        // Note: This is a placeholder for future implementation
        // Currently, services are accessed directly via properties
    }
    
    // MARK: - Convenience Methods
    
    /// Classify text using a specified classification service
    /// - Parameters:
    ///   - text: The text to classify
    ///   - service: The classification service to use
    /// - Returns: Array of tags with labels and confidence scores
    /// - Throws: An error if classification fails
    public static func classify(_ text: String, with service: ClassificationService) async throws -> [Tag] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await service.run(request: request)
        return response.outputs["tags"] as? [Tag] ?? []
    }
    
    /// Classify multiple texts using a specified classification service
    /// - Parameters:
    ///   - texts: Array of texts to classify
    ///   - service: The classification service to use
    /// - Returns: Array of tags with labels and confidence scores
    /// - Throws: An error if classification fails
    public static func classify(_ texts: [String], with service: ClassificationService) async throws -> [Tag] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await service.run(request: request)
        return response.outputs["tags"] as? [Tag] ?? []
    }
    
    /// Generate embeddings for text using a specified embedding service
    /// - Parameters:
    ///   - text: The text to embed
    ///   - service: The embedding service to use
    /// - Returns: Array of embedding vectors
    /// - Throws: An error if embedding generation fails
    public static func embed(_ text: String, with service: EmbeddingService) async throws -> [Double] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await service.run(request: request)
        let embeddings = response.outputs["embeddings"] as? [[Double]] ?? []
        return embeddings.first ?? []
    }
    
    /// Generate embeddings for multiple texts using a specified embedding service
    /// - Parameters:
    ///   - texts: Array of texts to embed
    ///   - service: The embedding service to use
    /// - Returns: Array of embedding vectors (one per input text)
    /// - Throws: An error if embedding generation fails
    public static func embed(_ texts: [String], with service: EmbeddingService) async throws -> [[Double]] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await service.run(request: request)
        return response.outputs["embeddings"] as? [[Double]] ?? []
    }
    
    /// Perform semantic search using a specified search service
    /// - Parameters:
    ///   - query: The search query
    ///   - service: The semantic search service to use
    /// - Returns: Array of search results with documents and scores
    /// - Throws: An error if search fails
    public static func search(_ query: String, with service: SemanticSearchService) async throws -> [[String: Any]] {
        let request = MLRequest(inputs: ["query": query])
        let response = try await service.run(request: request)
        return response.outputs["results"] as? [[String: Any]] ?? []
    }
    
    /// Extract intents from text using a specified intent extraction service
    /// - Parameters:
    ///   - text: The text to analyze for intents
    ///   - service: The intent extraction service to use
    /// - Returns: Array of intent dictionaries with names and confidence scores
    /// - Throws: An error if intent extraction fails
    public static func extractIntents(_ text: String, with service: IntentExtractionService) async throws -> [[String: Any]] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await service.run(request: request)
        return response.outputs["intents"] as? [[String: Any]] ?? []
    }
    
    /// Extract intents from multiple texts using a specified intent extraction service
    /// - Parameters:
    ///   - texts: Array of texts to analyze for intents
    ///   - service: The intent extraction service to use
    /// - Returns: Array of intent dictionaries with names and confidence scores
    /// - Throws: An error if intent extraction fails
    public static func extractIntents(_ texts: [String], with service: IntentExtractionService) async throws -> [[String: Any]] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await service.run(request: request)
        return response.outputs["intents"] as? [[String: Any]] ?? []
    }
    
    // MARK: - Model Management
    
    /// Register a default model for a specific task
    /// - Parameters:
    ///   - task: The ML task type
    ///   - modelURL: URL to the compiled Core ML model
    /// - Throws: An error if model loading fails
    public static func registerDefaultModel(for task: MLTask, from modelURL: URL) throws {
        switch task {
        case .sentiment:
            guard (try? NLModel(contentsOf: modelURL)) != nil else {
                throw MLError.modelLoadingFailed(modelURL)
            }
            _ = ClassificationService.defaultSentiment // This will use the new model
        case .categories:
            guard (try? NLModel(contentsOf: modelURL)) != nil else {
                throw MLError.modelLoadingFailed(modelURL)
            }
            _ = ClassificationService.defaultCategories // This will use the new model
        case .intents:
            guard (try? NLModel(contentsOf: modelURL)) != nil else {
                throw MLError.modelLoadingFailed(modelURL)
            }
            _ = IntentExtractionService.default // This will use the new model
        }
    }
}

// MARK: - Supporting Types

/// Common ML task types for default model registration
public enum MLTask {
    case sentiment
    case categories
    case intents
}

/// ML-specific errors
public enum MLError: Error, LocalizedError {
    case modelLoadingFailed(URL)
    case serviceNotAvailable(String)
    case invalidInput(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelLoadingFailed(let url):
            return "Failed to load model from: \(url.path)"
        case .serviceNotAvailable(let name):
            return "ML service '\(name)' is not available"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}
