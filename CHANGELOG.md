# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-01-08

### Added
- Migration of `OllamaService` from legacy `/api/generate` to the modern `/api/chat` endpoint.
- Full token usage tracking support for Ollama requests (`eval_count`, `prompt_eval_count`).
- New comprehensive unit tests for `OllamaService` chat API and streaming.
- `extractThoughtsAndStripJSON()` integration in `Summarizer` for more robust cleaning of LLM reasoning blocks.

### Changed
- Refined prompt engineering across `AuroraTaskLibrary` (Translation, Titles, Clustering, Sentiment, Language Detection) to ensure more reliable JSON responses.
- Increased default `maxTokens` in `GenerateTitlesLLMTask` from 100 to 500.
- Improved streaming robustness in `OllamaService` to handle newline-delimited JSON chunks.
- Softened sentiment in integration tests to improve compatibility with Apple Foundation Model content filters.
- Updated `.gitignore` to exclude test artifacts (`*_output.txt`).

### Fixed
- Corrected `OllamaService` default port from 11400 to 11434 in `LLMServiceFactory`.
- Fixed `OllamaService` default token limits to ensure the context window (8192) is larger than the max output tokens (4096), preventing accidental prompt trimming.
- Fixed `LLMManager` fallback routing logic to correctly respect strict model routing constraints.
- Resolved integration test failures with Apple Foundation Model by implementing graceful skipping on system errors.

## [1.0.1] - 2025-12-13

### Added
- `supportedModels` property to `LLMServiceProtocol` for explicit model support declaration independent of routing
- Configurable `supportedModels` in all LLM service initializers (`OpenAIService`, `AnthropicService`, `GoogleService`, `OllamaService`, `FoundationModelService`) with automatic deduplication
- Strict model routing support in `LLMManager`:
  - `Routing.models` now strictly validates service support
  - Returns `nil` if the requested model is not supported by any registered service (instead of falling back)
  - Non-strict requests correctly fall back to active/fallback services
- Public read-only access to `LLMManager.services` registry

### Changed
- `LLMManager.selectService` routing logic refined to prevent silent fallbacks for explicit model requests
- Updated `MockLLMService` to include `supportedModels` and strict routing validation support

## [1.0.0] - 2025-11-13

### Added
- Swift 6 concurrency compatibility with full support for strict concurrency checking
- Actor-based state management for thread-safe configuration in convenience APIs
- Comprehensive API audit and stability verification
- Enhanced documentation with Swift 6 compatibility notes across all modules
- Model parameter support in all LLM convenience methods (`send` and `stream`) for specifying custom models

### Changed
- `LLM.configure(with:)` and `LLM.getDefaultService()` are now `async` for Swift 6 concurrency safety
- `Tasks.configure(with:)` and `Tasks.getDefaultService()` are now `async` for Swift 6 concurrency safety
- Replaced `DispatchQueue` usage with actors for modern concurrency patterns
- Modernized `CustomLogger` to use `NSLock` for thread-safe logging operations
- Removed unused `ML.configure(with:)` placeholder method

### Fixed
- All Swift 6 strict concurrency warnings resolved
- Thread safety improvements throughout the codebase
- `Sendable` conformance added to all protocols and types crossing concurrency boundaries
- Data race issues resolved with actor-based state management

### Documentation
- Updated README with Swift 6 compatibility information and future roadmap
- Added Swift 6 compatibility sections to all module documentation
- Enhanced API documentation with thread-safety notes

## [0.9.6] - 2025-11-09

### Added
- Context management refactor with enum-based architecture:
  - `ContentType` enum for type-safe content classification
  - `SummaryItem` struct for summary metadata and references
  - `ContextElement` enum wrapping items and summaries with chronological ordering
- `ContextController.generateComprehensiveSummary()` method for efficiently combining existing summaries with non-summarized items
- Context management example demonstrating conversation management, summarization, and comprehensive summary generation
- Comprehensive test coverage for domain routing:
  - `LLMDomainRouterTests`: 17 tests for basic domain routing functionality
  - `DualDomainRouterTests`: 14 tests for confidence-based conflict resolution
  - `CoreMLDomainRouterTests`: 2 tests for on-device classification routing
  - Updated `LogicDomainRouterTests`: 18 tests for regex-based routing
- Test coverage for new context management types:
  - `ContentTypeTests`: Type validation and content classification
  - `ContextElementTests`: Element wrapping and chronological ordering
  - `ContextSummaryReferencesTests`: Summary reference tracking and relationships

### Changed
- Context management architecture refactored to use enum-based design:
  - `Context` now stores `[ContextElement]` internally with backward-compatible computed properties
  - Chronological ordering guaranteed for items and summaries
  - Prepared for multi-modal content support
- Domain routing standardization:
  - Added `fallbackDomain` property to `LLMDomainRouterProtocol` for consistency across all router implementations
  - Renamed `defaultDomain` → `fallbackDomain` in `LogicDomainRouter`
  - Standardized validation behavior across all routers (warn if fallback is in supportedDomains)
- Protocol naming standardized across all domain routers
- Updated `SummarizeContextLLMTask` for new context management API

### Fixed
- Made `ContextManager` and `LLMServiceFactory` initializers public
- Fixed documentation warnings and missing parameter documentation
- Improved README with standardized Apple Foundation Model naming

## [0.9.4] - 2025-11-02

### Added
- Convenience APIs across all modules for simplified usage:
  - `AuroraCore` convenience APIs for simplified workflow and task creation
  - `AuroraLLM` convenience APIs (`LLM.anthropic`, `LLM.openai`, `LLM.google`, `LLM.ollama`) with `.send()`, `.stream()`, and `.apiKey()` methods
  - `AuroraML` convenience APIs for simplified ML service access
  - `AuroraTaskLibrary` convenience APIs (`Tasks`) for common task operations with configurable token limits
- OpenAI Responses API support with automatic transport selection (`auto`, `responses`, `legacyChat`).
- GoogleService convenience APIs (`LLM.google.send()`, `LLM.google.stream()`).
- `defaultModel` property added to `LLMServiceProtocol` for standardized model fallback behavior.
- `APIKeyLoader` utility for examples to load API keys from `.env` files, environment variables, or SecureStorage.
- Environment variable priority for API key lookup in examples (reduces keychain prompts).
- Error response logging for better debugging of API errors.
- Comprehensive error handling improvements across all modules.
- Performance optimizations in existing functions.
- CHANGELOG.md
- `.env.example` for API keys configuration.
- SwiftLint configuration and linting.
- GitHub Actions CI workflow for build, test, and lint.

### Changed
- Updated default models to more cost-effective options:
  - Anthropic: `claude-haiku-4-5` (was `claude-3-5-sonnet-20240620`)
  - OpenAI: `gpt-4o-mini` (was `gpt-3.5-turbo`)
  - Google: `gemini-2.5-flash-lite` (was `gemini-2.0-flash`)
- OpenAI Responses API now uses `instructions` parameter for system prompts and array format for `input`.
- Removed unsupported `top_p` parameter from Anthropic requests.
- Keychain access control updated to minimize biometric prompts (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
- `SecureStorage` moved from `AuroraCore` to `AuroraLLM` module (now in `AuroraLLM/Utilities/SecureStorage.swift`).
- Service initializer parameters standardized: `defaultModel` now follows `apiKey`, and `logger` is the last parameter across all LLM services.

### Fixed
- Anthropic 400 errors caused by unsupported `top_p` parameter.
- OpenAI 400 errors for `gpt-5-nano` by implementing proper Responses API support.
- Missing convenience APIs for GoogleService.
- Error propagation in workflow execution for nested workflows and parallel task groups.
- API keys now stored in memory during service initialization to avoid blocking keychain access.

## [0.9.2] - 2025-05-18

### Added
- Added AuroraML module for CoreML and NaturalLanguage workflow task integration. Includes
- - `MLManager` for CoreML/NL service management
- - `MLServiceProtocol` for services
- - `ClassificationService` for classification using a CoreML model
- - `IntentExtractionService` for intent extraction using a CoreML model
- - `TaggingService` for tagging using `NLTagger`
- - `EmbeddingService` for for converting text to embeddings using `NLEmbedding`
- - `SemanticSearchService` for semantic search across a collection of documents
- Added new `Workflow.Task` subclasses based on new ML services
- Added `ModelTrainer` for training CoreML models from `.csv` files

### Key Features
- Fully on-device NLP tasks
- Composable workflow components to integrate ML with LLM tasks
- Train and deploy CoreML models with applications
