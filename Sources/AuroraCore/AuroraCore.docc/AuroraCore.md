# ``AuroraCore``

Core foundation and workflow management for the Aurora Toolkit.

## Overview

AuroraCore provides the fundamental building blocks for the Aurora Toolkit ecosystem, including a powerful declarative workflow system and essential utility functions. This module serves as the foundation that other Aurora modules build upon.

### Key Components

- **Workflows**: A declarative system for orchestrating complex task execution with support for sequential and parallel processing
- **Utilities**: Essential helper functions for debugging, secure storage, token handling, and execution timing
- **Type Safety**: Strong typing support with comprehensive type handling utilities

## Topics

### Workflow Management

- ``Workflow``
- ``WorkflowBuilder``
- ``WorkflowReport``
- ``WorkflowComponentReport``

### Development Utilities

- ``CustomLogger``
- ``ExecutionTimer``
- ``SecureStorage``

## Getting Started

AuroraCore is designed to be the foundation of your Aurora-based applications. Start by exploring the workflow system for orchestrating complex operations:

```swift
import AuroraCore

// Create a simple workflow
let workflow = Workflow(
    name: "My Workflow",
    description: "A sample workflow"
) {
    Workflow.Task(name: "Step1") { _ in
        print("Executing step 1")
        return ["result": "completed"]
    }
    
    Workflow.Task(name: "Step2") { inputs in
        print("Executing step 2")
        return ["final": "done"]
    }
}

// Execute the workflow
await workflow.start()
```

For debugging and development, leverage the comprehensive logging utilities:

```swift
import AuroraCore

// Use the custom logger for detailed debugging
CustomLogger.shared.log("Application started", level: .info)
CustomLogger.shared.logError("Something went wrong", error: someError)
```

## Architecture

AuroraCore follows a modular architecture where each component serves a specific purpose:

The **Workflow System** provides declarative task orchestration with support for complex execution patterns. The **Utility Layer** offers essential development tools including logging, timing, and secure storage.

This foundation enables the other Aurora modules (AuroraLLM, AuroraML, AuroraTaskLibrary) to provide specialized functionality while maintaining consistency and reliability.