# Contributing to AuroraCore

Thank you for considering contributing to AuroraCore! We welcome contributions from the community. Please follow these guidelines to help us maintain a high-quality project.

## How to Contribute

1. **Fork the Repository**: Click the "Fork" button at the top right of the repository page to create your own copy of the project.

2. **Clone Your Fork**: Clone your forked repository to your local machine:
   ```bash
   git clone https://github.com/your-username/AuroraCore.git
   ```

3. **Create a Branch**: Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b my-feature-branch
   ```

4. **Make Changes**: Make your changes and ensure that your code adheres to the project's coding standards.

5. **Write Tests**: If applicable, write tests for your changes to ensure they work as expected.

6. **Commit Your Changes**: Commit your changes with a clear and descriptive commit message:
   ```bash
   git commit -m "Add feature X"
   ```

7. **Push to Your Fork**: Push your changes to your forked repository:
   ```bash
   git push origin my-feature-branch
   ```

8. **Create a Pull Request**: Go to the original repository and create a pull request. Provide a clear description of your changes and why they should be merged.

## Code Style and Quality

Please follow the existing code style in the project. Consistency is key to maintaining readability.

### Code Formatting
- Use SwiftLint for code style enforcement. Run `swiftlint` before committing.
- Follow the `.editorconfig` settings for consistent formatting across editors.
- All code must pass SwiftLint validation regardless of which tools or AI agents you use.

### Using AI Agents and IDEs
You're welcome to use AI agents (Claude Code, Cursor, ChatGPT, etc.) to help with development. However:
- **Don't commit personal agent configs, caches, or prompt histories** - these are ignored by `.gitignore`
- **The repository is the source of truth** - all changes must pass tests, linters, and formatters
- **Maintain code quality** - AI-generated code should be reviewed and tested just like manually written code
- If an agent suggests project-wide settings (formatter rules, linting configs), propose them via PR as normal code changes

### Required Checks
Before submitting a PR, ensure your code passes:
```bash
# Code style and linting
swiftlint

# Build and tests
swift build
swift test
```

## Reporting Issues

If you find a bug or have a feature request, please open an issue in the repository. Provide as much detail as possible to help us understand the problem.

Thank you for your contributions!
