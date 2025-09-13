# ``AuroraML``

Machine Learning integration and management for the Aurora Toolkit.

## Overview

AuroraML provides a comprehensive framework for integrating and managing machine learning models within the Aurora ecosystem. This module offers a unified interface for various ML services including classification, embedding generation, semantic search, intent extraction, and tagging operations.

### Key Features

- **Unified ML Interface**: Consistent API across different machine learning services and models
- **Core ML Integration**: Native support for Apple's Core ML framework
- **Multiple ML Services**: Ready-to-use services for common ML tasks
- **Flexible Architecture**: Easy integration of custom ML models and services
- **Performance Optimized**: Efficient model loading and inference management

## Topics

### Core Components

- ``MLManager``
- ``MLRequest``
- ``MLResponse``
- ``MLServiceProtocol``

### ML Services

- ``ClassificationService``
- ``EmbeddingService``
- ``SemanticSearchService``
- ``IntentExtractionService``
- ``TaggingService``

### Models and Data Types

- ``Tag``

## Getting Started

AuroraML makes it easy to integrate machine learning capabilities into your applications. Here's how to get started:

### Basic Classification

```swift
import AuroraML
import NaturalLanguage

// Load a Core ML classification model
guard let model = try? NLModel(contentsOf: modelURL) else {
    fatalError("Failed to load model")
}

// Create a classification service
let service = ClassificationService(
    name: "Text Classifier",
    model: model,
    scheme: "category",
    maxResults: 5
)

// Create a request
let request = MLRequest(inputs: ["strings": ["This is a sample text"]])

// Run classification
let response = try await service.run(request: request)
if let tags = response.outputs["tags"] as? [Tag] {
    for tag in tags {
        print("Label: \(tag.label), Confidence: \(tag.confidence)")
    }
}
```

### Embedding Generation

```swift
import AuroraML
import NaturalLanguage

// Create an embedding service
let embeddingService = EmbeddingService(
    name: "Text Embeddings",
    model: embeddingModel,
    revision: 1
)

// Generate embeddings for text
let request = MLRequest(inputs: ["strings": ["Hello world", "Machine learning"]])
let response = try await embeddingService.run(request: request)

if let embeddings = response.outputs["embeddings"] as? [[Float]] {
    print("Generated \(embeddings.count) embeddings")
}
```

### Semantic Search

```swift
import AuroraML

// Create a semantic search service
let searchService = SemanticSearchService(
    name: "Document Search",
    embeddingModel: embeddingModel,
    documents: documents
)

// Search for similar documents
let query = "machine learning applications"
let searchRequest = MLRequest(inputs: ["query": query])
let results = try await searchService.run(request: searchRequest)
```

### ML Manager Integration

For complex workflows involving multiple ML services, use the ML Manager:

```swift
import AuroraML

let manager = MLManager()

// Register multiple services
await manager.registerService(classificationService)
await manager.registerService(embeddingService)
await manager.registerService(searchService)

// Use services through the manager
let services = await manager.getServices()
for service in services {
    print("Available service: \(service.name)")
}
```

## Architecture

AuroraML follows a service-oriented architecture where each ML capability is encapsulated in a dedicated service class. All services conform to the `MLServiceProtocol`, ensuring consistent interfaces and enabling easy integration into workflows.

The module leverages Apple's Core ML framework for optimal performance on Apple platforms while providing abstractions that make it easy to swap models or extend functionality with custom implementations.

Services are designed to be stateless and thread-safe, allowing for efficient parallel processing and integration into concurrent workflows. The ML Manager provides centralized service registration and management capabilities for complex applications requiring multiple ML services.