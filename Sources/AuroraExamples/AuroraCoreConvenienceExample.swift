//
//  AuroraCoreConvenienceExample.swift
//  AuroraExamples
//
//  Created on 1/15/25.
//

import AuroraCore
import AuroraLLM
import Foundation

/// Example demonstrating AuroraCore convenience APIs for simplified workflow and task creation.
///
/// This example shows the "before" (traditional AuroraCore usage) and "after" (using convenience APIs)
/// for common workflow patterns, demonstrating how the convenience APIs reduce boilerplate while
/// maintaining the full power of the AuroraCore workflow system.
class AuroraCoreConvenienceExample {
    
    func execute() async {
        print("🔧 AuroraCore Convenience APIs Example")
        print("=====================================")
        print()
        
        // Demonstrate the difference between traditional and convenience APIs
        await demonstrateWorkflowCreation()
        await demonstrateTaskCreation()
        await demonstrateCommonPatterns()
        await demonstrateUtilityFunctions()
        await demonstrateWorkflowExtensions()
    }
    
    // MARK: - Workflow Creation Examples
    
    private func demonstrateWorkflowCreation() async {
        print("1. Workflow Creation Comparison")
        print("-------------------------------")
        
        // Traditional approach
        print("Traditional Workflow Creation:")
        var traditionalWorkflow = Workflow(
            name: "Traditional Workflow",
            description: "A workflow created using traditional AuroraCore APIs",
            logger: CustomLogger.shared
        ) {
            Workflow.Task(name: "TraditionalTask", description: "A traditional task") { _ in
                return ["result": "traditional"]
            }
        }
        
        await traditionalWorkflow.start()
        print("   Traditional workflow executed with outputs: \(traditionalWorkflow.outputs)")
        
        // Convenience approach
        print("\nConvenience Workflow Creation:")
        var convenienceWorkflow = AuroraCore.workflow(
            "Convenience Workflow",
            description: "A workflow created using convenience APIs"
        ) {
            AuroraCore.task("ConvenienceTask", description: "A convenience task") { _ in
                return ["result": "convenience"]
            }
        }
        
        await convenienceWorkflow.start()
        print("   Convenience workflow executed with outputs: \(convenienceWorkflow.outputs)")
        
        // Auto-named workflow
        print("\nAuto-named Workflow Creation:")
        var autoNamedWorkflow = AuroraCore.workflow(description: "An auto-named workflow") {
            AuroraCore.task(description: "An auto-named task") { _ in
                return ["result": "auto-named"]
            }
        }
        
        await autoNamedWorkflow.start()
        print("   Auto-named workflow '\(autoNamedWorkflow.name)' executed with outputs: \(autoNamedWorkflow.outputs)")
        
        print()
    }
    
    // MARK: - Task Creation Examples
    
    private func demonstrateTaskCreation() async {
        print("2. Task Creation Comparison")
        print("---------------------------")
        
        // Traditional approach
        print("Traditional Task Creation:")
        let traditionalTask = Workflow.Task(
            name: "TraditionalTask",
            description: "A task created using traditional AuroraCore APIs",
            inputs: ["input": "test"],
            executeBlock: { inputs in
                let input = inputs["input"] as? String ?? "default"
                return ["processed": input.uppercased()]
            }
        )
        
        let traditionalOutputs = try! await traditionalTask.execute()
        print("   Traditional task executed with outputs: \(traditionalOutputs)")
        
        // Convenience approach
        print("\nConvenience Task Creation:")
        let convenienceTask = AuroraCore.task(
            "ConvenienceTask",
            description: "A task created using convenience APIs",
            inputs: ["input": "test"]
        ) { inputs in
            let input = inputs["input"] as? String ?? "default"
            return ["processed": input.uppercased()]
        }
        
        let convenienceOutputs = try! await convenienceTask.execute()
        print("   Convenience task executed with outputs: \(convenienceOutputs)")
        
        // Auto-named task
        print("\nAuto-named Task Creation:")
        let autoNamedTask = AuroraCore.task(
            description: "An auto-named task",
            inputs: ["input": "test"]
        ) { inputs in
            let input = inputs["input"] as? String ?? "default"
            return ["processed": input.uppercased()]
        }
        
        let autoNamedOutputs = try! await autoNamedTask.execute()
        print("   Auto-named task '\(autoNamedTask.name)' executed with outputs: \(autoNamedOutputs)")
        
        print()
    }
    
    // MARK: - Common Patterns Examples
    
    private func demonstrateCommonPatterns() async {
        print("3. Common Workflow Patterns")
        print("---------------------------")
        
        // Sequential workflow
        print("Sequential Workflow:")
        var sequentialWorkflow = AuroraCore.workflow(
            "Sequential Example",
            description: "A workflow that executes tasks sequentially"
        ) {
            AuroraCore.task("Task1") { _ in
                print("   Executing Task 1")
                return ["step": 1]
            }
            
            AuroraCore.task("Task2") { inputs in
                print("   Executing Task 2 (received step: \(inputs["Task1.step"] ?? "none"))")
                return ["step": 2]
            }
            
            AuroraCore.task("Task3") { inputs in
                print("   Executing Task 3 (received step: \(inputs["Task2.step"] ?? "none"))")
                return ["step": 3]
            }
        }
        
        await sequentialWorkflow.start()
        print("   Sequential workflow completed with outputs: \(sequentialWorkflow.outputs)")
        
        // Parallel workflow
        print("\nParallel Workflow:")
        var parallelWorkflow = AuroraCore.workflow(
            "Parallel Example",
            description: "A workflow that executes tasks in parallel"
        ) {
            Workflow.TaskGroup(name: "ParallelTasks", mode: .parallel) {
                AuroraCore.task("ParallelTask1") { _ in
                    print("   Executing Parallel Task 1")
                    try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                    return ["parallel": 1]
                }
                
                AuroraCore.task("ParallelTask2") { _ in
                    print("   Executing Parallel Task 2")
                    try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                    return ["parallel": 2]
                }
                
                AuroraCore.task("ParallelTask3") { _ in
                    print("   Executing Parallel Task 3")
                    try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                    return ["parallel": 3]
                }
            }
        }
        
        await parallelWorkflow.start()
        print("   Parallel workflow completed with outputs: \(parallelWorkflow.outputs)")
        
        print()
    }
    
    // MARK: - Utility Functions Examples
    
    private func demonstrateUtilityFunctions() async {
        print("4. Utility Functions")
        print("--------------------")
        
        // Delay task
        print("Delay Task:")
        let delayTask = AuroraCore.delay(0.5, name: "HalfSecondDelay")
        let delayOutputs = try! await delayTask.execute()
        print("   Delay task completed with outputs: \(delayOutputs)")
        
        // Print task
        print("\nPrint Task:")
        let printTask = AuroraCore.print("Hello from AuroraCore convenience APIs!", name: "Greeting")
        let printOutputs = try! await printTask.execute()
        print("   Print task completed with outputs: \(printOutputs)")
        
        // Conditional task
        print("\nConditional Task:")
        let trueTask = AuroraCore.task("TrueTask") { _ in
            return ["condition": "true"]
        }
        
        let falseTask = AuroraCore.task("FalseTask") { _ in
            return ["condition": "false"]
        }
        
        let conditionalLogic = AuroraCore.conditional(
            "ConditionalExample",
            condition: { true }, // Always true for this example
            trueTask: trueTask,
            falseTask: falseTask
        )
        
        var conditionalWorkflow = AuroraCore.workflow("Conditional Workflow") {
            conditionalLogic
        }
        
        await conditionalWorkflow.start()
        print("   Conditional workflow completed with outputs: \(conditionalWorkflow.outputs)")
        
        print()
    }
    
    // MARK: - Workflow Extensions Examples
    
    private func demonstrateWorkflowExtensions() async {
        print("5. Workflow Extensions")
        print("----------------------")
        
        // Run and get outputs
        print("Run and Get Outputs:")
        var runWorkflow = AuroraCore.workflow("Run Example") {
            AuroraCore.task("DataTask") { _ in
                return ["data": "processed", "count": 42]
            }
        }
        
        let outputs = try! await runWorkflow.run()
        print("   Workflow run completed with outputs: \(outputs)")
        
        // Run and get specific output
        print("\nRun and Get Specific Output:")
        var specificOutputWorkflow = AuroraCore.workflow("Specific Output Example") {
            AuroraCore.task("SpecificTask") { _ in
                return ["message": "Hello World", "number": 123]
            }
        }
        
        let message: String? = try! await specificOutputWorkflow.run(output: "SpecificTask.message")
        let number: Int? = try! await specificOutputWorkflow.run(output: "SpecificTask.number")
        
        print("   Retrieved message: \(message ?? "nil")")
        print("   Retrieved number: \(number ?? 0)")
        
        print()
    }
}
