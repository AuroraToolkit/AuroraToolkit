//
//  ContextManagementExample.swift
//  AuroraExamples
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// An example demonstrating context management with conversations, summarization, and summary details.
/// This example shows how to:
/// - Create and manage a conversation context
/// - Add multiple conversation items
/// - Summarize older items automatically
/// - View summary relationships to original items
/// - Verify chronological ordering
struct ContextManagementExample {
    func execute() async {
        print("💬 Context Management Example")
        print("=============================")
        print()

        let service = createLLMService()
        print()

        // Create ContextController
        let contextController = ContextController(
            llmService: service,
            logger: CustomLogger.shared
        )

        print("📝 Starting a conversation about renewable energy...")
        print()

        // Simulate a conversation by adding items with different timestamps
        let baseDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        // Add conversation items (simulating a conversation over time)
        contextController.addItem(
            content: "User: What are the main benefits of renewable energy?",
            creationDate: baseDate.addingTimeInterval(-3600) // 1 hour ago
        )
        contextController.addItem(
            content: "Assistant: Renewable energy offers several key benefits: it's sustainable, reduces greenhouse gas emissions, decreases dependence on fossil fuels, and can create jobs in the green economy.",
            creationDate: baseDate.addingTimeInterval(-3500) // ~58 minutes ago
        )
        contextController.addItem(
            content: "User: Which renewable energy source is most efficient?",
            creationDate: baseDate.addingTimeInterval(-3400) // ~57 minutes ago
        )
        contextController.addItem(
            content: "Assistant: Solar and wind are among the most efficient renewable sources. Solar panels can convert 15-22% of sunlight to electricity, while modern wind turbines can achieve 40-50% efficiency. Hydroelectric power is also highly efficient at around 90%.",
            creationDate: baseDate.addingTimeInterval(-3300) // ~55 minutes ago
        )
        contextController.addItem(
            content: "User: What about the cost of renewable energy?",
            creationDate: baseDate.addingTimeInterval(-3200) // ~53 minutes ago
        )
        contextController.addItem(
            content: "Assistant: The cost of renewable energy has decreased significantly. Solar panel costs have dropped by about 90% since 2010. Wind energy is now one of the cheapest sources of electricity in many regions. The initial investment is higher, but long-term savings are substantial.",
            creationDate: baseDate.addingTimeInterval(-3100) // ~52 minutes ago
        )

        // Show items with timestamps
        for item in contextController.getItems() {
            print("[\(dateFormatter.string(from: item.creationDate))] \(item.text)")
        }
        print()

        // Summarize older items (items older than 0 days, which means all items)
        let serviceName = service.vendor == "Apple" ? "Apple Foundation Model" : service.vendor
        print("Summarizing older conversation items using \(serviceName)...")
        do {
            let startTime = Date()
            try await contextController.summarizeOlderContext(daysThreshold: 0)
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("✓ Summarization complete in \(String(format: "%.2f", elapsedTime)) seconds")
            print()

            // Show the generated summary
            let summaries = contextController.summarizedContext()
            if let firstSummary = summaries.first, let summaryText = firstSummary.text {
                print("Mid-Conversation Summary:")
                print(summaryText)
            }

            for _ in 0..<5 {
                print()
            }
        } catch {
            print("❌ Error during summarization: \(error)")
            print()
        }

        // Add more recent conversation items
        print("Adding more recent conversation items...")
        contextController.addItem(
            content: "User: How can I get started with renewable energy at home?",
            creationDate: baseDate.addingTimeInterval(-300) // 5 minutes ago
        )
        contextController.addItem(
            content: "Assistant: Great question! Start by conducting an energy audit, then consider solar panels, energy-efficient appliances, and smart home systems. Many governments offer tax incentives and rebates for renewable energy installations.",
            creationDate: baseDate.addingTimeInterval(-200) // ~3 minutes ago
        )
        
        // Show the newly added items
        let newItems = contextController.getItems().filter { !$0.isSummarized }
        for item in newItems {
            print("[\(dateFormatter.string(from: item.creationDate))] \(item.text)")
        }
        print()

        // Generate final summary using existing summaries plus non-summarized items
        print("Generating comprehensive summary using existing summaries plus new items using \(serviceName)...")
        do {
            // Debug: Show what we're combining
            let summaries = contextController.summarizedContext()
            let nonSummarizedItems = contextController.getItems().filter { !$0.isSummarized }
            print("  - Including \(summaries.count) existing summary(ies)")
            print("  - Including \(nonSummarizedItems.count) non-summarized item(s)")
            print()
            
            let startTime = Date()
            let finalSummary = try await contextController.generateComprehensiveSummary()
            let elapsedTime = Date().timeIntervalSince(startTime)

            print("✓ Comprehensive summary generated in \(String(format: "%.2f", elapsedTime)) seconds")
            print()
            print("Final Summary:")
            print(finalSummary)
            print()
        } catch {
            print("❌ Error generating comprehensive summary: \(error)")
            print()
        }
    }

    /// Creates an LLM service, preferring Apple Foundation Model with Anthropic as fallback.
    private func createLLMService() -> LLMServiceProtocol {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            #if canImport(FoundationModels)
            if let foundationService = FoundationModelService.createIfAvailable() {
                print("✓ Using Apple Foundation Model (on-device)")
                return foundationService
            } else {
                print("⚠️  Apple Foundation Model not available, falling back to Anthropic")
            }
            #else
            print("⚠️  FoundationModels not available, falling back to Anthropic")
            #endif
        } else {
            print("⚠️  Apple Foundation Model requires iOS 26/macOS 26/visionOS 26+, falling back to Anthropic")
        }

        let apiKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
        if apiKey == nil {
            print("⚠️  No Anthropic API key found. The example may fail.")
            print("   To fix: Set ANTHROPIC_API_KEY environment variable or use SecureStorage.saveAPIKey()")
        }
        return AnthropicService(apiKey: apiKey, logger: CustomLogger.shared)
    }
}
