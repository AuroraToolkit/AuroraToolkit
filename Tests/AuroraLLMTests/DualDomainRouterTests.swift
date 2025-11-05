//
//  DualDomainRouterTests.swift
//  AuroraLLM
//
//  Created on 2025-11-05.
//

import XCTest
@testable import AuroraLLM
import AuroraCore

final class DualDomainRouterTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeSampleRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            model: "test-model"
        )
    }
    
    private func makeMockRouter(name: String, domain: String?) -> MockLLMDomainRouter {
        let mockService = MockLLMService(
            name: "MockService",
            expectedResult: .success(MockLLMResponse(text: "response"))
        )
        return MockLLMDomainRouter(
            name: name,
            service: mockService,
            supportedDomains: ["sports", "finance", "technology"],
            expectedDomain: domain
        )
    }
    
    private func makeConfidentMockRouter(name: String, domain: String?, confidence: Double) -> MockConfidentDomainRouter {
        return MockConfidentDomainRouter(
            name: name,
            supportedDomains: ["sports", "finance", "technology"],
            expectedDomain: domain,
            expectedConfidence: confidence
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        let primary = makeMockRouter(name: "Primary", domain: "sports")
        let secondary = makeMockRouter(name: "Secondary", domain: "finance")
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance", "technology"],
            resolveConflict: { p, s in p?.label ?? s?.label }
        )
        
        XCTAssertEqual(router.name, "DualRouter")
        XCTAssertEqual(router.supportedDomains, ["sports", "finance", "technology"])
    }
    
    func testInitializationWithFallbackDomain() {
        let primary = makeMockRouter(name: "Primary", domain: nil)
        let secondary = makeMockRouter(name: "Secondary", domain: nil)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            resolveConflict: { _, _ in nil }
        )
        
        XCTAssertEqual(router.fallbackDomain, "general")
    }
    
    func testInitializationNormalizesDomains() {
        let primary = makeMockRouter(name: "Primary", domain: "sports")
        let secondary = makeMockRouter(name: "Secondary", domain: "finance")
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["SPORTS", "Finance", "TECHNOLOGY"],
            resolveConflict: { p, s in p?.label ?? s?.label }
        )
        
        XCTAssertEqual(router.supportedDomains, ["sports", "finance", "technology"])
    }
    
    // MARK: - Both Predictions Available Tests
    
    func testBothPredictionsMatch() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.9)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "sports", confidence: 0.8)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    func testBothPredictionsDiffer() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.9)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.8)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            resolveConflict: { p, _ in p?.label } // Prefer primary
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    // MARK: - Single Prediction Tests
    
    func testOnlyPrimaryPrediction() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.9)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: nil, confidence: 0.0)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    func testOnlySecondaryPrediction() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: nil, confidence: 0.0)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.8)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "finance")
    }
    
    // MARK: - Confidence Threshold Tests
    
    func testConfidenceThresholdFavorsHigherConfidence() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.6)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.9)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            confidenceThreshold: 0.2, // 0.9 - 0.6 = 0.3 > 0.2, so secondary wins
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "finance")
    }
    
    func testConfidenceThresholdBelowThresholdUsesResolver() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.6)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.7)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            confidenceThreshold: 0.2, // 0.7 - 0.6 = 0.1 < 0.2, so use resolver
            resolveConflict: { p, _ in p?.label } // Prefer primary
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "sports")
    }
    
    // MARK: - Fallback Domain Tests
    
    func testFallbackDomainWhenBothNil() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: nil, confidence: 0.0)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: nil, confidence: 0.0)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    func testFallbackDomainWhenBothBelowThreshold() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.3)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.2)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            fallbackConfidenceThreshold: 0.5, // Both below 0.5
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    func testFallbackDomainNotInSupportedDomains() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: nil, confidence: 0.0)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: nil, confidence: 0.0)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general", // Not in supportedDomains, but that's OK
            resolveConflict: { _, _ in nil }
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "general")
    }
    
    // MARK: - Custom Resolver Tests
    
    func testCustomResolverPreference() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.6)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.7)
        
        // Custom resolver: always prefer finance
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            confidenceThreshold: 0.2, // Below threshold, so use resolver
            resolveConflict: { _, s in s?.label } // Prefer secondary
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertEqual(domain, "finance")
    }
    
    func testCustomResolverReturnsNil() async throws {
        let primary = makeConfidentMockRouter(name: "Primary", domain: "sports", confidence: 0.6)
        let secondary = makeConfidentMockRouter(name: "Secondary", domain: "finance", confidence: 0.7)
        
        let router = DualDomainRouter(
            name: "DualRouter",
            primary: primary,
            secondary: secondary,
            supportedDomains: ["sports", "finance"],
            confidenceThreshold: 0.2,
            resolveConflict: { _, _ in nil } // Resolver returns nil
        )
        
        let request = makeSampleRequest(content: "Test")
        let domain = try await router.determineDomain(for: request)
        
        XCTAssertNil(domain)
    }
}

// MARK: - Mock Confident Domain Router

private class MockConfidentDomainRouter: ConfidentDomainRouter {
    let name: String
    let supportedDomains: [String]
    let fallbackDomain: String? = nil
    private let expectedDomain: String?
    private let expectedConfidence: Double
    
    init(name: String, supportedDomains: [String], expectedDomain: String?, expectedConfidence: Double) {
        self.name = name
        self.supportedDomains = supportedDomains
        self.expectedDomain = expectedDomain
        self.expectedConfidence = expectedConfidence
    }
    
    func determineDomain(for request: LLMRequest) async throws -> String? {
        return expectedDomain
    }
    
    func determineDomainWithConfidence(for request: LLMRequest) async throws -> (String, Double)? {
        guard let domain = expectedDomain else { return nil }
        return (domain, expectedConfidence)
    }
}

