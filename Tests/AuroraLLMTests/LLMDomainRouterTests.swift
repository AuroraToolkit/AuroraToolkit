//
//  LLMDomainRouterTests.swift
//  AuroraLLM
//
//  Created on 2025-11-05.
//

import XCTest
@testable import AuroraLLM
import AuroraCore

final class LLMDomainRouterTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeSampleRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            model: "test-model"
        )
    }
    
    private func makeMockService(returningDomain: String) -> MockLLMService {
        let mockResponse = MockLLMResponse(text: returningDomain)
        return MockLLMService(
            name: "MockService",
            expectedResult: .success(mockResponse)
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let service = makeMockService(returningDomain: "sports")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance", "technology"],
            logger: nil
        )
        
        XCTAssertEqual(router.name, "TestRouter")
        XCTAssertEqual(router.supportedDomains, ["sports", "finance", "technology"])
        XCTAssertNil(router.fallbackDomain)
    }
    
    func testInitializationWithFallbackDomain() {
        let service = makeMockService(returningDomain: "sports")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            logger: nil
        )
        
        XCTAssertEqual(router.fallbackDomain, "general")
    }
    
    func testInitializationNormalizesSupportedDomains() {
        let service = makeMockService(returningDomain: "sports")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["SPORTS", "Finance", "TECHNOLOGY"],
            logger: nil
        )
        
        XCTAssertEqual(router.supportedDomains, ["sports", "finance", "technology"])
    }
    
    func testInitializationNormalizesFallbackDomain() {
        let service = makeMockService(returningDomain: "sports")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "GENERAL",
            logger: nil
        )
        
        XCTAssertEqual(router.fallbackDomain, "general")
    }
    
    // MARK: - Domain Determination Tests
    
    func testDetermineDomainReturnsValidDomain() async throws {
        let service = makeMockService(returningDomain: "sports")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance", "technology"],
            logger: nil
        )
        
        let request = makeSampleRequest(content: "What's the latest NBA score?")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    func testDetermineDomainReturnsLowercasedDomain() async throws {
        let service = makeMockService(returningDomain: "SPORTS")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    func testDetermineDomainTrimsWhitespace() async throws {
        let service = makeMockService(returningDomain: "  sports  \n")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    func testDetermineDomainReturnsFallbackWhenInvalid() async throws {
        let service = makeMockService(returningDomain: "invalid")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    func testDetermineDomainReturnsNilWhenInvalidAndNoFallback() async throws {
        let service = makeMockService(returningDomain: "invalid")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: nil,
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertNil(domain)
    }
    
    func testDetermineDomainPropagatesServiceError() async throws {
        let errorService = MockLLMService(
            name: "ErrorService",
            expectedResult: .failure(NSError(domain: "TestError", code: 1))
        )
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: errorService,
            supportedDomains: ["sports"],
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        
        do {
            _ = try await router.determineDomain(for: request)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Fallback Domain Tests
    
    func testFallbackDomainNotInSupportedDomains() async throws {
        // This is valid - fallback is independent
        let service = makeMockService(returningDomain: "invalid")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general", // Not in supportedDomains, but that's OK
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    func testFallbackDomainInSupportedDomains() async throws {
        // This will log a warning but still works
        let service = makeMockService(returningDomain: "invalid")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance", "general"],
            fallbackDomain: "general", // In supportedDomains - may indicate config issue
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    func testNilFallbackDomain() async throws {
        let service = makeMockService(returningDomain: "invalid")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: nil,
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertNil(domain)
    }
    
    // MARK: - System Prompt Tests
    
    func testSystemPromptConfigured() {
        let service = makeMockService(returningDomain: "sports")
        _ = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            logger: nil
        )
        
        XCTAssertNotNil(service.systemPrompt)
        XCTAssertTrue(service.systemPrompt?.contains("sports") ?? false)
        XCTAssertTrue(service.systemPrompt?.contains("finance") ?? false)
    }
    
    func testCustomInstructions() {
        let service = makeMockService(returningDomain: "sports")
        let customInstructions = "Custom instructions: %@"
        _ = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: nil,
            instructions: customInstructions,
            logger: nil
        )
        
        XCTAssertNotNil(service.systemPrompt)
        XCTAssertTrue(service.systemPrompt?.contains("Custom instructions") ?? false)
    }
    
    // MARK: - Edge Cases
    
    func testEmptySupportedDomains() async throws {
        let service = makeMockService(returningDomain: "anything")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: [],
            fallbackDomain: "general",
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        // Should return fallback since nothing is in supportedDomains
        XCTAssertEqual(domain, "general")
    }
    
    func testEmptyResponseFromLLM() async throws {
        let service = makeMockService(returningDomain: "")
        let router = LLMDomainRouter(
            name: "TestRouter",
            service: service,
            supportedDomains: ["sports"],
            fallbackDomain: "general",
            logger: nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        // Empty response should trigger fallback
        XCTAssertEqual(domain, "general")
    }
}

