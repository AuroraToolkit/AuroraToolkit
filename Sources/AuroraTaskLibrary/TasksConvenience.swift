//
//  TasksConvenience.swift
//  AuroraTaskLibrary
//
//  Created on 10/18/25.
//

import AuroraCore
import AuroraLLM
import AuroraML
import Foundation

/// Top-level convenience APIs for AuroraTaskLibrary, providing simplified access to common task operations.
///
/// This struct provides static methods and properties that reduce boilerplate for common task operations
/// like sentiment analysis, summarization, keyword extraction, and workflow creation.
///
/// ### Example Usage
/// ```swift
/// // Simple sentiment analysis
/// let sentiments = try await Tasks.analyzeSentiment(["I love this!", "This is terrible!"])
///
/// // Generate keywords
/// let keywords = try await Tasks.extractKeywords("Article content...")
///
/// // Create a simple workflow
/// let workflow = Tasks.workflow("Content Analysis") {
///     Tasks.fetch("https://example.com/feed.xml")
///     Tasks.parseRSS()
///     Tasks.summarize()
/// }
/// ```
public struct Tasks {
    
    // MARK: - Default Service Configuration
    
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
    
    /// The configured default service manager for task operations
    private static let defaultServiceManager = DefaultServiceManager()
    
    /// Configure the default LLM service for all task operations
    /// - Parameter service: The LLM service to use as default
    public static func configure(with service: LLMServiceProtocol) async {
        await defaultServiceManager.set(service)
    }
    
    /// Configure with a specific service type
    /// - Parameter serviceType: The type of service to configure
    public static func configure(with serviceType: LLMServiceType) async {
        let service: LLMServiceProtocol?
        switch serviceType {
        case .anthropic:
            service = LLM.anthropic
        case .openai:
            service = LLM.openai
        case .ollama:
            service = LLM.ollama
        case .foundation:
            if #available(iOS 26, macOS 26, visionOS 26, *) {
                service = LLM.foundation
            } else {
                service = nil
            }
        }
        if let service = service {
            await defaultServiceManager.set(service)
        }
    }
    
    /// Get the configured default service or throw an error
    public static func getDefaultService() async throws -> LLMServiceProtocol {
        guard let service = await defaultServiceManager.get() else {
            throw TasksError.noDefaultServiceConfigured
        }
        return service
    }
    
    // MARK: - LLM Task Convenience Methods
    
    /// Analyze sentiment of text strings
    /// - Parameters:
    ///   - strings: Array of text strings to analyze
    ///   - maxTokens: Maximum number of tokens to generate (default: 500)
    /// - Returns: Array of sentiment analysis results
    /// - Throws: An error if analysis fails
    public static func analyzeSentiment(_ strings: [String], maxTokens: Int = 500) async throws -> [String] {
        let service = try await getDefaultService()
        let task = AnalyzeSentimentLLMTask(
            name: "SentimentAnalysis",
            llmService: service,
            strings: strings,
            detailed: false,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract sentiments from the complex output structure, preserving order
        if let sentimentsDict = outputs["sentiments"] as? [String: String] {
            // Simple format: {"text": "sentiment"}
            // Return sentiments in the same order as input strings
            return strings.compactMap { inputString in
                sentimentsDict[inputString]
            }
        } else if let sentimentsDict = outputs["sentiments"] as? [String: [String: Any]] {
            // Detailed format: {"text": {"sentiment": "positive", "confidence": 0.95}}
            // Return sentiments in the same order as input strings
            return strings.compactMap { inputString in
                sentimentsDict[inputString]?["sentiment"] as? String
            }
        }
        return []
    }
    
    /// Analyze sentiment of a single text string
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - maxTokens: Maximum number of tokens to generate (default: 500)
    /// - Returns: The sentiment result
    /// - Throws: An error if analysis fails
    public static func analyzeSentiment(_ text: String, maxTokens: Int = 500) async throws -> String {
        let results = try await analyzeSentiment([text], maxTokens: maxTokens)
        return results.first ?? "unknown"
    }
    
    /// Analyze sentiment of text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to analyze
    ///   - maxTokens: Maximum number of tokens to generate (default: 500)
    /// - Returns: Dictionary mapping input text to sentiment
    /// - Throws: An error if analysis fails
    public static func analyzeSentimentAsDictionary(_ strings: [String], maxTokens: Int = 500) async throws -> [String: String] {
        let service = try await getDefaultService()
        let task = AnalyzeSentimentLLMTask(
            name: "SentimentAnalysis",
            llmService: service,
            strings: strings,
            detailed: false,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract sentiments as dictionary
        if let sentimentsDict = outputs["sentiments"] as? [String: String] {
            return sentimentsDict
        } else if let sentimentsDict = outputs["sentiments"] as? [String: [String: Any]] {
            // Convert detailed format to simple format
            return sentimentsDict.compactMapValues { sentimentData in
                sentimentData["sentiment"] as? String
            }
        }
        return [:]
    }
    
    /// Summarize text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to summarize
    ///   - maxTokens: Maximum number of tokens to generate (default: 300)
    /// - Returns: Dictionary mapping input text to summary
    /// - Throws: An error if summarization fails
    public static func summarizeAsDictionary(_ strings: [String], maxTokens: Int = 300) async throws -> [String: String] {
        let service = try await getDefaultService()
        let summarizer = Summarizer(llmService: service)
        let task = SummarizeStringsLLMTask(
            name: "Summarization",
            summarizer: summarizer,
            summaryType: .single,
            strings: strings,
            options: SummarizerOptions(maxTokens: maxTokens)
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract summaries as dictionary
        if let summariesDict = outputs["summaries"] as? [String: String] {
            return summariesDict
        }
        return [:]
    }
    
    /// Extract keywords from text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to extract keywords from
    ///   - maxTokens: Maximum number of tokens to generate (default: 200)
    /// - Returns: Dictionary mapping input text to array of keywords
    /// - Throws: An error if keyword extraction fails
    public static func extractKeywordsAsDictionary(_ strings: [String], maxTokens: Int = 200) async throws -> [String: [String]] {
        let service = try await getDefaultService()
        let task = GenerateKeywordsLLMTask(
            name: "KeywordExtraction",
            llmService: service,
            strings: strings,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract keywords as dictionary
        if let keywordsDict = outputs["keywords"] as? [String: [String]] {
            return keywordsDict
        }
        return [:]
    }
    
    /// Translate text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to translate
    ///   - targetLanguage: The target language code (e.g., "es", "fr", "de")
    ///   - maxTokens: Maximum number of tokens to generate (default: 500)
    /// - Returns: Dictionary mapping input text to translated text
    /// - Throws: An error if translation fails
    public static func translateAsDictionary(_ strings: [String], to targetLanguage: String, maxTokens: Int = 500) async throws -> [String: String] {
        let service = try await getDefaultService()
        let task = TranslateStringsLLMTask(
            name: "Translation",
            llmService: service,
            strings: strings,
            targetLanguage: targetLanguage,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract translations as dictionary
        if let translationsDict = outputs["translations"] as? [String: String] {
            return translationsDict
        }
        return [:]
    }
    
    /// Extract entities from text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to extract entities from
    ///   - maxTokens: Maximum number of tokens to generate (default: 300)
    /// - Returns: Dictionary mapping input text to array of entities
    /// - Throws: An error if entity extraction fails
    public static func extractEntitiesAsDictionary(_ strings: [String], maxTokens: Int = 300) async throws -> [String: [String]] {
        let service = try await getDefaultService()
        let task = ExtractEntitiesLLMTask(
            name: "EntityExtraction",
            llmService: service,
            strings: strings,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract entities as dictionary
        if let entitiesDict = outputs["entities"] as? [String: [String]] {
            return entitiesDict
        }
        return [:]
    }
    
    /// Categorize text strings and return as dictionary
    /// - Parameters:
    ///   - strings: Array of text strings to categorize
    ///   - categories: Array of category names
    ///   - maxTokens: Maximum number of tokens to generate (default: 200)
    /// - Returns: Dictionary mapping category to array of texts in that category
    /// - Throws: An error if categorization fails
    public static func categorizeAsDictionary(_ strings: [String], into categories: [String], maxTokens: Int = 200) async throws -> [String: [String]] {
        let service = try await getDefaultService()
        let task = CategorizeStringsLLMTask(
            name: "Categorization",
            llmService: service,
            strings: strings,
            categories: categories,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract categorized content as dictionary
        if let categorizedContent = outputs["categorizedStrings"] as? [String: [String]] {
            return categorizedContent
        }
        return [:]
    }
    
    /// Summarize text content
    /// - Parameters:
    ///   - text: The text to summarize
    ///   - maxTokens: Maximum number of tokens to generate (default: 300)
    /// - Returns: The summary
    /// - Throws: An error if summarization fails
    public static func summarize(_ text: String, maxTokens: Int = 300) async throws -> String {
        let service = try await getDefaultService()
        let summarizer = Summarizer(llmService: service)
        let task = SummarizeStringsLLMTask(
            name: "Summarization",
            summarizer: summarizer,
            summaryType: .single,
            strings: [text],
            options: SummarizerOptions(maxTokens: maxTokens)
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract summaries from the complex output structure
        if let summariesDict = outputs["summaries"] as? [String: String] {
            // Format: {"original_text": "summary"}
            return Array(summariesDict.values).first ?? text
        } else if let summariesArray = outputs["summaries"] as? [String] {
            // Direct array format
            return summariesArray.first ?? text
        }
        return text
    }
    
    /// Extract keywords from text
    /// - Parameters:
    ///   - text: The text to extract keywords from
    ///   - maxTokens: Maximum number of tokens to generate (default: 200)
    /// - Returns: Array of extracted keywords
    /// - Throws: An error if keyword extraction fails
    public static func extractKeywords(_ text: String, maxTokens: Int = 200) async throws -> [String] {
        let service = try await getDefaultService()
        let task = GenerateKeywordsLLMTask(
            name: "KeywordExtraction",
            llmService: service,
            strings: [text],
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract keywords from the complex output structure
        if let keywordsDict = outputs["keywords"] as? [String: [String]] {
            // Format: {"original_text": ["keyword1", "keyword2"]}
            return Array(keywordsDict.values.flatMap { $0 })
        } else if let keywordsArray = outputs["keywords"] as? [String] {
            // Direct array format
            return keywordsArray
        }
        return []
    }
    
    /// Translate text to a target language
    /// - Parameters:
    ///   - text: The text to translate
    ///   - targetLanguage: The target language code (e.g., "es", "fr", "de")
    ///   - maxTokens: Maximum number of tokens to generate (default: 500)
    /// - Returns: The translated text
    /// - Throws: An error if translation fails
    public static func translate(_ text: String, to targetLanguage: String, maxTokens: Int = 500) async throws -> String {
        let service = try await getDefaultService()
        let task = TranslateStringsLLMTask(
            name: "Translation",
            llmService: service,
            strings: [text],
            targetLanguage: targetLanguage,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract translations from the complex output structure
        if let translationsDict = outputs["translations"] as? [String: String] {
            // Format: {"original_text": "translated_text"}
            return Array(translationsDict.values).first ?? text
        } else if let translationsArray = outputs["translations"] as? [String] {
            // Direct array format
            return translationsArray.first ?? text
        }
        return text
    }
    
    /// Extract entities from text
    /// - Parameters:
    ///   - text: The text to extract entities from
    ///   - maxTokens: Maximum number of tokens to generate (default: 300)
    /// - Returns: Array of extracted entities
    /// - Throws: An error if entity extraction fails
    public static func extractEntities(_ text: String, maxTokens: Int = 300) async throws -> [String] {
        let service = try await getDefaultService()
        let task = ExtractEntitiesLLMTask(
            name: "EntityExtraction",
            llmService: service,
            strings: [text],
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract entities from the complex output structure
        if let entitiesDict = outputs["entities"] as? [String: [String]] {
            // Format: {"original_text": ["entity1", "entity2"]}
            return Array(entitiesDict.values.flatMap { $0 })
        } else if let entitiesArray = outputs["entities"] as? [String] {
            // Direct array format
            return entitiesArray
        }
        return []
    }
    
    /// Categorize text into predefined categories
    /// - Parameters:
    ///   - text: The text to categorize
    ///   - categories: Array of category names
    ///   - maxTokens: Maximum number of tokens to generate (default: 200)
    /// - Returns: The assigned category
    /// - Throws: An error if categorization fails
    public static func categorize(_ text: String, into categories: [String], maxTokens: Int = 200) async throws -> String {
        let service = try await getDefaultService()
        let task = CategorizeStringsLLMTask(
            name: "Categorization",
            llmService: service,
            strings: [text],
            categories: categories,
            maxTokens: maxTokens
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract categorized content from the complex output structure
        if let categorizedContent = outputs["categorizedStrings"] as? [String: [String]] {
            // Format: {"category": ["text1", "text2"]}
            // Find which category contains our input text
            for (category, texts) in categorizedContent {
                if texts.contains(text) {
                    return category
                }
            }
            return categorizedContent.keys.first ?? "uncategorized"
        } else if let categorizedContent = outputs["categorized_content"] as? [String: [String]] {
            // Alternative format: {"category": ["text1", "text2"]}
            for (category, texts) in categorizedContent {
                if texts.contains(text) {
                    return category
                }
            }
            return categorizedContent.keys.first ?? "uncategorized"
        } else if let categorizedContent = outputs["categorized_content"] as? [String: String] {
            // Format: {"text": "category"}
            return Array(categorizedContent.values).first ?? "uncategorized"
        }
        return "uncategorized"
    }
    
    // MARK: - Data Processing Convenience Methods
    
    /// Fetch content from a URL
    /// - Parameter url: The URL to fetch
    /// - Returns: The fetched data as a string
    /// - Throws: An error if fetching fails
    public static func fetch(_ url: String) async throws -> String {
        guard let urlObject = URL(string: url) else {
            throw TasksError.invalidURL(url)
        }
        
        let task = FetchURLTask(name: "FetchURL", url: urlObject.absoluteString)
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract data from the output structure
        if let data = outputs["data"] as? Data {
            return String(data: data, encoding: .utf8) ?? ""
        } else if let dataString = outputs["data"] as? String {
            return dataString
        }
        return ""
    }
    
    /// Parse RSS feed data
    /// - Parameter xmlData: The RSS XML data to parse
    /// - Returns: Array of parsed RSS articles
    /// - Throws: An error if parsing fails
    public static func parseRSS(_ xmlData: String) async throws -> [RSSArticle] {
        let task = RSSParsingTask(
            name: "RSSParsing",
            inputs: ["xml": xmlData]
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        return outputs["articles"] as? [RSSArticle] ?? []
    }
    
    /// Parse JSON data
    /// - Parameters:
    ///   - jsonData: The JSON data to parse
    ///   - keyPath: The key path to extract (e.g., "data.items")
    /// - Returns: The extracted JSON element
    /// - Throws: An error if parsing fails
    public static func parseJSON(_ jsonData: String, keyPath: String) async throws -> JSONElement {
        let task = JSONParsingTask(
            name: "JSONParsing",
            inputs: ["json": jsonData, "keyPath": keyPath]
        )
        
        let component = task.toComponent()
        guard case .task(let workflowTask) = component else {
            throw TasksError.taskExecutionFailed("Failed to extract task from component")
        }
        let outputs = try await workflowTask.execute()
        
        // Extract parsed JSON element from the output structure
        if let parsedJSON = outputs["parsedJSON"] as? JSONElement {
            return parsedJSON
        }
        return JSONElement.null
    }
    
    
    // MARK: - ML Task Convenience Methods
    
    /// Classify text using ML models
    /// - Parameter text: The text to classify
    /// - Returns: Array of classification tags
    /// - Throws: An error if classification fails
    public static func classify(_ text: String) async throws -> [Tag] {
        return try await ML.classify(text, with: ML.sentiment)
    }
    
    /// Generate embeddings for text
    /// - Parameter text: The text to embed
    /// - Returns: The embedding vector
    /// - Throws: An error if embedding generation fails
    public static func embed(_ text: String) async throws -> [Double] {
        return try await ML.embed(text, with: ML.embeddings)
    }
    
    /// Perform semantic search
    /// - Parameters:
    ///   - query: The search query
    ///   - documents: The documents to search in
    /// - Returns: Array of search results
    /// - Throws: An error if search fails
    public static func search(_ query: String, in documents: [String]) async throws -> [[String: Any]] {
        let searchService = SemanticSearchService.withDefaultEmbeddings(
            name: "SemanticSearch",
            documents: documents,
            topK: 5
        )
        return try await ML.search(query, with: searchService)
    }
}

// MARK: - Supporting Types

/// LLM service types for configuration
public enum LLMServiceType {
    case anthropic
    case openai
    case ollama
    case foundation
}

/// Tasks-specific errors
public enum TasksError: Error, LocalizedError {
    case noDefaultServiceConfigured
    case invalidURL(String)
    case taskExecutionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noDefaultServiceConfigured:
            return "No default LLM service configured. Use Tasks.configure(with:) to set up a service."
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .taskExecutionFailed(let message):
            return "Task execution failed: \(message)"
        }
    }
}
