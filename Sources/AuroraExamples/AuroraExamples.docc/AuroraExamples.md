# ``AuroraExamples``

Comprehensive examples and tutorials for the Aurora Toolkit ecosystem.

## Overview

AuroraExamples provides a rich collection of working examples that demonstrate how to use the Aurora Toolkit's various components in real-world scenarios. From basic LLM requests to complex multi-stage workflows, these examples serve as both learning resources and starting points for your own applications.

Each example is self-contained and includes detailed explanations, making it easy to understand the concepts and adapt the code for your specific use cases.

### Example Categories

- **Basic Usage**: Fundamental operations with LLM services and Aurora components
- **Domain Routing**: Intelligent request routing based on content analysis
- **Complex Workflows**: Multi-step processes combining LLM, ML, and data processing
- **Real-World Applications**: Production-ready examples for common business scenarios

## Topics

### Basic Examples

- ``BasicRequestExample``
- ``StreamingRequestExample``

### Routing Examples

- ``DomainRoutingExample``
- ``LLMRoutingExample``
- ``DualDomainRoutingExample``
- ``SiriStyleDomainRoutingExample``
- ``LogicDomainRouterExample``

### Workflow Examples

- ``BlogCategoryWorkflowExample``
- ``CustomerFeedbackAnalysisWorkflow``
- ``IssueTriageWorkflowExample``
- ``LeMondeTranslationWorkflow``
- ``SupportTicketWorkflowExample``
- ``TemperatureMonitorWorkflow``
- ``TVScriptWorkflowExample``

## Getting Started

The examples are organized from simple to complex, making it easy to learn Aurora concepts progressively:

### 1. Start with Basic Examples

Begin with ``BasicRequestExample`` to understand how to set up and use LLM services:

```swift
// Initialize the LLM Manager
let manager = LLMManager()

// Register an LLM service
let service = AnthropicService(apiKey: apiKey, logger: CustomLogger.shared)
manager.registerService(service)

// Send a basic request
let request = LLMRequest(messages: [
    LLMMessage(role: .user, content: "What is the meaning of life?")
])

if let response = await manager.sendRequest(request) {
    print("Response: \(response.text)")
}
```

### 2. Explore Domain Routing

Learn how Aurora can intelligently route requests with ``DomainRoutingExample``:

```swift
// Register domain-specific services
let sportsService = MockLLMService(name: "Sports Service")
manager.registerService(sportsService, withRoutings: [.domain(["sports"])])

let moviesService = MockLLMService(name: "Movies Service")
manager.registerService(moviesService, withRoutings: [.domain(["movies"])])

// Aurora automatically routes based on content
let sportsQuestion = LLMRequest(messages: [
    LLMMessage(role: .user, content: "Who won the Super Bowl?")
])
let response = await manager.routeRequest(sportsQuestion)
```

### 3. Build Complex Workflows

Study workflow examples like ``BlogCategoryWorkflowExample`` to see how multiple services work together:

```swift
let workflow = Workflow(
    name: "Blog Categorization",
    description: "Classify and summarize blog posts"
) {
    // On-device ML classification
    Workflow.Task(name: "ClassifyPost") { inputs in
        let output = try await mlService.run(request: MLRequest(...))
        return ["categories": output.tags]
    }
    
    // LLM-powered summarization
    Workflow.Task(name: "SummarizePost") { inputs in
        let response = try await llmService.sendRequest(LLMRequest(...))
        return ["summary": response.text]
    }
}
```

### 4. Production-Ready Patterns

Examine examples like ``CustomerFeedbackAnalysisWorkflow`` and ``SupportTicketWorkflowExample`` for enterprise-grade implementations that include error handling and recovery strategies, multi-service coordination, data validation and transformation, performance optimization techniques, and logging and monitoring integration.

## Example Highlights

### Advanced Routing with Machine Learning

``DualDomainRoutingExample`` demonstrates sophisticated routing using multiple Core ML models for improved accuracy in content classification.

### Real-Time Processing

``StreamingRequestExample`` shows how to handle streaming responses for interactive applications requiring real-time feedback.

### Multi-Language Support

``LeMondeTranslationWorkflow`` illustrates international content processing with translation and localization workflows.

### Business Process Automation

``IssueTriageWorkflowExample`` and ``SupportTicketWorkflowExample`` provide templates for automating common business processes using Aurora's workflow system.

## Running the Examples

Each example can be run independently by calling its `execute()` method. The examples require appropriate API keys set as environment variables:

```bash
export ANTHROPIC_API_KEY="your-anthropic-key"
export OPENAI_API_KEY="your-openai-key"

# Run the examples
swift run AuroraExamples
```

Some examples require additional setup, such as Core ML models or specific data files. Check the individual example documentation for detailed requirements.

## Architecture Patterns

The examples demonstrate several important Aurora architecture patterns:

**Service Registration**: How to set up and configure different types of Aurora services.

**Workflow Composition**: Building complex processes from simple, reusable components.

**Error Handling**: Robust error handling strategies for production applications.

**Resource Management**: Efficient use of API quotas, model loading, and memory management.

**Testing Strategies**: Approaches for testing Aurora-based applications, including mocking services and validation techniques.

These patterns provide proven approaches for building scalable, maintainable applications with the Aurora Toolkit.