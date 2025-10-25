//
//  ClassificationService.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 5/9/25.
//

import AuroraCore
import Foundation
import NaturalLanguage
import CoreML

/// `ClassificationService` implements `MLServiceProtocol` using Apple's `NLModel` text classifiers.
///
/// It classifies each input string using the provided `NLModel` to predict a label and optional confidence, and returns an array of `Tag` objects, where each  tag corresponds to an input string.
///
/// - **Inputs**
///    - `strings`: An array of `String` texts to tag.
/// - **Outputs**
///    - `tags`: A `Tag` array, where each tag corresponds to an input string. Each `Tag` includes:
///        - `token`: the substring that was tagged
///        - `label`: the tag or category
///        - `scheme`: the tagging scheme identifier
///        - `confidence`: optional confidence score
///        - `start`: starting index of the tagged token in the source string
///        - `length`: length of the tagged token in the source string
///
/// **Note**: Your Core ML model must be a compiled text classifier loaded into an `NLModel` (e.g. `NLModel(contentsOf: myModelURL)`).
///
/// ### Example
/// ```swift
/// // Load a compiled Core ML text classifier:
/// let model = try! NLModel(contentsOf: URL(fileURLWithPath: "TextClassifier.mlmodelc"))
/// let service = ClassificationService(
///    name: "TextClassifier",
///    model: model,
///    scheme: "TextClassifier",
///    maxResults: 3,
///    logger: CustomLogger.shared
/// )
///
/// let strings = ["I love Swift!", "This is okay."]
/// let request = MLRequest(inputs: ["strings": strings])
///
/// // Execute:
/// let outputs = try await service.run(request: request)
/// let tags = outputs["tags"] as? [Tag]
/// for tag in tags {
///     print("\(tag.token) → \(tag.label) @\(tag.confidence ?? 0)")
/// }
/// ```
public final class ClassificationService: MLServiceProtocol {
    public var name: String
    private let model: NLModel
    private let scheme: String
    private let maxResults: Int
    private let logger: CustomLogger?

    /// - Parameters:
    ///    - name: Identifier for this service.
    ///    - model: A compiled `NLModel` text‐classifier.
    ///    - scheme: The tag scheme identifier to set on each `Tag`.
    ///    - maxResults: How many top labels to return per input string.
    ///    - logger: Optional logger for debugging.
    public init(
        name: String,
        model: NLModel,
        scheme: String,
        maxResults: Int = 3,
        logger: CustomLogger? = nil
    ) {
        self.name = name
        self.model = model
        self.scheme = scheme
        self.maxResults = maxResults
        self.logger = logger
    }

    public func run(request: MLRequest) async throws -> MLResponse {
        guard let texts = request.inputs["strings"] as? [String] else {
            logger?.error("Missing 'strings' input", category: name)
            throw NSError(domain: name, code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Input 'strings' missing"])
        }

        var tags: [Tag] = []

        for text in texts {
            let hypos = model.predictedLabelHypotheses(
                for: text,
                maximumCount: maxResults
            )

            for (label, score) in hypos {
                if let logger {
                    let loggedText = text.count > 15 ? "\(text.prefix(15))..." : text
                    logger.debug("[\(name)] \(loggedText)) → \(label) @\(score)", category: name)
                }
                let tag = Tag(
                    token: text,
                    label: label,
                    scheme: scheme,
                    confidence: score,
                    start: 0,
                    length: text.count
                )
                tags.append(tag)
            }
        }

        return MLResponse(outputs: ["tags": tags], info: nil)
    }
}

// MARK: - Convenience Extensions

extension ClassificationService {
    /// Default sentiment analysis service
    /// Note: This requires a sentiment classification model to be registered
    public static var defaultSentiment: ClassificationService {
        // This will be set up when a model is registered via ML.registerDefaultModel
        // For now, we'll create a service that will fail gracefully when used without a proper model
        // In real usage, this would be replaced with actual model loading
        fatalError("Default sentiment service requires a model to be registered. Use ML.registerDefaultModel(for: .sentiment, from: modelURL) first.")
    }
    
    /// Default category classification service
    /// Note: This requires a category classification model to be registered
    public static var defaultCategories: ClassificationService {
        // This will be set up when a model is registered via ML.registerDefaultModel
        // For now, we'll create a service that will fail gracefully when used without a proper model
        // In real usage, this would be replaced with actual model loading
        fatalError("Default category service requires a model to be registered. Use ML.registerDefaultModel(for: .categories, from: modelURL) first.")
    }
    
    /// Classify a single text string
    /// - Parameter text: The text to classify
    /// - Returns: Array of tags with labels and confidence scores
    /// - Throws: An error if classification fails
    public func classify(_ text: String) async throws -> [Tag] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await run(request: request)
        return response.outputs["tags"] as? [Tag] ?? []
    }
    
    /// Classify multiple text strings
    /// - Parameter texts: Array of texts to classify
    /// - Returns: Array of tags with labels and confidence scores
    /// - Throws: An error if classification fails
    public func classify(_ texts: [String]) async throws -> [Tag] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await run(request: request)
        return response.outputs["tags"] as? [Tag] ?? []
    }
    
    /// Get the top classification result for a text
    /// - Parameter text: The text to classify
    /// - Returns: The top tag with highest confidence, or nil if no results
    /// - Throws: An error if classification fails
    public func topClassification(for text: String) async throws -> Tag? {
        let tags = try await classify(text)
        return tags.max { ($0.confidence ?? 0) < ($1.confidence ?? 0) }
    }
}
