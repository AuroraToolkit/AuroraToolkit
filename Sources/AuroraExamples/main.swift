//
//  main.swift

import AuroraCore
import Foundation

// swiftlint:disable orphaned_doc_comment

/// These examples use a mix of Anthropic, OpenAI, Google, and Ollama models.
///
/// To run these examples, you must have the following environment variables set:
///    - OPENAI_API_KEY: Your OpenAI API key
///    - ANTHROPIC_API_KEY: Your Anthropic API key
///    - GOOGLE_API_KEY: Your Google API key
///
///    You can set these environment variables in the `Examples` scheme or by using the following commands:
///    ```
///    export OPENAI_API_KEY="your-openai-api-key"
///    export ANTHROPIC_API_KEY="your-anthropic-api-key"
///    export GOOGLE_API_KEY="your-google-api-key"
///    ```
///
///    Additionally, you must have the Ollama service running locally on port 11434.
///
///    These examples demonstrate how to:
///    - Make requests to different LLM services
///    - Stream requests to a service
///    - Route requests between services based on token limits
///    - Route requests between services based on the domain
///
///    Each example is self-contained and demonstrates a specific feature of the Aurora Core framework.
///
/// To run these examples, execute the following command in the terminal from the root directory of the project:
///    ```
///    swift run AuroraExamples
///    ```

// Uncomment the following line to disable debug logs
// CustomLogger.shared.toggleDebugLogs(false)

// MARK: - Example Menu System

struct ExampleRunner {
    static func run() async {
        print("🚀 Aurora Core Examples")
        print("======================")
        print()
        
        let examples: [(String, () async -> Void)] = [
            ("Basic Request", { await BasicRequestExample().execute() }),
            ("Streaming Request", { await StreamingRequestExample().execute() }),
            ("LLM Routing", { await LLMRoutingExample().execute() }),
            ("Domain Routing", { await DomainRoutingExample().execute() }),
            ("Dual Domain Routing", { await DualDomainRoutingExample().execute() }),
            ("Siri Style Domain Routing", { await SiriStyleDomainRoutingExample().execute() }),
            ("Logic Domain Routing", { await LogicDomainRouterExample().execute() }),
            ("TV Script Workflow", { await TVScriptWorkflowExample().execute() }),
            ("Translate Text Workflow", { await LeMondeTranslationWorkflow().execute() }),
            ("Customer Feedback Analysis Workflow", { await CustomerFeedbackAnalysisWorkflow().execute() }),
            ("Temperature Monitor Workflow", { await TemperatureMonitorWorkflow().execute() }),
            ("Blog Post Categorization Workflow", { await BlogCategoryWorkflowExample().execute() }),
            ("Support Ticket Analysis Workflow", { await SupportTicketWorkflowExample().execute(on: "My account is locked after too many login attempts.") }),
            ("Github Issues Triage Workflow", { await IssueTriageWorkflowExample().execute(on: "App crashes with error E401 when I press Save") }),
            ("Foundation Model", { await FoundationModelExample().execute() }),
            ("Two Model Conversation", { await MultiModelConversationExample().execute() }),
            ("Convenience API", { await ConvenienceAPIExample().execute() })
        ]
        
        while true {
            printMenu(examples)
            
            guard let input = readLine() else {
                print("❌ No input received. Exiting...")
                return
            }
            
            let choice = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            switch choice.lowercased() {
            case "all", "a":
                await runAllExamples(examples)
                return
            case "quit", "q", "exit":
                print("👋 Goodbye!")
                return
            default:
                if let index = Int(choice), index >= 1 && index <= examples.count {
                    await runSingleExample(examples[index - 1])
                } else {
                    print("❌ Invalid choice. Please try again.")
                    print()
                }
            }
        }
    }
    
    private static func printMenu(_ examples: [(String, () async -> Void)]) {
        print("📋 Available Examples:")
        print("=====================")
        
        for (index, example) in examples.enumerated() {
            print("\(index + 1). \(example.0)")
        }
        
        print()
        print("Options:")
        print("• Enter a number (1-\(examples.count)) to run a specific example")
        print("• Enter 'all' or 'a' to run all examples")
        print("• Enter 'quit', 'q', or 'exit' to exit")
        print()
        print("Your choice: ", terminator: "")
    }
    
    private static func runSingleExample(_ example: (String, () async -> Void)) async {
        print()
        print("🎯 Running: \(example.0)")
        print("=" + String(repeating: "=", count: example.0.count + 10))
        print()
        
        await example.1()
        
        print()
        print("✅ \(example.0) completed!")
        print("Press Enter to continue...")
        _ = readLine()
        print()
    }
    
    private static func runAllExamples(_ examples: [(String, () async -> Void)]) async {
        print()
        print("🚀 Running All Examples")
        print("=======================")
        print()
        
        for (index, example) in examples.enumerated() {
            print("🎯 Running Example \(index + 1)/\(examples.count): \(example.0)")
            print("=" + String(repeating: "=", count: example.0.count + 30))
            print()
            
            await example.1()
            
            print()
            print("✅ \(example.0) completed!")
            
            if index < examples.count - 1 {
                print("--------------------")
                print()
            }
        }
        
        print()
        print("🎉 All examples completed!")
    }
    
    // MARK: - Non-Interactive Methods
    
    static func runAllExamplesDirectly() async {
        let examples: [(String, () async -> Void)] = [
            ("Basic Request", { await BasicRequestExample().execute() }),
            ("Streaming Request", { await StreamingRequestExample().execute() }),
            ("LLM Routing", { await LLMRoutingExample().execute() }),
            ("Domain Routing", { await DomainRoutingExample().execute() }),
            ("Dual Domain Routing", { await DualDomainRoutingExample().execute() }),
            ("Siri Style Domain Routing", { await SiriStyleDomainRoutingExample().execute() }),
            ("Logic Domain Routing", { await LogicDomainRouterExample().execute() }),
            ("TV Script Workflow", { await TVScriptWorkflowExample().execute() }),
            ("Translate Text Workflow", { await LeMondeTranslationWorkflow().execute() }),
            ("Customer Feedback Analysis Workflow", { await CustomerFeedbackAnalysisWorkflow().execute() }),
            ("Temperature Monitor Workflow", { await TemperatureMonitorWorkflow().execute() }),
            ("Blog Post Categorization Workflow", { await BlogCategoryWorkflowExample().execute() }),
            ("Support Ticket Analysis Workflow", { await SupportTicketWorkflowExample().execute(on: "My account is locked after too many login attempts.") }),
            ("Github Issues Triage Workflow", { await IssueTriageWorkflowExample().execute(on: "App crashes with error E401 when I press Save") }),
            ("Foundation Model", { await FoundationModelExample().execute() }),
            ("Two Model Conversation", { await MultiModelConversationExample().execute() }),
            ("Convenience API", { await ConvenienceAPIExample().execute() })
        ]
        
        await runAllExamples(examples)
    }
    
    static func runSingleExampleDirectly(_ index: Int) async {
        let examples: [(String, () async -> Void)] = [
            ("Basic Request", { await BasicRequestExample().execute() }),
            ("Streaming Request", { await StreamingRequestExample().execute() }),
            ("LLM Routing", { await LLMRoutingExample().execute() }),
            ("Domain Routing", { await DomainRoutingExample().execute() }),
            ("Dual Domain Routing", { await DualDomainRoutingExample().execute() }),
            ("Siri Style Domain Routing", { await SiriStyleDomainRoutingExample().execute() }),
            ("Logic Domain Routing", { await LogicDomainRouterExample().execute() }),
            ("TV Script Workflow", { await TVScriptWorkflowExample().execute() }),
            ("Translate Text Workflow", { await LeMondeTranslationWorkflow().execute() }),
            ("Customer Feedback Analysis Workflow", { await CustomerFeedbackAnalysisWorkflow().execute() }),
            ("Temperature Monitor Workflow", { await TemperatureMonitorWorkflow().execute() }),
            ("Blog Post Categorization Workflow", { await BlogCategoryWorkflowExample().execute() }),
            ("Support Ticket Analysis Workflow", { await SupportTicketWorkflowExample().execute(on: "My account is locked after too many login attempts.") }),
            ("Github Issues Triage Workflow", { await IssueTriageWorkflowExample().execute(on: "App crashes with error E401 when I press Save") }),
            ("Foundation Model", { await FoundationModelExample().execute() }),
            ("Two Model Conversation", { await MultiModelConversationExample().execute() }),
            ("Convenience API", { await ConvenienceAPIExample().execute() })
        ]
        
        if index >= 1 && index <= examples.count {
            await runSingleExample(examples[index - 1])
        } else {
            print("❌ Invalid example number: \(index)")
        }
    }
}

// MARK: - Main Execution

// Check for command line arguments
let arguments = CommandLine.arguments

if arguments.count > 1 {
    let choice = arguments[1]
    
    switch choice.lowercased() {
    case "all", "a":
        print("🚀 Running All Examples (Non-Interactive Mode)")
        print("=============================================")
        print()
        await ExampleRunner.runAllExamplesDirectly()
    case "help", "h", "-h", "--help":
        print("🚀 Aurora Core Examples")
        print("======================")
        print()
        print("Usage:")
        print("  swift run AuroraExamples           # Interactive menu")
        print("  swift run AuroraExamples all       # Run all examples")
        print("  swift run AuroraExamples help      # Show this help")
        print()
        print("Interactive Options:")
        print("  • Enter a number (1-17) to run a specific example")
        print("  • Enter 'all' or 'a' to run all examples")
        print("  • Enter 'quit', 'q', or 'exit' to exit")
    default:
        if let index = Int(choice), index >= 1 && index <= 17 {
            print("🎯 Running Example \(index) (Non-Interactive Mode)")
            print("===============================================")
            print()
            await ExampleRunner.runSingleExampleDirectly(index)
        } else {
            print("❌ Invalid argument: \(choice)")
            print("Use 'swift run AuroraExamples help' for usage information.")
        }
    }
} else {
    // Interactive mode
    await ExampleRunner.run()
}

// swiftlint:enable orphaned_doc_comment
