//
//  AuroraCoreConvenienceTests.swift
//  AuroraCoreTests
//
//  Created on 1/15/25.
//

import XCTest
@testable import AuroraCore

/// Unit tests for AuroraCore convenience APIs.
///
/// These tests verify that the convenience APIs work correctly and provide
/// the expected simplified interface while maintaining compatibility with
/// the underlying AuroraCore workflow system.
final class AuroraCoreConvenienceTests: XCTestCase {
    
    // MARK: - Workflow Convenience Tests
    
    func testWorkflowConvenienceCreation() async {
        // Test basic workflow creation
        let workflow = AuroraCore.workflow(
            "Test Workflow",
            description: "A test workflow"
        ) {
            AuroraCore.task("Test Task") { _ in
                return ["result": "success"]
            }
        }
        
        XCTAssertEqual(workflow.name, "Test Workflow")
        XCTAssertEqual(workflow.description, "A test workflow")
        XCTAssertNotNil(workflow.componentsManager)
    }
    
    func testWorkflowAutoNaming() async {
        // Test auto-named workflow creation
        let workflow = AuroraCore.workflow(description: "An auto-named workflow") {
            AuroraCore.task("Test Task") { _ in
                return ["result": "success"]
            }
        }
        
        XCTAssertTrue(workflow.name.hasPrefix("Workflow_"))
        XCTAssertEqual(workflow.description, "An auto-named workflow")
    }
    
    func testWorkflowExecution() async {
        // Test workflow execution
        var workflow = AuroraCore.workflow("Execution Test") {
            AuroraCore.task("Execution Task") { _ in
                return ["executed": true]
            }
        }
        
        await workflow.start()
        XCTAssertEqual(workflow.outputs["Execution Task.executed"] as? Bool, true)
    }
    
    // MARK: - Task Convenience Tests
    
    func testTaskConvenienceCreation() async {
        // Test basic task creation
        let task = AuroraCore.task(
            "Test Task",
            description: "A test task",
            inputs: ["input": "test"]
        ) { inputs in
            let input = inputs["input"] as? String ?? "default"
            return ["processed": input.uppercased()]
        }
        
        XCTAssertEqual(task.name, "Test Task")
        XCTAssertEqual(task.description, "A test task")
        XCTAssertEqual(task.inputs["input"] as? String, "test")
    }
    
    func testTaskAutoNaming() async {
        // Test auto-named task creation
        let task = AuroraCore.task(description: "An auto-named task") { _ in
            return ["result": "success"]
        }
        
        XCTAssertTrue(task.name.hasPrefix("Task_"))
        XCTAssertEqual(task.description, "An auto-named task")
    }
    
    func testTaskExecution() async throws {
        // Test task execution
        let task = AuroraCore.task("Execution Test") { _ in
            return ["executed": true, "timestamp": Date().timeIntervalSince1970]
        }
        
        let outputs = try await task.execute()
        XCTAssertEqual(outputs["executed"] as? Bool, true)
        XCTAssertNotNil(outputs["timestamp"] as? TimeInterval)
    }
    
    // MARK: - Common Patterns Tests
    
    func testSequentialWorkflow() async {
        // Test sequential workflow creation
        let workflow = AuroraCore.workflow(
            "Sequential Test",
            description: "A sequential workflow test"
        ) {
            AuroraCore.task("Task1") { _ in
                return ["step": 1]
            }
            
            AuroraCore.task("Task2") { inputs in
                let step = inputs["Task1.step"] as? Int ?? 0
                return ["step": step + 1]
            }
        }
        
        XCTAssertEqual(workflow.name, "Sequential Test")
        XCTAssertNotNil(workflow.componentsManager)
    }
    
    func testParallelWorkflow() async {
        // Test parallel workflow creation
        let workflow = AuroraCore.workflow(
            "Parallel Test",
            description: "A parallel workflow test"
        ) {
            Workflow.TaskGroup(name: "ParallelTasks", mode: .parallel) {
                AuroraCore.task("ParallelTask1") { _ in
                    return ["parallel": 1]
                }
                
                AuroraCore.task("ParallelTask2") { _ in
                    return ["parallel": 2]
                }
            }
        }
        
        XCTAssertEqual(workflow.name, "Parallel Test")
        XCTAssertNotNil(workflow.componentsManager)
    }
    
    // MARK: - Utility Functions Tests
    
    func testDelayTask() async throws {
        // Test delay task creation and execution
        let delayTask = AuroraCore.delay(0.1, name: "TestDelay")
        
        XCTAssertEqual(delayTask.name, "TestDelay")
        
        let startTime = Date()
        let outputs = try await delayTask.execute()
        let endTime = Date()
        
        XCTAssertEqual(outputs["delay_completed"] as? Bool, true)
        XCTAssertEqual(outputs["duration"] as? TimeInterval, 0.1)
        
        // Verify the delay actually occurred (within reasonable tolerance)
        let actualDelay = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThan(actualDelay, 0.05) // At least 50ms
        XCTAssertLessThan(actualDelay, 0.2) // But not more than 200ms
    }
    
    func testPrintTask() async throws {
        // Test print task creation and execution
        let printTask = AuroraCore.print("Test Message", name: "TestPrint")
        
        XCTAssertEqual(printTask.name, "TestPrint")
        
        let outputs = try await printTask.execute()
        XCTAssertEqual(outputs["message_printed"] as? String, "Test Message")
    }
    
    func testConditionalTask() async {
        // Test conditional task creation
        let trueTask = AuroraCore.task("TrueTask") { _ in
            return ["condition": "true"]
        }
        
        let falseTask = AuroraCore.task("FalseTask") { _ in
            return ["condition": "false"]
        }
        
        let conditional = AuroraCore.conditional(
            "TestConditional",
            condition: { true },
            trueTask: trueTask,
            falseTask: falseTask
        )
        
        XCTAssertEqual(conditional.name, "TestConditional")
    }
    
    // MARK: - Workflow Extensions Tests
    
    func testWorkflowRun() async throws {
        // Test workflow run extension
        var workflow = AuroraCore.workflow("Run Test") {
            AuroraCore.task("RunTask") { _ in
                return ["data": "processed", "count": 42]
            }
        }
        
        let outputs = try await workflow.run()
        XCTAssertEqual(outputs["RunTask.data"] as? String, "processed")
        XCTAssertEqual(outputs["RunTask.count"] as? Int, 42)
    }
    
    func testWorkflowRunSpecificOutput() async throws {
        // Test workflow run with specific output
        var workflow = AuroraCore.workflow("Specific Output Test") {
            AuroraCore.task("SpecificTask") { _ in
                return ["message": "Hello World", "number": 123]
            }
        }
        
        let message: String? = try await workflow.run(output: "SpecificTask.message")
        let number: Int? = try await workflow.run(output: "SpecificTask.number")
        
        XCTAssertEqual(message, "Hello World")
        XCTAssertEqual(number, 123)
    }
    
    func testWorkflowRunSpecificOutputNotFound() async throws {
        // Test workflow run with non-existent output
        var workflow = AuroraCore.workflow("Non-existent Output Test") {
            AuroraCore.task("TestTask") { _ in
                return ["data": "test"]
            }
        }
        
        let result: String? = try await workflow.run(output: "NonExistentKey")
        XCTAssertNil(result)
    }
    
    // MARK: - Integration Tests
    
    func testComplexWorkflow() async throws {
        // Test a more complex workflow using multiple convenience APIs
        var workflow = AuroraCore.workflow("Complex Test") {
            // Initial task
            AuroraCore.task("InitialTask") { _ in
                return ["initialized": true]
            }
            
            // Delay task
            AuroraCore.delay(0.05, name: "ShortDelay")
            
            // Print task
            AuroraCore.print("Complex workflow executing", name: "StatusPrint")
            
            // Final task
            AuroraCore.task("FinalTask") { inputs in
                let initialized = inputs["InitialTask.initialized"] as? Bool ?? false
                return ["completed": initialized, "final_step": true]
            }
        }
        
        let outputs = try await workflow.run()
        
        XCTAssertEqual(outputs["InitialTask.initialized"] as? Bool, true)
        XCTAssertEqual(outputs["ShortDelay.delay_completed"] as? Bool, true)
        XCTAssertEqual(outputs["StatusPrint.message_printed"] as? String, "Complex workflow executing")
        XCTAssertEqual(outputs["FinalTask.completed"] as? Bool, true)
        XCTAssertEqual(outputs["FinalTask.final_step"] as? Bool, true)
    }
}
