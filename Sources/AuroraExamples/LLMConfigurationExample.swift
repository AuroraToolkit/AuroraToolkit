//
//  LLMConfigurationExample.swift
//  AuroraCore

import AuroraCore
import AuroraLLM
import Foundation

/// An example demonstrating how to configure the default LLM service for convenience APIs.
/// This example shows the new Apple Foundation Model-first approach with fallback configuration.
struct LLMConfigurationExample {
    func execute() async {
        print("🔧 LLM Configuration Example")
        print("===21=========================")

        // Test 1: Try using convenience API without configuration (will use Apple Foundation Model if available)
        print("\n1. Testing convenience API without explicit configuration...")
        print("   (Will use Apple Foundation Model if available, otherwise will show error)")
        await testConvenienceAPI(country: "Spain")

        // Test 2: Configure Anthropic as default and test
        print("\n2. Configuring Anthropic as default service...")
        let anthropicKey = APIKeyLoader.get("ANTHROPIC_API_KEY", forService: "Anthropic")
        await LLM.configure(with: anthropicKey != nil ? LLM.anthropic.apiKey(anthropicKey!) : LLM.anthropic)
        await testConvenienceAPI(country: "France")

        // Test 3: Configure OpenAI as default and test
        print("\n3. Configuring OpenAI as default service...")
        let openAIKey = APIKeyLoader.get("OPENAI_API_KEY", forService: "OpenAI")
        await LLM.configure(with: openAIKey != nil ? LLM.openai.apiKey(openAIKey!) : LLM.openai)
        await testConvenienceAPI(country: "Switzerland")

        // Test 3b: Explicit OpenAI Responses API using gpt-5-nano
        print("\n3b. Configuring OpenAI Responses (gpt-5-nano)...")
        await LLM.configure(with: openAIKey != nil ? LLM.openai.apiKey(openAIKey!) : LLM.openai)
        await testOpenAIResponses(country: "Portugal")

        // Test 4: Configure Google as default and test
        print("\n4. Configuring Google as default service...")
        let googleKey = APIKeyLoader.get("GOOGLE_API_KEY", forService: "Google")
        await LLM.configure(with: googleKey != nil ? LLM.google.apiKey(googleKey!) : LLM.google)
        await testConvenienceAPI(country: "Germany")

        // Test 5: Configure Ollama as default and test
        print("\n5. Configuring Ollama as default service...")
        await LLM.configure(with: LLM.ollama)
        await testConvenienceAPI(country: "Italy")

        print("\n✅ Configuration example completed!")
    }
    
    private func testConvenienceAPI(country: String) async {
        let message = "What is the capital of \(country)?"
        let start = CFAbsoluteTimeGetCurrent()
        var duration: CFAbsoluteTime = 0

        do {
            print("   Prompt: \(message)")
            let response = try await LLM.send(message, maxTokens: 1000)
            duration = CFAbsoluteTimeGetCurrent() - start
            print("   Response: \(response)")
        } catch {
            duration = CFAbsoluteTimeGetCurrent() - start
            print("   Error: \(error)")
            
            if let llmError = error as? LLMServiceError {
                switch llmError {
                case .noDefaultServiceConfigured:
                    print("   💡 This means no service is configured and Apple Foundation Model is not available.")
                    print("   💡 Use LLM.configure(with: service) to set a default service.")
                case .missingAPIKey:
                    print("   💡 API key is missing. Set it using SecureStorage.saveAPIKey() or environment variables.")
                default:
                    print("   💡 Other error occurred: \(llmError.localizedDescription)")
                }
            }
        }
        print("   Request took: \(String(format: "%.3f", duration))s")
    }

    private func testOpenAIResponses(country: String) async {
        let message = "What is the capital of \(country)?"
        let start = CFAbsoluteTimeGetCurrent()
        var duration: CFAbsoluteTime = 0

        do {
            print("   Prompt: \(message)")
            let request = LLMRequest(
                messages: [LLMMessage(role: .user, content: message)],
                temperature: 0.2,
                maxTokens: 1000,
                model: "gpt-5-nano",
                options: LLMRequestOptions(transport: .responses)
            )
            // Use the configured default service (OpenAI was configured in Test 3)
            let service = try await LLM.getDefaultService()
            let response = try await service.sendRequest(request)
            duration = CFAbsoluteTimeGetCurrent() - start
            print("   Response (Responses API): \(response.text)")
        } catch {
            duration = CFAbsoluteTimeGetCurrent() - start
            print("   Error (Responses API): \(error)")
        }
        print("   Request took: \(String(format: "%.3f", duration))s")
    }
}
