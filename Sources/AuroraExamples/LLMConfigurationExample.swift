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
        print("============================")
        
        let message = "What is the capital of France?"
        
        // Test 1: Try using convenience API without configuration (will use Foundation Model if available)
        print("\n1. Testing convenience API without explicit configuration...")
        print("   (Will use Foundation Model if available, otherwise will show error)")
        await testConvenienceAPI(message: message)
        
        // Test 2: Configure Anthropic as default and test
        print("\n2. Configuring Anthropic as default service...")
        LLM.configure(with: LLM.anthropic)
        await testConvenienceAPI(message: message)
        
        // Test 3: Configure OpenAI as default and test
        print("\n3. Configuring OpenAI as default service...")
        LLM.configure(with: LLM.openai)
        await testConvenienceAPI(message: message)
        
        // Test 4: Configure Ollama as default and test
        print("\n4. Configuring Ollama as default service...")
        LLM.configure(with: LLM.ollama)
        await testConvenienceAPI(message: message)
        
        print("\n✅ Configuration example completed!")
    }
    
    private func testConvenienceAPI(message: String) async {
        do {
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
