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
        let anthropicApiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
        if let apiKey = anthropicApiKey {
            manager.registerService(AnthropicService(name: "DefaultAnthropic", apiKey: apiKey))
        } else {
            print("Warning: ANTHROPIC_API_KEY not set. Traditional Anthropic example will be skipped.")
        }

        let traditionalRequest = LLMRequest(messages: [LLMMessage(role: .user, content: "What is the capital of France?")])
        if let response = await manager.sendRequest(traditionalRequest) {
            print("Traditional Anthropic Response: \(response.text)")
        } else {
            print("Traditional Anthropic Request Failed: No response received")
        }

        // --- After: Using LLM Convenience APIs ---
        print("\n--- Using LLM Convenience APIs (After) ---")

        // 1. Simple Send Request (Anthropic)
        do {
            print("\nSending simple request to Anthropic via LLM.send:")
            let responseText = try await LLM.send("What is the capital of Germany?", to: LLM.anthropic)
            print("LLM.anthropic.send Response: \(responseText)")
        } catch {
            print("LLM.anthropic.send Failed: \(error.localizedDescription)")
        }

        // 2. Simple Send Request (OpenAI)
        do {
            print("\nSending simple request to OpenAI via LLM.send:")
            let responseText = try await LLM.send("What is the capital of Spain?", to: LLM.openai)
            print("LLM.openai.send Response: \(responseText)")
        } catch {
            print("LLM.openai.send Failed: \(error.localizedDescription)")
        }

        // 3. Streaming Request (Anthropic)
        do {
            print("\nSending streaming request to Anthropic via LLM.stream:")
            print("Streaming Anthropic Response:")
            _ = try await LLM.stream("Tell me a very short story about a brave knight.", to: LLM.anthropic) { partialResponse in
                print(partialResponse, terminator: "")
            }
            print("\n(Streaming complete)")
        } catch {
            print("LLM.anthropic.stream Failed: \(error.localizedDescription)")
        }

        // 4. Streaming Request (OpenAI)
        do {
            print("\nSending streaming request to OpenAI via LLM.stream:")
            print("Streaming OpenAI Response:")
            _ = try await LLM.stream("Write a haiku about a cherry blossom.", to: LLM.openai) { partialResponse in
                print(partialResponse, terminator: "")
            }
            print("\n(Streaming complete)")
        } catch {
            print("LLM.openai.stream Failed: \(error.localizedDescription)")
        }

        // 5. Direct service convenience method (Ollama)
        do {
            print("\nSending direct request to Ollama via LLM.ollama.send:")
            let ollamaResponse = try await LLM.ollama.send("What is the best way to learn Swift?")
            print("LLM.ollama.send Response: \(ollamaResponse)")
        } catch {
            print("LLM.ollama.send Failed: \(error.localizedDescription)")
        }

        // 6. Direct service convenience method (Foundation Models - if available)
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            if let foundationService = LLM.foundation {
                do {
                    print("\nSending direct request to Foundation Model via LLM.foundation.send:")
                    let fmResponse = try await foundationService.send("Summarize the main idea of a modular architecture.")
                    print("LLM.foundation.send Response: \(fmResponse)")
                } catch {
                    print("LLM.foundation.send Failed: \(error.localizedDescription)")
                }
            } else {
                print("\nFoundation Models service not available on this device/platform.")
            }
        } else {
            print("\nFoundation Models service requires iOS 26+, macOS 26+, or visionOS 26+.")
        }

        print("\n--- ConvenienceAPIExample Finished ---")
    }
}
