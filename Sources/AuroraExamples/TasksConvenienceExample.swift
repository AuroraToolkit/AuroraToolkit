//
//  TasksConvenienceExample.swift
//  AuroraExamples
//
//  Created on 10/18/25.
//

import AuroraCore
import AuroraLLM
import AuroraTaskLibrary
import Foundation

/// This example demonstrates the use of the new `Tasks` convenience APIs
/// for simplified interaction with AuroraTaskLibrary components.
///
/// It showcases how to perform common task operations like sentiment analysis,
/// summarization, keyword extraction, and workflow creation without needing
/// to manually set up complex task configurations.
struct TasksConvenienceExample {
    func execute() async {
        print("--- Running TasksConvenienceExample ---")
        
        // Configure default LLM service
        let anthropicKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
        
        if anthropicKey == nil {
            print("⚠️  No Anthropic API key found in .env, environment variables, or SecureStorage.")
            print("   The example will continue but API calls may fail.")
            print("   To fix: Set ANTHROPIC_API_KEY environment variable or use SecureStorage.saveAPIKey()")
        }
        
        let anthropicService = AnthropicService(apiKey: anthropicKey, logger: CustomLogger.shared)
        await Tasks.configure(with: anthropicService)
        
        // --- Before: Traditional Task Setup (for comparison) ---
        print("\n--- Traditional Task Setup (Before) ---")
        
        // Traditional way: Manual task setup with complex configuration
        let traditionalInputs = ["I love this new feature!", "This is terrible."]
        let traditionalSentimentTask = AnalyzeSentimentLLMTask(
            name: "TraditionalSentimentAnalysis",
            llmService: anthropicService,
            strings: traditionalInputs,
            detailed: false,
            maxTokens: 500,
            inputs: [:],
            logger: CustomLogger.shared
        )
        
        var traditionalWorkflow = Workflow(
            name: "TraditionalSentimentWorkflow",
            description: "Traditional sentiment analysis workflow",
            logger: CustomLogger.shared
        ) {
            traditionalSentimentTask.toComponent()
        }
        
        await traditionalWorkflow.start()
        
        // Extract results from the traditional workflow output structure
        let traditionalOutputs = traditionalWorkflow.outputs["TraditionalSentimentAnalysis.sentiments"]
        
        print("Traditional Sentiment Results:")
        if let sentimentsDict = traditionalOutputs as? [String: String] {
            // Simple format: {"text": "sentiment"}
            for (inputText, sentiment) in sentimentsDict {
                print("  • '\(inputText)' → \(sentiment)")
            }
        } else if let sentimentsDict = traditionalOutputs as? [String: [String: Any]] {
            // Detailed format: {"text": {"sentiment": "positive", "confidence": 0.95}}
            for (inputText, sentimentData) in sentimentsDict {
                if let sentiment = sentimentData["sentiment"] as? String {
                    print("  • '\(inputText)' → \(sentiment)")
                }
            }
        }
        
        // --- After: Using Tasks Convenience APIs ---
        print("\n--- Using Tasks Convenience APIs (After) ---")
        
        // 1. Simple Sentiment Analysis
        do {
            print("\n1. Sentiment analysis with Tasks.analyzeSentiment:")
            let inputTexts = [
                "I absolutely love this new feature!",
                "This is the worst experience ever.",
                "It's okay, nothing special."
            ]
            let sentimentsDict = try await Tasks.analyzeSentimentAsDictionary(inputTexts)
            print("   Sentiment analysis results:")
            for (inputText, sentiment) in sentimentsDict {
                print("     • '\(inputText)' → \(sentiment)")
            }
            
            // Single text sentiment analysis
            let singleText = "This is amazing!"
            let singleSentiment = try await Tasks.analyzeSentiment(singleText)
            print("   Single text sentiment: '\(singleText)' → \(singleSentiment)")
        } catch {
            print("   Sentiment analysis failed: \(error.localizedDescription)")
        }
        
        // 2. Text Summarization
        do {
            print("\n2. Text summarization with Tasks.summarize:")
            let longText = """
            Artificial Intelligence (AI) has revolutionized numerous industries and continues to shape the future of technology. 
            From healthcare to finance, AI applications are transforming how we work, live, and interact with the world around us. 
            Machine learning algorithms can now process vast amounts of data to identify patterns and make predictions with unprecedented accuracy. 
            Natural language processing enables computers to understand and generate human language, powering chatbots, translation services, and content creation tools. 
            Computer vision allows machines to interpret and analyze visual information, enabling applications in autonomous vehicles, medical imaging, and security systems. 
            As AI technology continues to advance, we can expect even more innovative applications that will further integrate artificial intelligence into our daily lives.
            """
            
            let summary = try await Tasks.summarize(longText)
            print("   Original text length: \(longText.count) characters")
            print("   Summary length: \(summary.count) characters")
            print("   Compression ratio: \(String(format: "%.1f", Double(summary.count) / Double(longText.count) * 100))%")
            print("   Summary: \(summary)")
        } catch {
            print("   Summarization failed: \(error.localizedDescription)")
        }
        
        // 3. Keyword Extraction
        do {
            print("\n3. Keyword extraction with Tasks.extractKeywords:")
            let articleText = "Swift is a powerful programming language developed by Apple for iOS, macOS, watchOS, and tvOS development. It combines the best of C and Objective-C without the constraints of C compatibility."
            
            let keywords = try await Tasks.extractKeywords(articleText)
            print("   Article: \(articleText)")
            print("   Extracted keywords: \(keywords.joined(separator: ", "))")
        } catch {
            print("   Keyword extraction failed: \(error.localizedDescription)")
        }
        
        // 4. Text Translation
        do {
            print("\n4. Text translation with Tasks.translate:")
            let englishText = "Hello, how are you today?"
            
            let spanishTranslation = try await Tasks.translate(englishText, to: "es")
            let frenchTranslation = try await Tasks.translate(englishText, to: "fr")
            
            print("   English: \(englishText)")
            print("   Spanish: \(spanishTranslation)")
            print("   French: \(frenchTranslation)")
        } catch {
            print("   Translation failed: \(error.localizedDescription)")
        }
        
        // 5. Entity Extraction
        do {
            print("\n5. Entity extraction with Tasks.extractEntities:")
            let newsText = "Apple Inc. announced new products at their headquarters in Cupertino, California. CEO Tim Cook presented the latest iPhone model to investors."
            
            let entities = try await Tasks.extractEntities(newsText)
            print("   Text: \(newsText)")
            print("   Extracted entities: \(entities.joined(separator: ", "))")
        } catch {
            print("   Entity extraction failed: \(error.localizedDescription)")
        }
        
        // 6. Text Categorization
        do {
            print("\n6. Text categorization with Tasks.categorize:")
            let categories = ["Technology", "Business", "Science", "Health", "Sports"]
            
            let techText = "The new iPhone features advanced AI capabilities and improved camera technology."
            let businessText = "The company reported record quarterly earnings and announced expansion plans."
            
            let techCategory = try await Tasks.categorize(techText, into: categories)
            let businessCategory = try await Tasks.categorize(businessText, into: categories)
            
            print("   '\(techText)' → \(techCategory)")
            print("   '\(businessText)' → \(businessCategory)")
        } catch {
            print("   Categorization failed: \(error.localizedDescription)")
        }
        
        // 7. Data Processing Tasks
        do {
            print("\n7. Data processing with Tasks convenience methods:")
            
            // Fetch content from a URL
            let content = try await Tasks.fetch("https://httpbin.org/json")
            print("   Fetched content length: \(content.count) characters")
            
            // Parse JSON from the fetched content
            if let jsonData = content.data(using: .utf8) {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                if let jsonDict = jsonObject as? [String: Any] {
                    print("   Successfully parsed JSON with keys: \(Array(jsonDict.keys).joined(separator: ", "))")
                    if let slideshow = jsonDict["slideshow"] as? [String: Any],
                       let title = slideshow["title"] as? String {
                        print("   Extracted slideshow title: '\(title)'")
                    }
                }
            } else {
                print("   Failed to convert content to JSON data")
            }
        } catch {
            print("   Data processing failed: \(error.localizedDescription)")
        }
        
        // 8. ML Task Integration
        do {
            print("\n8. ML task integration with Tasks convenience methods:")
            
            // Generate embeddings (this works with built-in models)
            let embedding = try await Tasks.embed("Sample text for embedding")
            print("   Generated embedding with \(embedding.count) dimensions")
            
            // Semantic search (this works with built-in models)
            let documents = [
                "Machine learning is transforming industries",
                "Swift is a powerful programming language",
                "Natural language processing enables text understanding"
            ]
            let searchResults = try await Tasks.search("programming languages", in: documents)
            print("   Semantic search results:")
            for result in searchResults {
                if let document = result["document"] as? String,
                   let score = result["score"] as? Double {
                    print("     • \(document) (score: \(String(format: "%.3f", score)))")
                }
            }
            
            // Note: Classification requires registered models
            print("   Note: Text classification requires registered models via ML.registerDefaultModel()")
        } catch {
            print("   ML task integration failed: \(error.localizedDescription)")
        }
        
        // 9. Simple Workflow Creation
        print("\n9. Simple workflow creation with AuroraCore.workflow:")
        
        var simpleWorkflow = AuroraCore.workflow("Content Analysis Pipeline") {
            AuroraCore.task("TextProcessor") { inputs in
                let inputText = inputs["text"] as? String ?? "Hello, world!"
                let wordCount = inputText.components(separatedBy: .whitespaces).count
                let charCount = inputText.count
                return [
                    "processedText": inputText.uppercased(),
                    "wordCount": wordCount,
                    "charCount": charCount,
                    "timestamp": Date().timeIntervalSince1970
                ]
            }
        }
        
        await simpleWorkflow.start()
        let outputs = simpleWorkflow.outputs
        if let processedText = outputs["TextProcessor.processedText"] as? String,
           let wordCount = outputs["TextProcessor.wordCount"] as? Int,
           let charCount = outputs["TextProcessor.charCount"] as? Int {
            print("   Workflow executed successfully!")
            print("   Processed text: '\(processedText)'")
            print("   Word count: \(wordCount), Character count: \(charCount)")
        } else {
            print("   Workflow executed but outputs not accessible")
        }
        
        print("\n--- Tasks Convenience Example Complete ---")
        print("\nKey Benefits of Tasks Convenience APIs:")
        print("• Reduced boilerplate: From 15+ lines to 1-2 lines for common operations")
        print("• Default service management: Automatic configuration of LLM services")
        print("• Consistent API patterns: Unified interface across all task types")
        print("• Better error handling: Graceful fallbacks and clear error messages")
        print("• Simplified workflow creation: Declarative workflow building")
        print("• Cross-module integration: Seamless integration with AuroraLLM and AuroraML")
    }
}
