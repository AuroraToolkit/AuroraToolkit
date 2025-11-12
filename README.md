# AuroraToolkit

**AuroraToolkit** is a suite of tools designed to simplify the integration of AI capabilities into your projects. This package offers robust support for AI-driven workflows, including task orchestration, workflow management, on-device ML services, and seamless integration with large language models (LLMs) like Anthropic Claude, Google Gemini, OpenAI ChatGPT, open-source models via Ollama, and Apple's Foundation Models. Its modular architecture empowers developers to customize, extend, and integrate with external services effortlessly.

The AuroraToolkit main package is organized into several modules to enhance flexibility and maintainability:

- **AuroraCore**: The foundational library for workflow orchestration, utilities, and declarative task management.
- **AuroraLLM**: A dedicated package for integrating large language models (LLMs) such as Anthropic, Google, OpenAI,  Ollama, and on-device Apple Foundation Models.
- **AuroraML**: On-device ML services (classification, intent extraction, tagging, embedding, semantic search) and corresponding Workflow tasks.  
- **AuroraTaskLibrary**: A growing collection of prebuilt, reusable tasks designed to accelerate development.
- **AuroraExamples**: Practical examples demonstrating how to leverage the toolkit for real-world scenarios.

Whether you're building sophisticated AI-powered applications or integrating modular components into your workflows, AuroraToolkit provides the tools and flexibility to bring your ideas to life.

## Quick Start

```swift
import AuroraLLM

// Send a message using the default service (Apple Foundation Model if available)
let response = try await LLM.send("What is machine learning?")
print(response)
```

For more examples, see the [Usage](#usage) section below.

## Features

- **Modular Architecture**: Organized into distinct modules (Core, LLM, ML, TaskLibrary) for flexibility and maintainability
- **Declarative Workflows**: Define workflows declaratively, similar to SwiftUI, for clear task orchestration
- **Multi-LLM Support**: Unified interface for Anthropic, Google, OpenAI, Ollama, and Apple Foundation Models
- **On-Device ML**: Native support for classification, embeddings, semantic search, and more using Core ML
- **Intelligent Routing**: Domain-based routing to automatically select the best LLM service for each request
- **Convenience APIs**: Simplified top-level APIs (`LLM.send()`, `ML.classify()`, etc.) for common operations
- **Swift 6 Compatible**: Fully compatible with Swift 5.5+ and Swift 6 strict concurrency checking with actor-based state management
- **Production Ready**: Comprehensive testing, error handling, thread-safe design, and stable API surface
- **Comprehensive Testing**: Full test coverage including integration tests across all modules


## Modules

### AuroraCore
The foundational library providing workflows, task orchestration, and utility functions. Includes declarative workflow system with support for asynchronous execution, parallel processing, and dynamic task groups.

### AuroraLLM
Unified interface for managing multiple LLM services (Anthropic, Google, OpenAI, Ollama, Apple Foundation Models). Features intelligent domain-based routing, context management, streaming support, and convenience APIs. Includes native support for on-device Apple Foundation Models (iOS 26+/macOS 26+) and CoreML-based domain routing.

### AuroraML
On-device ML services powered by Apple's Natural Language and Core ML frameworks. Provides classification, intent extraction, tagging, embedding generation, and semantic search capabilities.

### AuroraTaskLibrary
Prebuilt, reusable tasks for common operations including JSON/RSS parsing, URL fetching, sentiment analysis, language detection, keyword extraction, and context summarization.

### AuroraExamples
Practical examples demonstrating real-world usage patterns including multi-model management, declarative workflows, domain routing, and ML+LLM hybrid pipelines.



## Installation

### Swift Package Manager

To integrate AuroraToolkit into your project using Swift Package Manager, add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/AuroraToolkit/AuroraToolkit.git", from: "1.0.0")
```

Then add the desired modules as dependencies to your target. For example:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AuroraCore", package: "AuroraToolkit"),
        .product(name: "AuroraLLM", package: "AuroraToolkit"),
        .product(name: "AuroraML", package: "AuroraToolkit"),
        .product(name: "AuroraTaskLibrary", package: "AuroraToolkit")
    ]
),
```

You can include only the modules you need in your project to keep it lightweight and focused.


## Usage

### Basic LLM Usage

```swift
import AuroraLLM

// Simple convenience API (uses Apple Foundation Model if available)
let response = try await LLM.send("What is machine learning?")
print(response)

// Use a specific service
let response = try await LLM.anthropic.send("Explain quantum computing")
let response = try await LLM.foundation?.send("What are the privacy benefits of on-device AI?")
let response = try await LLM.google.send("Summarize the benefits of renewable energy")
let response = try await LLM.openai.send("Write a haiku about coding")

// Streaming responses
try await LLM.stream("Tell me a story") { partial in
    print(partial, terminator: "")
}
```

### Workflows

```swift
import AuroraCore

let workflow = Workflow(name: "Example Workflow") {
    Workflow.Task(name: "Task_1") { _ in
        return ["result": "Task 1 completed"]
    }
    Workflow.Task(name: "Task_2") { inputs in
        return ["result": "Task 2 completed"]
    }
}

await workflow.start()
print("Result: \(workflow.outputs["Task_2.result"] as? String ?? "")")
```

### Advanced: Domain Routing

Aurora supports multiple domain routing strategies to automatically select the best LLM service:

```swift
import AuroraLLM

// Logic-based routing (regex rules)
let router = LogicDomainRouter(
    name: "Privacy Router",
    supportedDomains: ["private", "public"],
    rules: [
        .regex(name: "Email", pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
               domain: "private", priority: 100)
    ],
    fallbackDomain: "public"
)

// Register router with manager
let manager = LLMManager()
manager.registerDomainRouter(router)
```

For more advanced examples including CoreML-based routing and dual router strategies, see the [full documentation](docs/).

## Testing

AuroraToolkit includes comprehensive unit and integration tests. Tests run with Ollama by default (no API keys required). For testing other services, configure API keys via environment variables:

```bash
export ANTHROPIC_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
export GOOGLE_API_KEY="your-key"
```

**Important**: Never commit API keys to the repository. See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed testing setup instructions.

## Documentation

AuroraToolkit uses Swift-DocC for comprehensive, interactive documentation. View documentation by opening the `.doccarchive` files in Xcode:

```bash
open docs/AuroraCore.doccarchive
open docs/AuroraLLM.doccarchive
open docs/AuroraML.doccarchive
open docs/AuroraTaskLibrary.doccarchive
```

For contributors: See [CONTRIBUTING.md](CONTRIBUTING.md) for documentation generation instructions.

## Future Ideas

- **Multimodal LLM support**: Enable multimodal LLMs for use cases beyond plain text
- **Advanced Workflow templates**: Prebuilt workflow templates for common AI tasks (summarization, Q&A, data extraction)
- **Agent support**: Intelligent agents that can reason, plan, and execute complex multi-step tasks
- **Tool calling / Function calling**: Enable LLMs to call external tools and functions (calendar, weather, file system, APIs, etc.)
- **Structured data extraction**: Type-safe extraction of structured data from LLM responses using Swift types (similar to Apple's `@Generable` macro)


## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue. For more details on how to contribute, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## Code of Conduct

We expect all participants to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming and inclusive environment for everyone.

## License

AuroraToolkit is released under the [Apache 2.0 License](LICENSE).

## Contact

For any inquiries or feedback, please reach out to us at [aurora.toolkit@gmail.com](mailto:aurora.toolkit@gmail.com).
