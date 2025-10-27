//
//  StreamingRequestExample.swift
//  AuroraCore

import AuroraCore
import AuroraLLM
import Foundation

/// An example demonstrating how to send a streaming request to the LLM service.
/// This example shows both the traditional approach and the new convenience API approach.
struct StreamingRequestExample {
    func execute() async {
        let messageContent = "What is the meaning of life? Use no more than 2 sentences."
        
        print("=== Traditional Approach ===")
        await executeTraditionalApproach(message: messageContent)
        
        print("\n=== Convenience API Approach ===")
        await executeConvenienceApproach(message: messageContent)
    }
    
    private func executeTraditionalApproach(message: String) async {
        // Set up the required API key for your LLM service with fallback logic
        // 1. Try SecureStorage first, 2. Fall back to environment variable, 3. Use nil as last resort
        let apiKey = SecureStorage.getAPIKey(for: "Anthropic") ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        
        if apiKey == nil {
            print("⚠️  No Anthropic API key found in SecureStorage or environment variables.")
            print("   The example will continue but API calls may fail.")
            print("   To fix: Set ANTHROPIC_API_KEY environment variable or use SecureStorage.saveAPIKey()")
        }

        // Initialize the LLMManager
        let manager = LLMManager(logger: CustomLogger.shared)

        // Create and register a service (will use nil key if none found)
        let realService = AnthropicService(apiKey: apiKey, logger: CustomLogger.shared)
        manager.registerService(realService)

        // Create a request for streaming response
        let request = LLMRequest(messages: [LLMMessage(role: .user, content: message)], stream: true)

        print("Sending streaming request to the LLM service...")
        print("Message content: \(message)")

        // Handle streaming response with a closure for partial responses
        var partialResponses = [String]()
        let onPartialResponse: (String) -> Void = { partialText in
            partialResponses.append(partialText)
            print("Partial response: \(partialText)")
        }

        if let response = await manager.sendStreamingRequest(request, onPartialResponse: onPartialResponse) {
            // Handle the final response
            let vendor = response.vendor ?? "Unknown"
            let model = response.model ?? "Unknown"
            print("Final response received from vendor: \(vendor), model: \(model)\n\(response.text)")
        } else {
            print("No response received, possibly due to an error.")
        }
    }
    
    private func executeConvenienceApproach(message: String) async {
        print("Sending streaming request using convenience API...")
        print("Message content: \(message)")
        
        do {
            // The convenience API will automatically use Foundation Model if available,
            // or the configured default service if Foundation Model is not available
            LLM.configure(with: LLM.anthropic)
            let response = try await LLM.stream(message) { partialText in
                print("Partial response: \(partialText)")
            }
            print("Final response: \(response)")
        } catch {
            print("Error: \(error)")
            
            // If Foundation Model is not available and no service is configured,
            // show how to configure a default service
            if let llmError = error as? LLMServiceError, 
               case .noDefaultServiceConfigured = llmError {
                print("\n💡 To fix this, configure a default service:")
                print("   LLM.configure(with: LLM.anthropic)")
                print("   // or")
                print("   LLM.configure(with: LLM.openai)")
                print("   // or")
                print("   LLM.configure(with: LLM.ollama)")
            }
        }
    }
}
