//
//  MultiModelConversationExample.swift
//  AuroraExamples
//
//  Created by Dan Murrell Jr on 9/17/25.
//

import AuroraLLM
import AuroraCore
import Foundation

/// Example demonstrating dynamic multi-model conversations with various interaction scenarios.
/// 
/// This example shows how to:
/// - Initialize multiple AI services (Anthropic, OpenAI, Google, Ollama, Foundation Models)
/// - Set up flexible conversations between 1-N models with different scenarios
/// - Manage turn-based dialogue with configurable personalities
/// - Support different interaction types (rap battles, teaching, word games, etc.)
public struct MultiModelConversationExample {
    
    struct ConversationScenario {
        let name: String
        let description: String
        let personalities: [String]
        let initialPrompt: String
        let continuationPrompt: String
    }

    public func execute(numberOfResponses: Int = 4) async {
        print("Setting up multi-model conversation...")

        // Initialize available services
        let services = await initializeAvailableServices()

        guard !services.isEmpty else {
            print("No services available to run this example.")
            return
        }

        // Select random scenario
        let scenarios = createScenarios()
        let selectedScenario = scenarios.randomElement()!
        
        print("Selected scenario: \(selectedScenario.name)")
        print("Description: \(selectedScenario.description)")
        
        // Determine how many models to use (up to available services, max personalities)
        let maxParticipants = min(selectedScenario.personalities.count, services.count)
        let participants = Array(services.shuffled().prefix(maxParticipants))
        
        print("Participants (\(participants.count)):")
        for (index, participant) in participants.enumerated() {
            print("  \(index + 1). \(participant.vendor) - \(participant.name)")
        }
        
        print("\n" + String(repeating: "=", count: 60))

        await runConversation(
            participants: participants,
            scenario: selectedScenario,
            numberOfResponses: numberOfResponses
        )
    }

    private func initializeAvailableServices() async -> [LLMServiceProtocol] {
        var services: [LLMServiceProtocol] = []

        // Try to initialize Anthropic service
        if let anthropicKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !anthropicKey.isEmpty {
            let anthropicService = AnthropicService(apiKey: anthropicKey, maxOutputTokens: 512)
            services.append(anthropicService)
            print("✓ Anthropic service initialized")
        }

        // Try to initialize OpenAI service
        if let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !openAIKey.isEmpty {
            let openAIService = OpenAIService(apiKey: openAIKey, maxOutputTokens: 512)
            services.append(openAIService)
            print("✓ OpenAI service initialized")
        }

        // Try to initialize Google service
        if let googleKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"], !googleKey.isEmpty {
            let googleService = GoogleService(apiKey: googleKey, maxOutputTokens: 512)
            services.append(googleService)
            print("✓ Google service initialized")
        }

        // Try to initialize Ollama service (no API key needed)
        let ollamaService = OllamaService(maxOutputTokens: 512)
        services.append(ollamaService)
        print("✓ Ollama service initialized")

        // Try to initialize Foundation Model service (iOS 26+/macOS 26+)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            do {
                let foundationService = try FoundationModelService(
                    name: "Apple Intelligence",
                    contextWindowSize: 4096,
                    maxOutputTokens: 512,
                    systemPrompt: "You are a thoughtful AI assistant participating in a discussion."
                )
                if FoundationModelService.isAvailable() {
                    services.append(foundationService)
                    print("✓ Foundation Model service initialized")
                } else {
                    print("⚠ Foundation Model service not available on this device")
                }
            } catch {
                print("⚠ Foundation Model service initialization failed: \(error)")
            }
        }

        return services
    }
    
    private func createScenarios() -> [ConversationScenario] {
        return [
            ConversationScenario(
                name: "Rap Battle",
                description: "Two rappers trading bars with wordplay, rhythm, and clever disses",
                personalities: [
                    "You are a confident rapper with a smooth flow and clever wordplay. Start strong with opening bars that set the tone. Use internal rhymes, attitude, and playful competitive energy. Keep it fun but fierce.",
                    "You are a fierce rapper known for quick wit and sharp comebacks. Fire back with creative rhymes, unexpected metaphors, and skillful wordplay. Match the energy and raise the stakes. Make every line count."
                ],
                initialPrompt: "🎤 RAP BATTLE TIME! The beat drops... who's going first?",
                continuationPrompt: "Drop those bars! Keep the energy high and the rhymes tight."
            ),
            ConversationScenario(
                name: "Teacher & Student",
                description: "A Socratic dialogue where teacher guides student through discovery",
                personalities: [
                    "You are a wise, patient teacher who uses the Socratic method. Start by asking an engaging question about the topic to get the student thinking. Ask probing questions to guide discovery rather than giving direct answers. Be encouraging and build on responses.",
                    "You are an eager, curious student who asks genuine questions and builds on what you learn. You might make mistakes or have misconceptions - that's part of learning! Be enthusiastic, answer questions thoughtfully, and ask follow-up questions when curious."
                ],
                initialPrompt: "Today's topic is: What makes something 'intelligent'? Let's explore this together through discussion.",
                continuationPrompt: "Continue the learning dialogue. Build on what was just shared."
            ),
            ConversationScenario(
                name: "Word Association Chain", 
                description: "Rapid-fire word associations that build creative connections",
                personalities: [
                    "You are playing word association. Start with the given word and make a creative connection to something new. Briefly explain your association with wit and creativity. Keep it snappy and surprising!",
                    "You are playing word association. Take the previous word/phrase and connect it to something unexpected but logical. Be creative with your associations and explain your reasoning in a fun, engaging way."
                ],
                initialPrompt: "WORD ASSOCIATION GAME! Starting word: 'Lightning'",
                continuationPrompt: "Quick! What's your association? Keep the chain going!"
            )
        ]
    }
    
    private func runConversation(
        participants: [LLMServiceProtocol],
        scenario: ConversationScenario,
        numberOfResponses: Int
    ) async {
        var conversationHistory: [LLMMessage] = []

        print("\nStarting conversation...")
        print("Moderator: \(scenario.initialPrompt)")
        print()

        do {
            // Start the conversation
            conversationHistory.append(LLMMessage(role: .user, content: scenario.initialPrompt))

            for responseCount in 0..<numberOfResponses {
                let participantIndex = responseCount % participants.count
                let currentParticipant = participants[participantIndex]
                let personality = scenario.personalities[min(participantIndex, scenario.personalities.count - 1)]
                
                let (response, responseTime) = try await getModelResponseWithTiming(
                    service: currentParticipant,
                    personality: personality,
                    conversationHistory: conversationHistory
                )

                print("\(currentParticipant.vendor) (\(currentParticipant.name)) [\(String(format: "%.2f", responseTime))s]: \(response)")
                conversationHistory.append(LLMMessage(role: .assistant, content: response))
                
                // Add continuation prompt if not the last response
                if responseCount < numberOfResponses - 1 {
                    conversationHistory.append(LLMMessage(role: .user, content: scenario.continuationPrompt))
                }
                
                // Add spacing between responses
                if responseCount < numberOfResponses - 1 {
                    print()
                }
            }

            print("\n" + String(repeating: "=", count: 60))
            print("Conversation completed successfully!")
            print("Total responses: \(numberOfResponses)")
            print("Participants: \(participants.count)")

        } catch {
            print("Error during conversation: \(error)")
            print("Conversation stopped due to error.")
        }
    }

    private func getModelResponseWithTiming(
        service: LLMServiceProtocol,
        personality: String,
        conversationHistory: [LLMMessage]
    ) async throws -> (response: String, timeInSeconds: Double) {
        var messages = [LLMMessage(role: .system, content: personality)]
        messages.append(contentsOf: conversationHistory)

        let request = LLMRequest(
            messages: messages,
            maxTokens: 150
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        let response = try await service.sendRequest(request)
        let endTime = CFAbsoluteTimeGetCurrent()

        let timeElapsed = endTime - startTime
        return (response.text, timeElapsed)
    }
}
