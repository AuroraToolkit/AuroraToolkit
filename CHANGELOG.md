# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
