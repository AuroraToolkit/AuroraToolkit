//
//  LLMConfigurationExample.swift
//  AuroraCore

import AuroraCore
import AuroraLLM
import Foundation

/// An example demonstrating how to configure the default LLM service for convenience APIs.
/// This example shows the new Foundation Model-first approach with fallback configuration.
struct LLMConfigurationExample {
    func execute() async {
        print("🔧 LLM Configuration Example")
        print("===21=========================")

        // Test 1: Try using convenience API without configuration (will use Foundation Model if available)
        print("\n1. Testing convenience API without explicit configuration...")
        print("   (Will use Foundation Model if available, otherwise will show error)")
        await testConvenienceAPI(country: "Spain")

        // Test 2: Configure Anthropic as default and test
        print("\n2. Configuring Anthropic as default service...")
        LLM.configure(with: LLM.anthropic)
        await testConvenienceAPI(country: "France")

        // Test 3: Configure OpenAI as default and test
        print("\n3. Configuring OpenAI as default service...")
        LLM.configure(with: LLM.openai)
        await testConvenienceAPI(country: "Switzerland")

        // Test 4: Configure Google as default and test
        print("\n4. Configuring Google as default service...")
        LLM.configure(with: LLM.google)
        await testConvenienceAPI(country: "Germany")

        // Test 5: Configure Ollama as default and test
        print("\n5. Configuring Ollama as default service...")
        LLM.configure(with: LLM.ollama)
        await testConvenienceAPI(country: "Italy")

        print("\n✅ Configuration example completed!")
    }
    
    private func testConvenienceAPI(country: String) async {
        let message = "What is the capital of \(country)?"

        do {
            print("   Prompt: \(message)")
            let response = try await LLM.send(message, maxTokens: 50)
            print("   Response: \(response)")
        } catch {
            print("   Error: \(error)")
            
            if let llmError = error as? LLMServiceError {
                switch llmError {
                case .noDefaultServiceConfigured:
                    print("   💡 This means no service is configured and Foundation Model is not available.")
                    print("   💡 Use LLM.configure(with: service) to set a default service.")
                case .missingAPIKey:
                    print("   💡 API key is missing. Set it using SecureStorage.saveAPIKey() or environment variables.")
                default:
                    print("   💡 Other error occurred: \(llmError.localizedDescription)")
                }
            }
        }
    }
}
