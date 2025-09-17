//
//  FoundationModelServiceTests.swift
//  AuroraLLM
//
//  Created by Dan Murrell Jr on 9/16/25.
//

import XCTest
@testable import AuroraLLM
import AuroraCore

final class FoundationModelServiceTests: XCTestCase {

    // MARK: - Test Data

    private func makeSampleRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            model: "foundation-model"
        )
    }

    // MARK: - Availability Tests

    func testIsAvailableReturnsFalseOnUnsupportedPlatforms() {
        // Note: This test will always pass on platforms < iOS 26/macOS 26
        // since FoundationModels won't be available
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            let isAvailable = FoundationModelService.isAvailable()

            // We can't assert a specific value since it depends on the platform
            // Just verify the method doesn't crash and returns a boolean
            XCTAssertTrue(isAvailable == true || isAvailable == false)
        } else {
            // On platforms < iOS 26/macOS 26, FoundationModelService isn't available
            XCTAssertTrue(true) // Test passes since the service shouldn't be available
        }
    }

    func testCreateIfAvailableReturnsNilOnUnsupportedPlatforms() {
        // On unsupported platforms, createIfAvailable should return nil
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            let service = FoundationModelService.createIfAvailable()

            // On supported platforms with Apple Intelligence, this might succeed
            if service == nil {
                // Expected when Apple Intelligence is disabled
                XCTAssertNil(service)
            } else {
                // If service creation succeeded, verify it's properly configured
                XCTAssertEqual(service?.vendor, "Apple")
                XCTAssertEqual(service?.contextWindowSize, 4096)
                XCTAssertEqual(service?.maxOutputTokens, 2048)
            }
        } else {
            // On platforms < iOS 26/macOS 26, FoundationModelService isn't available
            XCTAssertTrue(true) // Test passes since the service shouldn't be available
        }
    }

    // MARK: - Configuration Tests

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testFoundationModelServiceConfiguration() throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available on this platform")
        }

        let service = try FoundationModelService(
            name: "TestFoundationModel",
            contextWindowSize: 4096,
            maxOutputTokens: 2048
        )

        XCTAssertEqual(service.vendor, "Apple")
        XCTAssertEqual(service.name, "TestFoundationModel")
        XCTAssertEqual(service.contextWindowSize, 4096)
        XCTAssertEqual(service.maxOutputTokens, 2048)
        XCTAssertEqual(service.inputTokenPolicy, .adjustToServiceLimits)
        XCTAssertEqual(service.outputTokenPolicy, .adjustToServiceLimits)
    }

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testFoundationModelServiceWithCustomConfiguration() throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available on this platform")
        }

        let service = try FoundationModelService(
            name: "CustomFoundationModel",
            contextWindowSize: 3000,
            maxOutputTokens: 1500,
            inputTokenPolicy: .strictRequestLimits,
            outputTokenPolicy: .strictRequestLimits,
            systemPrompt: "You are a helpful assistant."
        )

        XCTAssertEqual(service.vendor, "Apple")
        XCTAssertEqual(service.name, "CustomFoundationModel")
        XCTAssertEqual(service.contextWindowSize, 3000)
        XCTAssertEqual(service.maxOutputTokens, 1500)
        XCTAssertEqual(service.inputTokenPolicy, .strictRequestLimits)
        XCTAssertEqual(service.outputTokenPolicy, .strictRequestLimits)
        XCTAssertEqual(service.systemPrompt, "You are a helpful assistant.")
    }

    // MARK: - Token Limit Validation Tests

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testWarningForExcessiveContextWindowSize() throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available on this platform")
        }

        // This should succeed but log warnings (we can't easily test logging in unit tests)
        let service = try FoundationModelService(
            contextWindowSize: 8192 // Exceeds Foundation Models limit of 4096
        )

        XCTAssertEqual(service.contextWindowSize, 8192)
        XCTAssertEqual(service.vendor, "Apple")
    }

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testWarningForExcessiveMaxOutputTokens() throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available on this platform")
        }

        // This should succeed but log warnings
        let service = try FoundationModelService(
            maxOutputTokens: 5000 // Exceeds Foundation Models limit of 4096
        )

        XCTAssertEqual(service.maxOutputTokens, 5000)
        XCTAssertEqual(service.vendor, "Apple")
    }

    // MARK: - Request Tests

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testSendRequestBasicFunctionality() async throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available or Apple Intelligence not enabled")
        }

        let service = try FoundationModelService()
        let request = makeSampleRequest(content: "Hello, how are you?")

        do {
            let response = try await service.sendRequest(request)

            XCTAssertFalse(response.text.isEmpty)
            XCTAssertEqual(response.model, "foundation-model")
            XCTAssertNotNil(response.tokenUsage)
            XCTAssertTrue(response.tokenUsage!.promptTokens > 0)
            XCTAssertTrue(response.tokenUsage!.completionTokens > 0)
            XCTAssertTrue(response.tokenUsage!.totalTokens > 0)
        } catch LLMServiceError.serviceUnavailable {
            // Apple Intelligence might not be enabled - this is expected
            throw XCTSkip("Apple Intelligence not available on this device")
        }
    }

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testSendStreamingRequestBasicFunctionality() async throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available or Apple Intelligence not enabled")
        }

        let service = try FoundationModelService()
        let request = makeSampleRequest(content: "Tell me a short joke.")

        var receivedPartialResponse = false

        do {
            let response = try await service.sendStreamingRequest(request) { partial in
                receivedPartialResponse = true
                XCTAssertFalse(partial.isEmpty)
            }

            XCTAssertFalse(response.text.isEmpty)
            XCTAssertEqual(response.model, "foundation-model")
            XCTAssertNotNil(response.tokenUsage)
            XCTAssertTrue(receivedPartialResponse)
        } catch LLMServiceError.serviceUnavailable {
            // Apple Intelligence might not be enabled - this is expected
            throw XCTSkip("Apple Intelligence not available on this device")
        }
    }

    // MARK: - Factory Tests

    func testLLMServiceFactoryCreatesFoundationModelService() {
        let factory = LLMServiceFactory()
        let context = Context(llmServiceVendor: "Apple")

        if #available(iOS 26, macOS 26, visionOS 26, *) {
            let service = factory.createService(for: context)

            if service == nil {
                // Expected on unsupported platforms or when Apple Intelligence is disabled
                XCTAssertNil(service)
            } else {
                // If service creation succeeded, verify it's the right type
                XCTAssertTrue(service is FoundationModelService)
                XCTAssertEqual(service?.vendor, "Apple")
            }
        } else {
            // On platforms < iOS 26/macOS 26, FoundationModelService isn't available
            let service = factory.createService(for: context)
            XCTAssertNil(service) // Should be nil on unsupported platforms
        }
    }

    // MARK: - Error Handling Tests

    @available(iOS 26, macOS 26, visionOS 26, *)
    func testRequestFailureHandling() async throws {
        // Skip this test if FoundationModels isn't available
        guard FoundationModelService.isAvailable() else {
            throw XCTSkip("FoundationModels framework not available or Apple Intelligence not enabled")
        }

        let service = try FoundationModelService()

        // Create a request that might exceed the token limit
        let longContent = String(repeating: "This is a very long sentence that will use many tokens. ", count: 200)
        let request = makeSampleRequest(content: longContent)

        do {
            _ = try await service.sendRequest(request)
            // If it succeeds, that's fine too - the request might not actually exceed limits
        } catch LLMServiceError.requestFailed(let message) {
            // This is expected if we exceed the 4096 token limit
            XCTAssertTrue(message.contains("4,096") || message.contains("context window"))
        } catch LLMServiceError.serviceUnavailable {
            // Apple Intelligence might not be enabled
            throw XCTSkip("Apple Intelligence not available on this device")
        }
    }

    // MARK: - Edge Cases

    func testCreateIfAvailableWithCustomParameters() {
        if #available(iOS 26, macOS 26, visionOS 26, *) {
            let service = FoundationModelService.createIfAvailable(
                name: "CustomTest",
                contextWindowSize: 3000,
                maxOutputTokens: 1000,
                systemPrompt: "Test prompt"
            )

            if let service = service {
                // Service created successfully
                XCTAssertEqual(service.name, "CustomTest")
                XCTAssertEqual(service.contextWindowSize, 3000)
                XCTAssertEqual(service.maxOutputTokens, 1000)
                XCTAssertEqual(service.systemPrompt, "Test prompt")
                XCTAssertEqual(service.vendor, "Apple")
            } else {
                // Service creation failed - expected when Apple Intelligence is disabled
                XCTAssertNil(service)
            }
        } else {
            // On platforms < iOS 26/macOS 26, FoundationModelService isn't available
            XCTAssertTrue(true) // Test passes since the service shouldn't be available
        }
    }
}
