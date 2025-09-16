# Using AI Agents with AuroraToolkit

This directory provides guidance and templates for using AI agents effectively with the AuroraToolkit project.

## Quick Start

- **Keep personal agent configs out of git** - see `.gitignore` for what's already ignored
- **All changes must pass quality checks** regardless of which tool generated them:
  ```bash
  swiftlint          # Code style validation
  swift build        # Compilation check
  swift test         # Unit tests
  ```

## Recommended Workflow

1. **Use any AI agent you prefer** (Claude Code, Cursor, ChatGPT, etc.)
2. **Let the agent help with code generation**, but always review the output
3. **Ensure code follows project conventions** by examining similar files first
4. **Run quality checks** before committing
5. **Test thoroughly** - AI-generated code needs the same validation as manually written code

## Agent Configuration Tips

### For Code Generation
- Point agents to existing code examples in `Sources/` to understand patterns
- Reference the SwiftLint config (`.swiftlint.yml`) for style guidelines
- Mention that this is a Swift Package Manager project with multiple targets

### For Documentation
- The project uses Swift-DocC for documentation generation
- Code should include proper Swift documentation comments
- See existing files for documentation patterns

### For Testing
- Tests are located in `Tests/` directory
- Follow existing test patterns and naming conventions
- Ensure new features have corresponding tests

## Project Context for AI Agents

**AuroraToolkit** is a Swift toolkit with these main components:
- `AuroraCore`: Core utilities and protocols
- `AuroraLLM`: LLM management and integration
- `AuroraML`: Machine learning model management  
- `AuroraTaskLibrary`: High-level task abstractions
- `AuroraExamples`: Usage examples and demos

**Key architectural patterns:**
- Protocol-oriented design
- Async/await for concurrency
- Swift Package Manager modular structure
- Comprehensive error handling with custom error types

## Quality Standards

Remember: The repository is the source of truth. Whether code is written by human or AI, it must meet the same standards:

- ✅ Passes SwiftLint validation
- ✅ Compiles without warnings
- ✅ Has appropriate tests
- ✅ Follows existing code patterns
- ✅ Includes proper documentation
- ✅ Handles errors appropriately

## Getting Help

- Check `CONTRIBUTING.md` for general contribution guidelines
- Examine existing code in `Sources/` for patterns and conventions
- Run `swiftlint --help` for linting options
- See `Package.swift` for project structure and dependencies