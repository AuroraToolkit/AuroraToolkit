# ``AuroraTaskLibrary``

Ready-to-use task components for building sophisticated workflows in the Aurora Toolkit.

## Overview

AuroraTaskLibrary provides a comprehensive collection of pre-built task components that can be easily integrated into Aurora workflows. These tasks cover common operations across LLM processing, machine learning, data parsing, network operations, and general utility functions.

Each task is designed to work seamlessly with the Aurora workflow system, providing standardized inputs, outputs, and error handling while abstracting away the complexity of the underlying operations.

### Key Features

- **Extensive Task Collection**: Over 25 ready-to-use task components
- **LLM Integration**: Advanced text processing tasks powered by large language models
- **ML Operations**: Machine learning tasks for classification, embedding, and analysis
- **Data Processing**: Parsing tasks for JSON, RSS, and other data formats
- **Network Operations**: URL fetching and web-based data retrieval
- **Workflow Ready**: All tasks designed for seamless integration into Aurora workflows

## Topics

### LLM-Powered Tasks

- ``AnalyzeSentimentLLMTask``
- ``AnalyzeTextReadabilityLLMTask``
- ``CategorizeStringsLLMTask``
- ``ClusterStringsLLMTask``
- ``DetectLanguagesLLMTask``
- ``ExtractEntitiesLLMTask``
- ``ExtractRelationsLLMTask``
- ``GenerateKeywordsLLMTask``
- ``GenerateTitlesLLMTask``
- ``SummarizeContextLLMTask``
- ``SummarizeStringsLLMTask``
- ``TranslateStringsLLMTask``

### Machine Learning Tasks

- ``MLTask``
- ``ClassificationMLTask``
- ``EmbeddingMLTask``
- ``IntentExtractionMLTask``
- ``SemanticSearchMLTask``
- ``TaggingMLTask``
- ``AnalyzeSentimentMLTask``

### Data Processing Tasks

- ``JSONParsingTask``
- ``RSSParsingTask``
- ``JSONElement``
- ``RSSArticle``

### Network Tasks

- ``FetchURLTask``

### Utility Tasks

- ``TrimmingTask``

## Getting Started

AuroraTaskLibrary tasks are designed to be drop-in components for your Aurora workflows. Here's how to use them:

### Basic LLM Task Usage

```swift
import AuroraCore
import AuroraLLM
import AuroraTaskLibrary

// Create a workflow with sentiment analysis
let workflow = Workflow(
    name: "Content Analysis",
    description: "Analyze text sentiment"
) {
    // Analyze sentiment of input text
    AnalyzeSentimentLLMTask(
        name: "SentimentAnalysis",
        llmService: anthropicService,
        inputs: ["strings": ["This is a great product!"]]
    )
    
    // Generate keywords from the text
    GenerateKeywordsLLMTask(
        name: "KeywordExtraction", 
        llmService: anthropicService,
        inputs: ["strings": ["This is a great product!"]]
    )
}

await workflow.start()

// Access results
if let sentiment = workflow.outputs["SentimentAnalysis.sentiments"] as? [String] {
    print("Detected sentiment: \(sentiment.first ?? "unknown")")
}
```

### Machine Learning Task Integration

```swift
import AuroraCore
import AuroraML
import AuroraTaskLibrary

let workflow = Workflow(
    name: "ML Processing",
    description: "Process text with ML models"
) {
    // Classify text using Core ML
    ClassificationMLTask(
        name: "TextClassification",
        service: classificationService,
        inputs: ["strings": ["Sample text to classify"]]
    )
    
    // Generate embeddings
    EmbeddingMLTask(
        name: "TextEmbeddings",
        service: embeddingService,
        inputs: ["strings": ["Sample text to embed"]]
    )
}
```

### Data Processing Workflow

```swift
import AuroraCore
import AuroraTaskLibrary

let workflow = Workflow(
    name: "Data Processing",
    description: "Fetch and parse web content"
) {
    // Fetch RSS feed
    FetchURLTask(
        name: "FetchRSS",
        url: URL(string: "https://example.com/feed.xml")!
    )
    
    // Parse the RSS content
    RSSParsingTask(
        name: "ParseRSS",
        inputs: ["xml": "{FetchRSS.data}"]
    )
    
    // Extract and clean article titles
    TrimmingTask(
        name: "CleanTitles",
        inputs: ["strings": "{ParseRSS.articles}"]
    )
}
```

### Chaining LLM Tasks

```swift
import AuroraCore
import AuroraLLM
import AuroraTaskLibrary

let workflow = Workflow(
    name: "Content Pipeline",
    description: "Complete content analysis pipeline"
) {
    // Extract entities from text
    ExtractEntitiesLLMTask(
        name: "EntityExtraction",
        llmService: llmService,
        inputs: ["strings": inputTexts]
    )
    
    // Categorize based on extracted entities
    CategorizeStringsLLMTask(
        name: "ContentCategorization",
        llmService: llmService,
        inputs: ["strings": "{EntityExtraction.entities}"],
        categories: ["Technology", "Business", "Science", "Healthcare"]
    )
    
    // Generate summaries for each category
    SummarizeStringsLLMTask(
        name: "CategorySummaries",
        llmService: llmService,
        inputs: ["strings": "{ContentCategorization.categorized_content}"]
    )
}
```

## Architecture

AuroraTaskLibrary follows a modular architecture where tasks are organized by functionality:

**LLM Tasks** leverage large language models for sophisticated text processing operations, including analysis, generation, and transformation tasks.

**ML Tasks** integrate with Core ML and other machine learning frameworks to provide on-device inference capabilities.

**Data Processing Tasks** handle various data formats and provide parsing capabilities for common web and data interchange formats.

**Network Tasks** enable workflows to fetch external data and integrate with web services.

**Utility Tasks** provide common data manipulation and processing operations.

All tasks implement the `WorkflowComponent` protocol, ensuring consistent behavior, error handling, and integration patterns across the entire library. This design enables easy composition of complex workflows while maintaining type safety and clear data flow between components.