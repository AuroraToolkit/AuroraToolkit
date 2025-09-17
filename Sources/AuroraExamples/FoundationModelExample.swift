//
//  FoundationModelExample.swift
//  AuroraExamples
//
//  Created by Dan Murrell Jr on 9/16/25.
//

import AuroraLLM
import AuroraCore
import Foundation

/// Example demonstrating Apple Foundation Models integration for on-device AI processing.
/// 
/// This example shows how to:
/// - Check Foundation Models availability
/// - Create and configure a FoundationModelService
/// - Send requests using on-device AI
/// - Handle platform compatibility gracefully
public struct FoundationModelExample {

    public init() {}

    public func execute() async {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            await executeFoundationModelExample()
        } else {
            print("Foundation Models requires iOS 26+/macOS 26+ or later")
            print("   Current platform not supported")
        }
    }

    @available(iOS 26, macOS 26, visionOS 26, *)
    private func executeFoundationModelExample() async {
        // Check if Foundation Models is available on this device
        guard FoundationModelService.isAvailable() else {
            print("Foundation Models not available")
            print("   Requires iOS 26+/macOS 26+ with Apple Intelligence enabled")
            print("   Supported hardware: iPhone 15 Pro or later")
            return
        }

        print("Foundation Models are available")

        do {
            // Create Foundation Model service (no API key required)
            let service = try FoundationModelService(
                name: "On-Device AI",
                contextWindowSize: 4096,    // Apple's documented limit
                maxOutputTokens: 1024,      // Leave room for input tokens
                systemPrompt: "You are a helpful assistant running on-device."
            )

            print("Created Foundation Model service: \(service.vendor) - \(service.name)")
            print("   Context window: \(service.contextWindowSize) tokens")
            print("   Max output: \(service.maxOutputTokens) tokens")

            // Example 1: Simple text generation
            print("\n--- Example 1: Simple Generation ---")
            let simplePrompt = "Explain quantum computing in one sentence."
            let simpleRequest = LLMRequest(
                messages: [
                    LLMMessage(role: .user, content: simplePrompt)
                ],
                maxTokens: 50
            )

            print("Prompt: \(simplePrompt)")
            let simpleResponse = try await service.sendRequest(simpleRequest)
            print("Response: \(simpleResponse.text)")
            if let usage = simpleResponse.tokenUsage {
                print("Token usage: \(usage.promptTokens) + \(usage.completionTokens) = \(usage.totalTokens)")
            }

            // Example 2: Streaming response
            print("\n--- Example 2: Streaming Response ---")
            let streamingPrompt = "List 3 benefits of on-device AI processing."
            let streamingRequest = LLMRequest(
                messages: [
                    LLMMessage(role: .user, content: streamingPrompt)
                ],
                maxTokens: 100
            )

            print("Prompt: \(streamingPrompt)")
            print("Streaming response: ", terminator: "")
            _ = try await service.sendStreamingRequest(streamingRequest) { partial in
                print(partial, terminator: "")
            }
            print("\nStreaming complete")

            // Example 3: Conversation with context
            print("\n--- Example 3: Multi-turn Conversation ---")
            let conversationMessages = [
                LLMMessage(role: .system, content: "You are a concise assistant."),
                LLMMessage(role: .user, content: "What is machine learning?"),
                LLMMessage(role: .assistant, content: "Machine learning is a subset of AI that enables computers to learn and improve from data without explicit programming."),
                LLMMessage(role: .user, content: "Give me a simple example.")
            ]

            print("Conversation context:")
            print("   System: You are a concise assistant.")
            print("   User: What is machine learning?")
            print("   Assistant: Machine learning is a subset of AI that enables computers to learn and improve from data without explicit programming.")
            print("   User: Give me a simple example.")

            let conversationRequest = LLMRequest(
                messages: conversationMessages,
                maxTokens: 80
            )

            let conversationResponse = try await service.sendRequest(conversationRequest)
            print("Conversation response: \(conversationResponse.text)")

            // Example 4: Turn-by-turn conversation with follow-ups
            print("\n--- Example 4: Turn-by-turn Conversation ---")
            await executeTurnByTurnConversation(service: service)

            // Example 5: Using with LLMManager
            print("\n--- Example 5: Integration with LLMManager ---")
            let manager = LLMManager()
            manager.registerService(service)

            let managerPrompt = "What are the privacy benefits of on-device AI?"
            let managerRequest = LLMRequest(
                messages: [
                    LLMMessage(role: .user, content: managerPrompt)
                ],
                maxTokens: 60
            )

            print("Prompt: \(managerPrompt)")
            if let managerResponse = await manager.sendRequest(managerRequest) {
                print("Manager response: \(managerResponse.text)")
            }

        } catch LLMServiceError.serviceUnavailable(let message) {
            print("Service unavailable: \(message)")
            print("   Apple Intelligence may not be enabled on this device")
        } catch {
            print("Error: \(error)")
        }
    }

    @available(iOS 26, macOS 26, visionOS 26, *)
    private func executeTurnByTurnConversation(service: FoundationModelService) async {
        // Array of question/follow-up pairs based on expected responses
        let conversationFlow = [
            (
                question: "What is artificial intelligence?",
                followUps: [
                    "Can you give me a practical example?",
                    "What are some real-world applications?"
                ]
            ),
            (
                question: "How does machine learning work?",
                followUps: [
                    "What's the difference between supervised and unsupervised learning?",
                    "Can you explain this in simpler terms?"
                ]
            ),
            (
                question: "What are neural networks?",
                followUps: [
                    "How are they similar to the human brain?",
                    "What makes them so powerful?"
                ]
            )
        ]

        // Pick a random conversation topic
        let selectedTopic = conversationFlow.randomElement()!

        var messages: [LLMMessage] = [
            LLMMessage(role: .system, content: "You are a helpful and concise assistant. Keep your responses brief and informative.")
        ]

        do {
            // First question
            print("Starting conversation with: \(selectedTopic.question)")
            messages.append(LLMMessage(role: .user, content: selectedTopic.question))

            let firstRequest = LLMRequest(messages: messages, maxTokens: 100)
            let firstResponse = try await service.sendRequest(firstRequest)
            print("AI: \(firstResponse.text)")

            messages.append(LLMMessage(role: .assistant, content: firstResponse.text))

            // First follow-up
            let firstFollowUp = selectedTopic.followUps[0]
            print("\nFollow-up 1: \(firstFollowUp)")
            messages.append(LLMMessage(role: .user, content: firstFollowUp))

            let secondRequest = LLMRequest(messages: messages, maxTokens: 100)
            let secondResponse = try await service.sendRequest(secondRequest)
            print("AI: \(secondResponse.text)")

            messages.append(LLMMessage(role: .assistant, content: secondResponse.text))

            // Second follow-up
            let secondFollowUp = selectedTopic.followUps[1]
            print("\nFollow-up 2: \(secondFollowUp)")
            messages.append(LLMMessage(role: .user, content: secondFollowUp))

            let thirdRequest = LLMRequest(messages: messages, maxTokens: 100)
            let thirdResponse = try await service.sendRequest(thirdRequest)
            print("AI: \(thirdResponse.text)")

            print("\nConversation completed successfully!")

        } catch {
            print("Error during conversation: \(error)")
            print("Stopping conversation due to error.")
        }
    }
}
