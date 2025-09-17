# ``AuroraLLM``

Large Language Model integration and management for the Aurora Toolkit.

## Overview

AuroraLLM provides a unified interface for working with multiple Large Language Model services, including intelligent routing, request management, and response handling. This module abstracts away the complexities of different LLM APIs while providing advanced features like domain-based routing and context management.

### Key Features

- **Multi-Service Support**: Unified interface for Anthropic, OpenAI, Google, Ollama, and Apple Foundation Models services
- **Intelligent Routing**: Domain-based routing to optimize requests across different LLM services
- **Context Management**: Advanced context storage and retrieval for conversational workflows
- **Request Optimization**: Automatic token management and request optimization
- **Streaming Support**: Real-time response streaming for interactive applications

## Topics

### Core Components

- ``LLMManager``
- ``LLMRequest``
- ``LLMMessage``
- ``LLMServiceProtocol``
- ``LLMResponseProtocol``

### Service Implementations

- ``AnthropicService``
- ``OpenAIService``
- ``OllamaService``
- ``FoundationModelService``

### Domain Routing

- ``LLMDomainRouterProtocol``
- ``CoreMLDomainRouter``
- ``DualDomainRouter``
- ``LLMDomainRouter``

### Context Management

- ``ContextManager``
- ``ContextController``
- ``LoadContextTask``
- ``SaveContextTask``

### Text Processing

- ``Summarizer``
- ``SummarizerProtocol``

### Response Handling

- ``AnthropicLLMResponse``
- ``OpenAILLMResponse``
- ``OllamaLLMResponse``
- ``FoundationModelResponse``
- ``LLMTokenUsage``

### Configuration

- ``LLMRequestOptions``
- ``LLMServiceFactory``
- ``LLMServiceError``

## Getting Started

AuroraLLM makes it easy to work with multiple LLM services through a unified interface. Here's how to get started:

### Basic Usage

```swift
import AuroraLLM

// Initialize the LLM Manager
let manager = LLMManager()

// Register an LLM service
let apiKey = "your-api-key"
let service = AnthropicService(apiKey: apiKey)
manager.registerService(service)

// Send a request
let request = LLMRequest(
    messages: [
        LLMMessage(role: .user, content: "What is machine learning?")
    ]
)

if let response = await manager.sendRequest(request) {
    print("Response: \(response.text)")
}
```

### Domain-Based Routing

For more advanced use cases, you can set up domain-based routing to automatically direct requests to the most appropriate service:

```swift
import AuroraLLM

let manager = LLMManager()

// Register services for different domains
let sportsService = OpenAIService(apiKey: openAIKey)
manager.registerService(sportsService, withRoutings: [.domain(["sports"])])

let techService = AnthropicService(apiKey: anthropicKey)
manager.registerService(techService, withRoutings: [.domain(["technology"])])

// The manager will automatically route to the appropriate service
let sportsQuestion = LLMRequest(messages: [
    LLMMessage(role: .user, content: "Who won the Super Bowl?")
])
let response = await manager.routeRequest(sportsQuestion)
```

### Apple Foundation Models (iOS 26+/macOS 26+)

For on-device AI processing using Apple's Foundation Models, you can use the FoundationModelService:

```swift
import AuroraLLM

// Check if Foundation Models is available on this device
guard FoundationModelService.isAvailable() else {
    print("Foundation Models not available (requires iOS 26+ and Apple Intelligence)")
    return
}

// Create the service (no API key required)
if let service = FoundationModelService.createIfAvailable() {
    let manager = LLMManager()
    manager.registerService(service)
    
    // Send a request using on-device AI
    let request = LLMRequest(
        messages: [
            LLMMessage(role: .user, content: "Summarize this text in one sentence.")
        ],
        maxTokens: 100 // Stay within 4,096 token limit
    )
    
    if let response = await manager.sendRequest(request) {
        print("On-device response: \(response.text)")
    }
} else {
    print("Foundation Models not available (Apple Intelligence may not be enabled)")
}
```

### Context Management

AuroraLLM provides powerful context management capabilities for maintaining conversation state:

```swift
import AuroraLLM
import AuroraCore

// Create a workflow with context management
let workflow = Workflow(
    name: "Conversational Workflow",
    description: "A workflow with persistent context"
) {
    LoadContextTask(contextId: "conversation-123")
    
    Workflow.Task(name: "ProcessMessage") { inputs in
        // Your LLM processing logic here
        return ["response": "Processed message"]
    }
    
    SaveContextTask(contextId: "conversation-123")
}
```

## Architecture

AuroraLLM is designed around a flexible service architecture that allows for easy integration of new LLM providers while maintaining a consistent interface. The module includes intelligent routing capabilities that can direct requests to the most appropriate service based on domain classification, token requirements, or custom logic.

The context management system provides persistent storage for conversation history, enabling sophisticated multi-turn interactions while maintaining efficiency through intelligent context pruning and optimization.