//
//  CoreMLDomainRouterTests.swift
//  AuroraLLM
//
//  Created on 2025-11-05.
//

import XCTest
@testable import AuroraLLM
import AuroraCore
import CoreML
import NaturalLanguage

final class CoreMLDomainRouterTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeSampleRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            model: "test-model"
        )
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationFailsWithInvalidModelURL() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/model.mlmodelc")
        let router = CoreMLDomainRouter(
            name: "TestRouter",
            modelURL: invalidURL,
            supportedDomains: ["sports", "finance"],
            logger: nil
        )
        
        XCTAssertNil(router, "Should return nil when model file doesn't exist")
    }
    
    func testInitializationWithFallbackDomain() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/model.mlmodelc")
        let router = CoreMLDomainRouter(
            name: "TestRouter",
            modelURL: invalidURL,
            supportedDomains: ["sports", "finance"],
            fallbackDomain: "general",
            logger: nil
        )
        
        XCTAssertNil(router, "Should return nil when model file doesn't exist")
    }
    
    // Note: CoreMLDomainRouter requires actual .mlmodelc files to test fully
    // These tests focus on initialization and edge cases that don't require models
    // For full integration testing with models, see DomainRoutingIntegrationTests
    
    // MARK: - Additional Tests
    
    // Note: Full domain determination tests require actual CoreML models
    // See DomainRoutingIntegrationTests for integration tests with real models
    // These unit tests focus on initialization and configuration validation
}

