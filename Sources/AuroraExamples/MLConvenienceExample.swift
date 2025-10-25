//
//  MLConvenienceExample.swift
//  AuroraExamples
//
//  Created on 10/18/25.
//

import AuroraCore
import AuroraML
import Foundation
import NaturalLanguage

/// This example demonstrates the use of the new `ML` convenience APIs
/// for simplified interaction with Machine Learning services.
///
/// It showcases how to perform common ML tasks like classification,
/// embedding generation, semantic search, and intent extraction
/// without needing to manually set up services or MLRequest objects.
struct MLConvenienceExample {
    func execute() async {
        print("--- Running MLConvenienceExample ---")
        
        // --- Before: Traditional ML Service Setup (for comparison) ---
        print("\n--- Traditional ML Service Setup (Before) ---")
        
        // Traditional way: Manual service setup with MLRequest
        let traditionalDocuments = [
            "Machine learning is transforming industries",
            "Swift is a powerful programming language",
            "Natural language processing enables text understanding"
        ]
        
        // Traditional embedding service setup
        guard let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english) else {
            print("❌ English sentence embedding not available")
            return
        }
        
        let traditionalEmbeddingService = EmbeddingService(
            name: "TraditionalEmbedding",
            embedding: sentenceEmbedding,
            logger: CustomLogger.shared
        )
        
        // Traditional semantic search setup
        let traditionalSearchService = SemanticSearchService(
            name: "TraditionalSearch",
            embeddingService: traditionalEmbeddingService,
            documents: traditionalDocuments,
            topK: 2,
            logger: CustomLogger.shared
        )
        
        // Traditional request/response pattern
        let traditionalRequest = MLRequest(inputs: ["query": "programming languages"])
        do {
            let traditionalResponse = try await traditionalSearchService.run(request: traditionalRequest)
            if let results = traditionalResponse.outputs["results"] as? [[String: Any]] {
                print("Traditional Search Results:")
                for result in results {
                    if let document = result["document"] as? String,
                       let score = result["score"] as? Double {
                        print("  • \(document) (score: \(String(format: "%.3f", score)))")
                    }
                }
            }
        } catch {
            print("Traditional search failed: \(error.localizedDescription)")
        }
        
        // Traditional classification setup
        let modelsDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("models")
        let blogClassifierURL = modelsDir.appendingPathComponent("BlogCategoriesClassifier.mlmodelc")
        
        if let blogModel = try? NLModel(contentsOf: blogClassifierURL) {
            let traditionalClassificationService = ClassificationService(
                name: "TraditionalBlogClassifier",
                model: blogModel,
                scheme: "category",
                maxResults: 3,
                logger: CustomLogger.shared
            )
            
            let traditionalClassificationRequest = MLRequest(inputs: ["strings": ["Building a SwiftUI app with Core Data"]])
            do {
                let traditionalClassificationResponse = try await traditionalClassificationService.run(request: traditionalClassificationRequest)
                if let tags = traditionalClassificationResponse.outputs["tags"] as? [Tag] {
                    print("Traditional Classification Results:")
                    for tag in tags {
                        print("  • \(tag.label) (confidence: \(String(format: "%.3f", tag.confidence ?? 0)))")
                    }
                }
            } catch {
                print("Traditional classification failed: \(error.localizedDescription)")
            }
        }
        
        // --- After: Using ML Convenience APIs ---
        print("\n--- Using ML Convenience APIs (After) ---")
        
        // 1. Simple Embedding Generation
        do {
            print("\n1. Generating embeddings with ML.embeddings:")
            let embeddings = try await ML.embeddings.embed("Hello, world!")
            print("   Generated embedding with \(embeddings.count) dimensions")
            
            // Calculate similarity between two texts
            let similarity = try await ML.embeddings.similarity(
                between: "Machine learning is amazing",
                and: "AI technology is incredible"
            )
            print("   Similarity score: \(String(format: "%.3f", similarity))")
        } catch {
            print("   Embedding generation failed: \(error.localizedDescription)")
        }
        
        // 2. Semantic Search with Default Embeddings
        do {
            print("\n2. Semantic search with ML convenience APIs:")
            let documents = [
                "Swift is a modern programming language developed by Apple",
                "Machine learning algorithms can learn from data patterns",
                "Natural language processing helps computers understand text",
                "iOS development requires knowledge of Swift and UIKit",
                "Deep learning uses neural networks with multiple layers"
            ]
            
            // Create search service with default embeddings
            let searchService = SemanticSearchService.withDefaultEmbeddings(
                name: "DocumentSearch",
                documents: documents,
                topK: 3
            )
            
            // Simple search
            let results = try await searchService.search("Apple programming")
            print("   Search results for 'Apple programming':")
            for result in results {
                if let document = result["document"] as? String,
                   let score = result["score"] as? Double {
                    print("     • \(document) (score: \(String(format: "%.3f", score)))")
                }
            }
            
            // Find most similar document
            if let mostSimilar = try await searchService.findMostSimilar(to: "neural networks") {
                print("   Most similar to 'neural networks': \(mostSimilar)")
            }
        } catch {
            print("   Semantic search failed: \(error.localizedDescription)")
        }
        
        // 3. Classification using existing models
        do {
            print("\n3. Text classification with existing models:")
            
            // Load the blog categories classifier
            let modelsDir = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .appendingPathComponent("models")
            let blogClassifierURL = modelsDir.appendingPathComponent("BlogCategoriesClassifier.mlmodelc")
            let supportClassifierURL = modelsDir.appendingPathComponent("SupportTicketsClassifier.mlmodelc")
            
            if let blogModel = try? NLModel(contentsOf: blogClassifierURL) {
                let blogService = ClassificationService(
                    name: "BlogCategories",
                    model: blogModel,
                    scheme: "category",
                    maxResults: 3,
                    logger: CustomLogger.shared
                )
                
                let blogText = "Building a SwiftUI app with Core Data integration and custom animations"
                let blogTags = try await blogService.classify(blogText)
                print("   Blog classification for: '\(blogText)'")
                for tag in blogTags {
                    print("     • \(tag.label) (confidence: \(String(format: "%.3f", tag.confidence ?? 0)))")
                }
            }
            
            if let supportModel = try? NLModel(contentsOf: supportClassifierURL) {
                let supportService = ClassificationService(
                    name: "SupportTickets",
                    model: supportModel,
                    scheme: "ticketType",
                    maxResults: 2,
                    logger: CustomLogger.shared
                )
                
                let supportText = "I can't log into my account and keep getting an error message"
                let supportTags = try await supportService.classify(supportText)
                print("   Support ticket classification for: '\(supportText)'")
                for tag in supportTags {
                    print("     • \(tag.label) (confidence: \(String(format: "%.3f", tag.confidence ?? 0)))")
                }
            }
        } catch {
            print("   Classification failed: \(error.localizedDescription)")
        }
        
        // 4. Intent Extraction using existing models
        do {
            print("\n4. Intent extraction with existing models:")
            
            // Load the support tickets classifier for intent extraction
            let modelsDir = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .appendingPathComponent("models")
            let supportClassifierURL = modelsDir.appendingPathComponent("SupportTicketsClassifier.mlmodelc")
            
            if let supportModel = try? NLModel(contentsOf: supportClassifierURL) {
                let intentService = IntentExtractionService(
                    name: "SupportIntentExtraction",
                    model: supportModel,
                    maxResults: 2,
                    logger: CustomLogger.shared
                )
                
                let intentTexts = [
                    "I need help resetting my password",
                    "My account was charged twice this month",
                    "The app keeps crashing when I try to upload photos"
                ]
                
                for text in intentTexts {
                    let intents = try await intentService.extractIntents(from: text)
                    print("   Intent extraction for: '\(text)'")
                    for intent in intents {
                        if let name = intent["name"] as? String,
                           let confidence = intent["confidence"] as? Double {
                            print("     • \(name) (confidence: \(String(format: "%.3f", confidence)))")
                        }
                    }
                }
            }
        } catch {
            print("   Intent extraction failed: \(error.localizedDescription)")
        }
        
        // 5. Advanced Workflow Example
        do {
            print("\n5. Advanced ML workflow combining multiple services:")
            
            let documents = [
                "The weather is sunny today",
                "I need to buy groceries",
                "Can you help me with my homework?",
                "What's the latest news about technology?",
                "I love listening to music"
            ]
            
            // Create a search service
            let searchService = SemanticSearchService.withDefaultEmbeddings(
                name: "AdvancedSearch",
                documents: documents,
                topK: 2
            )
            
            // Search for different types of queries
            let queries = ["weather", "shopping", "help", "technology", "entertainment"]
            
            for query in queries {
                if let topResult = try await searchService.topResult(for: query) {
                    print("   Query: '\(query)' → \(topResult.document) (score: \(String(format: "%.3f", topResult.score)))")
                }
            }
        } catch {
            print("   Advanced workflow failed: \(error.localizedDescription)")
        }
        
        print("\n--- ML Convenience Example Complete ---")
        print("\nKey Benefits of ML Convenience APIs:")
        print("• Reduced boilerplate: From 10+ lines to 1-2 lines for common operations")
        print("• Default service management: Automatic setup of common ML services")
        print("• Consistent API patterns: Unified interface across all ML operations")
        print("• Better error handling: Graceful fallbacks and clear error messages")
        print("• Simplified service access: Direct methods without MLManager overhead")
    }
}
