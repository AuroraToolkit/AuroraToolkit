//
//  ConvenienceAPIExample.swift
//  AuroraExamples
//
//  Created on 10/18/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// This example demonstrates the use of the new `LLM` convenience APIs
/// for simplified interaction with Large Language Models.
///
/// It showcases how to send basic requests and streaming requests
/// without needing to manually set up `LLMManager` or `LLMRequest` objects.
struct ConvenienceAPIExample {
    func execute() async {
        print("--- Running ConvenienceAPIExample ---")

        // --- Before: Traditional LLMManager setup (for comparison) ---
        print("\n--- Traditional LLMManager Setup (Before) ---")
        let manager = LLMManager()
        
        let anthropicApiKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
        
        if let apiKey = anthropicApiKey {
            manager.registerService(AnthropicService(name: "DefaultAnthropic", apiKey: apiKey))
            
            let prompt = "What is the capital of France?"
            print("Prompt: \"\(prompt)\"")
            let traditionalRequest = LLMRequest(messages: [LLMMessage(role: .user, content: prompt)])
            if let response = await manager.sendRequest(traditionalRequest) {
                print("Traditional Anthropic Response: \(response.text)")
            } else {
                print("Traditional Anthropic Request Failed: No response received")
            }
        } else {
            print("Warning: No Anthropic API key found in SecureStorage or environment variables.")
            print("   The traditional example will be skipped.")
            print("   To fix: Set ANTHROPIC_API_KEY environment variable or use SecureStorage.saveAPIKey()")
        }

        // --- After: Using LLM Convenience APIs ---
        print("\n--- Using LLM Convenience APIs (After) ---")

        // 1. Simple Send Request (Anthropic)
        do {
            let prompt = "What is the capital of Germany?"
            print("\nSending simple request to Anthropic via LLM.send:")
            print("Prompt: \"\(prompt)\"")
            let anthropicKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
            let anthropicService = anthropicKey != nil ? LLM.anthropic.apiKey(anthropicKey!) : LLM.anthropic
            let responseText = try await LLM.send(prompt, to: anthropicService)
            print("LLM.anthropic.send Response: \(responseText)")
        } catch {
            print("LLM.anthropic.send Failed: \(error.localizedDescription)")
        }

        // 2. Simple Send Request (OpenAI)
        do {
            let prompt = "What is the capital of Spain?"
            print("\nSending simple request to OpenAI via LLM.send:")
            print("Prompt: \"\(prompt)\"")
            let openAIKey = APIKeyLoader.get("OPENAI_API_KEY", forService: "OpenAI")
            let openAIService = openAIKey != nil ? LLM.openai.apiKey(openAIKey!) : LLM.openai
            let responseText = try await LLM.send(prompt, to: openAIService)
            print("LLM.openai.send Response: \(responseText)")
        } catch {
            print("LLM.openai.send Failed: \(error.localizedDescription)")
        }

        // 3. Streaming Request (Anthropic)
        do {
            let prompt = "Tell me a very short story about a brave knight."
            print("\nSending streaming request to Anthropic via LLM.stream:")
            print("Prompt: \"\(prompt)\"")
            print("Streaming Anthropic Response:")
            let anthropicKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
            let anthropicService = anthropicKey != nil ? LLM.anthropic.apiKey(anthropicKey!) : LLM.anthropic
            _ = try await LLM.stream(prompt, to: anthropicService) { partialResponse in
                print(partialResponse, terminator: "")
            }
            print("\n(Streaming complete)")
        } catch {
            print("LLM.anthropic.stream Failed: \(error.localizedDescription)")
        }

        // 4. Streaming Request (OpenAI)
        do {
            let prompt = "Write a haiku about a cherry blossom."
            print("\nSending streaming request to OpenAI via LLM.stream:")
            print("Prompt: \"\(prompt)\"")
            print("Streaming OpenAI Response:")
            let openAIKey = APIKeyLoader.get("OPENAI_API_KEY", forService: "OpenAI")
            let openAIService = openAIKey != nil ? LLM.openai.apiKey(openAIKey!) : LLM.openai
            _ = try await LLM.stream(prompt, to: openAIService) { partialResponse in
                print(partialResponse, terminator: "")
            }
            print("\n(Streaming complete)")
        } catch {
            print("LLM.openai.stream Failed: \(error.localizedDescription)")
        }

        // 5. Direct service convenience method (Ollama - default model)
        do {
            let prompt = "What is the best way to learn Swift?"
            print("\nSending direct request to Ollama via LLM.ollama.send (default model):")
            print("Prompt: \"\(prompt)\"")
            let ollamaResponse = try await LLM.ollama.send(prompt)
            print("LLM.ollama.send Response: \(ollamaResponse)")
        } catch {
            print("LLM.ollama.send Failed: \(error.localizedDescription)")
        }

        // 6. Direct service convenience method (Ollama - specific model)
        do {
            let prompt = "Explain recursion in one sentence."
            print("\nSending direct request to Ollama via LLM.ollama.send with model 'gemma3:1b':")
            print("Prompt: \"\(prompt)\"")
            let ollamaResponse = try await LLM.ollama.send(prompt, model: "gemma3:1b")
            print("LLM.ollama.send (gemma3:1b) Response: \(ollamaResponse)")
        } catch {
            print("LLM.ollama.send (gemma3:1b) Failed: \(error.localizedDescription)")
            if let llmError = error as? LLMServiceError {
                print("   Error type: \(llmError)")
                if case .invalidResponse(let statusCode) = llmError {
                    print("   Status code: \(statusCode)")
                    print("   Note: This may indicate the model 'gemma3:1b' is not available. Ensure it's installed with: ollama pull gemma3:1b")
                }
            }
        }

        // 7. Direct service convenience method (Apple Apple Foundation Models - if available)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            if let foundationService = LLM.foundation {
                do {
                    let prompt = "Summarize the main idea of a modular architecture."
                    print("\nSending direct request to Apple Foundation Model via LLM.foundation.send:")
                    print("Prompt: \"\(prompt)\"")
                    let fmResponse = try await foundationService.send(prompt)
                    print("LLM.foundation.send Response: \(fmResponse)")
                } catch {
                    print("LLM.foundation.send Failed: \(error.localizedDescription)")
                }
            } else {
                print("\nApple Apple Foundation Models service not available on this device/platform.")
            }
        } else {
            print("\nApple Apple Foundation Models service requires iOS 26+, macOS 26+, or visionOS 26+.")
        }

        print("\n--- ConvenienceAPIExample Finished ---")
    }
}
