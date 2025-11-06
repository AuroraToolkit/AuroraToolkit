# Integration Tests

Integration tests for AuroraToolkit that verify cross-module functionality and real-world workflow scenarios.

## Running Integration Tests

### Run All Integration Tests

```bash
swift test --filter IntegrationTests
```

### Run a Specific Integration Test

```bash
# Run a specific test case
swift test --filter IntegrationTests.CrossModuleIntegrationTests/testWorkflowWithLLMIntegration

# Run all tests in a test class
swift test --filter IntegrationTests.CrossModuleIntegrationTests
```

### Run with Verbose Output

```bash
swift test --filter IntegrationTests -v
```

### Run in Xcode

1. Open the project in Xcode
2. Press `Cmd+U` to run all tests
3. Or navigate to the test navigator and run specific integration tests

## Available Tests

### CrossModuleIntegrationTests

- `testWorkflowWithLLMIntegration` - Tests workflow with LLM service integration
- `testLLMTaskWithRealService` - Tests TaskLibrary LLM tasks with real service
- `testWorkflowWithMultipleLLMTasks` - Tests workflow chaining multiple LLM operations
- `testFoundationModelAvailability` - Verifies Apple Foundation Model detection

### MLAndLLMIntegrationTests

- `testMLClassificationThenLLMSummarization` - Tests ML tagging followed by LLM summarization
- `testMLEmbeddingThenLLMAnalysis` - Tests ML embeddings followed by LLM analysis
- `testMLTaskLibraryWithLLM` - Tests ML TaskLibrary tasks with LLM services

### ErrorHandlingIntegrationTests

- `testLLMErrorPropagationInWorkflow` - Tests error propagation through workflows
- `testErrorRecoveryPattern` - Tests error recovery patterns in workflows
- `testTaskLibraryErrorHandling` - Tests TaskLibrary error handling

### ContextManagementIntegrationTests

- `testMultiTurnConversation` - Tests multi-turn conversations with context management
- `testWorkflowWithContextManagement` - Tests workflows building context across LLM calls
- `testContextTasksIntegration` - Tests context management tasks from TaskLibrary

### PerformanceIntegrationTests

- `testSingleLLMCallPerformance` - Measures single LLM call latency
- `testWorkflowExecutionPerformance` - Measures complete workflow execution time
- `testMultipleSequentialLLMCallsPerformance` - Measures multiple sequential call performance
- `testTaskLibraryPerformance` - Measures TaskLibrary convenience method performance

### StreamingIntegrationTests

- `testBasicStreamingRequest` - Tests basic streaming request functionality
- `testStreamingInWorkflow` - Tests streaming requests within workflows
- `testStreamingWithTaskLibrary` - Tests streaming with TaskLibrary integration
- `testMultipleStreamingCalls` - Tests multiple sequential streaming requests
- `testStreamingErrorHandling` - Tests error handling in streaming requests

### DomainRoutingIntegrationTests

- `testLLMManagerDomainRouting` - Tests LLMManager routing based on domain
- `testCoreMLDomainRouter` - Tests CoreMLDomainRouter integration
- `testLLMDomainRouter` - Tests LLMDomainRouter integration
- `testLogicDomainRouter` - Tests LogicDomainRouter with rule-based routing
- `testManagerWithMultipleServicesAndRouting` - Tests manager with multiple services and routing
- `testRoutingFallback` - Tests routing fallback behavior

### LLMManagerIntegrationTests

- `testServiceRegistration` - Tests registering and unregistering services
- `testMultipleServiceRegistration` - Tests registering multiple services
- `testTokenLimitRouting` - Tests routing based on input token limits
- `testFallbackService` - Tests fallback service behavior
- `testActiveServiceManagement` - Tests setting and getting active service
- `testSendRequestThroughManager` - Tests sending requests through the manager
- `testStreamingThroughManager` - Tests streaming requests through the manager
- `testMultipleServicesWithDifferentRoutings` - Tests manager with multiple services having different routing strategies
- `testErrorHandlingNoMatchingService` - Tests error handling when no service matches routing

## Test Strategy

### Apple Foundation Model (Preferred)

Integration tests use **Apple Foundation Model** when available:
- ✅ Local execution (no API costs)
- ✅ Fast response times
- ✅ Available on macOS 26+ with Apple Intelligence enabled
- ✅ Tests real on-device LLM capabilities

### Mock Fallback

When Apple Foundation Model is unavailable (CI/CD, older systems):
- ✅ Automatically falls back to mock service
- ✅ Tests run without external dependencies
- ✅ Verifies workflow structure and data flow

## Adding New Integration Tests

1. Create a new test file in `Tests/IntegrationTests/`
2. Import required modules: `AuroraCore`, `AuroraLLM`, `AuroraML`, `AuroraTaskLibrary`
3. Use `IntegrationTestHelpers.getLLMService()` for LLM services
4. Test real-world scenarios that span multiple modules

Example:

```swift
import XCTest
@testable import AuroraCore
@testable import AuroraLLM

final class MyIntegrationTests: XCTestCase {
    func testMyScenario() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        // ... your test code
    }
}
```

