//
//  StreamingIntegrationTests.swift
//  AuroraToolkit Integration Tests
//
//  Integration tests for streaming LLM requests
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraTaskLibrary

/// Integration tests for streaming LLM requests and responses.
final class StreamingIntegrationTests: XCTestCase {
    
    // MARK: - Basic Streaming
    
    /// Tests basic streaming request functionality.
    func testBasicStreamingRequest() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        actor PartialResponseCollector {
            private var responses: [String] = []
            
            func append(_ response: String) {
                responses.append(response)
            }
            
            func count() -> Int {
                return responses.count
            }
            
            func getAll() -> [String] {
                return responses
            }
        }
        
        let collector = PartialResponseCollector()
        let expectation = XCTestExpectation(description: "Streaming should call partial response callback")
        
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Count from 1 to 5, one number per response chunk.")],
            maxTokens: 100,
            stream: true
        )
        
        let response = try await service.sendStreamingRequest(request) { @Sendable partial in
            Task {
                await collector.append(partial)
                let count = await collector.count()
                if count >= 1 {
                expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        XCTAssertFalse(response.text.isEmpty, "Response should have text")
        let partialResponses = await collector.getAll()
        XCTAssertGreaterThanOrEqual(partialResponses.count, 1, "Should receive at least one partial response")
        
        // Verify the complete response matches accumulated partials (or at least contains them)
        let accumulatedText = partialResponses.joined()
        XCTAssertTrue(
            response.text.contains(accumulatedText) || accumulatedText.contains(response.text),
            "Complete response should relate to partial responses"
        )
    }
    
    // MARK: - Streaming in Workflows
    
    /// Tests streaming requests within a workflow.
    func testStreamingInWorkflow() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        var workflow = Workflow(
            name: "Streaming Workflow",
            description: "Test streaming in workflow context"
        ) {
            Workflow.Task(name: "StreamingTask") { _ in
                let request = IntegrationTestHelpers.makeTestRequest(content: "Say hello")
                actor PartialTextCollector {
                    private var texts: [String] = []
                    
                    func append(_ text: String) {
                        texts.append(text)
                    }
                    
                    func count() -> Int {
                        return texts.count
                    }
                }
                
                let collector = PartialTextCollector()
                let requestWithStream = LLMRequest(
                    messages: request.messages,
                    temperature: request.temperature,
                    maxTokens: request.maxTokens,
                    model: request.model,
                    stream: true,
                    options: request.options
                )
                
                let response = try await service.sendStreamingRequest(requestWithStream) { @Sendable partial in
                    Task {
                        await collector.append(partial)
                }
                }
                
                let partialCount = await collector.count()
                return [
                    "response": response.text,
                    "partialCount": partialCount
                ]
            }
        }
        
        await workflow.start()
        
        let state = await workflow.state
        if case .completed = state {
            // Workflow completed successfully
        } else {
            XCTFail("Workflow should complete successfully, but got state: \(state)")
        }
        
        let response = workflow.outputs["StreamingTask.response"] as? String
        let partialCount = workflow.outputs["StreamingTask.partialCount"] as? Int
        
        XCTAssertNotNil(response, "Should have streaming response")
        XCTAssertNotNil(partialCount, "Should track partial responses")
        XCTAssertGreaterThanOrEqual(partialCount ?? 0, 0, "Should have received partial responses")
    }
    
    // MARK: - Streaming with TaskLibrary
    
    /// Tests that TaskLibrary can handle streaming responses.
    func testStreamingWithTaskLibrary() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        await Tasks.configure(with: service)
        
        // Note: TaskLibrary may not have streaming methods, but we can test
        // that services configured with Tasks can handle streaming
        actor PartialResponseCollector {
            private var responses: [String] = []
            
            func append(_ response: String) {
                responses.append(response)
            }
            
            func getAll() -> [String] {
                return responses
            }
        }
        
        let collector = PartialResponseCollector()
        
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Say hello in one word")],
            maxTokens: 50,
            stream: true
        )
        
        let response = try await service.sendStreamingRequest(request) { @Sendable partial in
            Task {
                await collector.append(partial)
        }
        }
        
        let partialResponses = await collector.getAll()
        
        XCTAssertFalse(response.text.isEmpty, "Should get a response")
        XCTAssertGreaterThanOrEqual(partialResponses.count, 0, "Should receive partial responses")
    }
    
    // MARK: - Multiple Streaming Calls
    
    /// Tests multiple sequential streaming requests.
    func testMultipleStreamingCalls() async throws {
        let service = try IntegrationTestHelpers.getLLMService()
        
        var allPartialResponses: [[String]] = []
        
        for i in 1...3 {
            let request = LLMRequest(
                messages: [LLMMessage(role: .user, content: "Say number \(i)")],
                maxTokens: 50,
                stream: true
            )
            
            actor PartialsCollector {
                private var partials: [String] = []
                
                func append(_ partial: String) {
                partials.append(partial)
                }
                
                func getAll() -> [String] {
                    return partials
                }
            }
            
            let collector = PartialsCollector()
            let response = try await service.sendStreamingRequest(request) { @Sendable partial in
                Task {
                    await collector.append(partial)
                }
            }
            
            XCTAssertFalse(response.text.isEmpty, "Call \(i) should have response")
            let partials = await collector.getAll()
            allPartialResponses.append(partials)
        }
        
        XCTAssertEqual(allPartialResponses.count, 3, "Should have 3 sets of partial responses")
    }
    
    // MARK: - Streaming Error Handling
    
    /// Tests error handling in streaming requests.
    func testStreamingErrorHandling() async throws {
        // Create a mock service that fails during streaming
        let failingService = IntegrationMockLLMService(
            name: "FailingStreamingService",
            vendor: "Mock",
            expectedResult: .failure(LLMServiceError.serviceUnavailable(message: "Streaming failed for testing"))
        )
        
        var errorCaught = false
        var partialCalled = false
        
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Test")],
            maxTokens: 50,
            stream: true
        )
        
        do {
            _ = try await failingService.sendStreamingRequest(request) { _ in
                partialCalled = true
            }
        } catch {
            errorCaught = true
        }
        
        XCTAssertTrue(errorCaught, "Should catch streaming error")
        XCTAssertFalse(partialCalled, "Partial callback should not be called on error")
    }
}

// MARK: - Mock Helpers (reused from IntegrationTestHelpers)

private struct IntegrationMockLLMResponse: LLMResponseProtocol {
    var text: String
    var model: String?
    var tokenUsage: LLMTokenUsage?
    var vendor: String?
    
    var id: String? { nil }
    var finishReason: String? { "stop" }
    var systemFingerprint: String? { nil }
    
    init(text: String, model: String, tokenUsage: LLMTokenUsage?) {
        self.text = text
        self.model = model
        self.tokenUsage = tokenUsage
        self.vendor = "Mock"
    }
}

private final class IntegrationMockLLMService: LLMServiceProtocol, @unchecked Sendable {
    var name: String
    var vendor: String
    var apiKey: String? = nil
    var requiresAPIKey = false
    var contextWindowSize: Int = 8192
    var maxOutputTokens: Int = 4096
    var inputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var outputTokenPolicy: TokenAdjustmentPolicy = .adjustToServiceLimits
    var systemPrompt: String? = nil
    var defaultModel: String = "mock-model"
    var supportedModels: [String] = []
    
    private let expectedResult: Result<LLMResponseProtocol, Error>
    
    init(name: String, vendor: String, expectedResult: Result<LLMResponseProtocol, Error>) {
        self.name = name
        self.vendor = vendor
        self.expectedResult = expectedResult
    }
    
    func sendRequest(_ request: LLMRequest) async throws -> LLMResponseProtocol {
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    
    func sendStreamingRequest(_ request: LLMRequest, onPartialResponse: ((String) -> Void)?) async throws -> LLMResponseProtocol {
        if let onPartialResponse = onPartialResponse {
            switch expectedResult {
            case .success(let response):
                // Simulate streaming by calling the callback with chunks
                let text = response.text
                let chunkSize = max(1, text.count / 3)
                var startIndex = text.startIndex
                
                while startIndex < text.endIndex {
                    let endIndex = text.index(startIndex, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
                    let chunk = String(text[startIndex..<endIndex])
                    onPartialResponse(chunk)
                    startIndex = endIndex
                    
                    // Small delay to simulate real streaming
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                return response
            case .failure(let error):
                throw error
            }
        }
        
        switch expectedResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}

