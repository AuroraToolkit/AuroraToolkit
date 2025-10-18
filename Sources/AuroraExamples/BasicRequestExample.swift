//
//  BasicRequestExample.swift
//  AuroraCore

import AuroraCore
import AuroraLLM
import Foundation

/// A basic example demonstrating how to send a request to the LLM service.
struct BasicRequestExample {
    func execute() async {
        // Set up the required API key for your LLM service with fallback logic
        // 1. Try SecureStorage first, 2. Fall back to environment variable, 3. Use nil as last resort
        let apiKey = SecureStorage.getAPIKey(for: "Anthropic") ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        
        if apiKey == nil {
            print("⚠️  No Anthropic API key found in SecureStorage or environment variables.")
            print("   The example will continue but API calls may fail.")
            print("   To fix: Set ANTHROPIC_API_KEY environment variable or use SecureStorage.saveAPIKey()")
        }

        // Initialize the LLMManager
        let manager = LLMManager()

        // Create and register a service (will use nil key if none found)
        let realService = AnthropicService(apiKey: apiKey, logger: CustomLogger.shared)
        manager.registerService(realService)

        // Create a basic request
        let messageContent = "What is the meaning of life? Use no more than 2 sentences."
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: messageContent)])

        print("Sending request to the LLM service...")
        print("Prompt: \(messageContent)")

        if let response = await manager.sendRequest(request) {
            // Handle the response
            let vendor = response.vendor ?? "Unknown"
            let model = response.model ?? "Unknown"
            print("Response received from vendor: \(vendor), model: \(model)\n\(response.text)")
        } else {
            print("No response received, possibly due to an error.")
        }
    }
}
