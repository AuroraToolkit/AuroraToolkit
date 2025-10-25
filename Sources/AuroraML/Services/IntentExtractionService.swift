//
//  IntentExtractionService.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 5/14/25.
//

import AuroraCore
import Foundation
import NaturalLanguage
import CoreML

/// `IntentExtractionService` uses a `ClassificationService` to extract one or more intents from input text, returning a structured list of intent dictionaries.
///
/// - **Inputs**
///    - `strings`: `[String]` — one or more texts to classify into intents.
/// - **Outputs**
///    - `intents`: `[[String: Any]]` — an array of intent dictionaries for each string, each containing:
///        - `name`: `String` — the predicted intent label.
///        - `confidence`: `Double` — the confidence score for that intent.
///
/// You can configure the maximum number of intents returned via the `maxResults` parameter.
public final class IntentExtractionService: MLServiceProtocol {
    public var name: String

    private let classifier: ClassificationService

    /// - Parameters:
    ///    - name: Optionally pass the name of the service, defaults to "IntentExtractionService".
    ///    - model: A compiled `NLModel` trained to predict intents (e.g. "playMusic", "setTimer").
    ///    - maxResults: How many top intents to return.
    ///    - logger: Optional logger for debug.
    public init(
        name: String = "IntentExtractionService",
        model: NLModel,
        maxResults: Int = 3,
        logger: CustomLogger? = nil
    ) {
        self.name = name
        classifier = ClassificationService(
            name: "IntentExtraction",
            model: model,
            scheme: "intent",
            maxResults: maxResults,
            logger: logger
        )
    }

    public func run(request: MLRequest) async throws -> MLResponse {
        let resp = try await classifier.run(request: request)
        // classifier returns MLResponse.outputs["tags"] as [Tag]
        guard let tags = resp.outputs["tags"] as? [Tag] else {
            throw NSError(
                domain: name,
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Missing 'tags' in classification response"]
            )
        }

        // Now reshape into an "intents" array of dictionaries
        let intents: [[String: Any]] = tags.map { tag in
            [
                "name": tag.label,
                "confidence": tag.confidence ?? 0,
            ]
        }

        return MLResponse(outputs: ["intents": intents], info: nil)
    }
}

// MARK: - Convenience Extensions

extension IntentExtractionService {
    /// Default intent extraction service
    /// Note: This requires an intent classification model to be registered
    public static var `default`: IntentExtractionService {
        // This will be set up when a model is registered via ML.registerDefaultModel
        // For now, we'll create a service that will fail gracefully when used without a proper model
        // In real usage, this would be replaced with actual model loading
        fatalError("Default intent extraction service requires a model to be registered. Use ML.registerDefaultModel(for: .intents, from: modelURL) first.")
    }
    
    /// Extract intents from a single text string
    /// - Parameter text: The text to analyze for intents
    /// - Returns: Array of intent dictionaries with names and confidence scores
    /// - Throws: An error if intent extraction fails
    public func extractIntents(from text: String) async throws -> [[String: Any]] {
        let request = MLRequest(inputs: ["strings": [text]])
        let response = try await run(request: request)
        return response.outputs["intents"] as? [[String: Any]] ?? []
    }
    
    /// Extract intents from multiple text strings
    /// - Parameter texts: Array of texts to analyze for intents
    /// - Returns: Array of intent dictionaries with names and confidence scores
    /// - Throws: An error if intent extraction fails
    public func extractIntents(from texts: [String]) async throws -> [[String: Any]] {
        let request = MLRequest(inputs: ["strings": texts])
        let response = try await run(request: request)
        return response.outputs["intents"] as? [[String: Any]] ?? []
    }
    
    /// Get the top intent from a text
    /// - Parameter text: The text to analyze for intents
    /// - Returns: The top intent with highest confidence, or nil if no results
    /// - Throws: An error if intent extraction fails
    public func topIntent(from text: String) async throws -> (name: String, confidence: Double)? {
        let intents = try await extractIntents(from: text)
        guard let topIntent = intents.first,
              let name = topIntent["name"] as? String,
              let confidence = topIntent["confidence"] as? Double else {
            return nil
        }
        return (name: name, confidence: confidence)
    }
    
    /// Check if a specific intent is present in the text
    /// - Parameters:
    ///   - intent: The intent name to check for
    ///   - text: The text to analyze
    ///   - threshold: Minimum confidence threshold (default: 0.5)
    /// - Returns: True if the intent is detected above the threshold
    /// - Throws: An error if intent extraction fails
    public func hasIntent(_ intent: String, in text: String, threshold: Double = 0.5) async throws -> Bool {
        let intents = try await extractIntents(from: text)
        return intents.contains { intentDict in
            guard let name = intentDict["name"] as? String,
                  let confidence = intentDict["confidence"] as? Double else {
                return false
            }
            return name == intent && confidence >= threshold
        }
    }
}
