//
//  LogicDomainRouterTests.swift
//  AuroraLLM
//
//  Created by Dan Murrell Jr on 9/16/25.
//

import XCTest
@testable import AuroraLLM
import AuroraCore

final class LogicDomainRouterTests: XCTestCase {

    // MARK: - Test Data

    private func makeSampleRequest(content: String) -> LLMRequest {
        return LLMRequest(
            messages: [LLMMessage(role: .user, content: content)],
            model: "test-model"
        )
    }

    private func makeSportsRule() -> LogicRule {
        return .regex(
            name: "Sports",
            pattern: #"\b(basketball|football|soccer|nba|nfl)\b"#,
            domain: "sports",
            priority: 10
        )
    }

    private func makeFinanceRule() -> LogicRule {
        return .regex(
            name: "Finance",
            pattern: #"\b(loan|mortgage|apr|finance)\b"#,
            domain: "finance",
            priority: 5
        )
    }

    private func makePIIRule() -> LogicRule {
        return .regex(
            name: "PII (email)",
            pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            domain: "private",
            priority: 100
        )
    }

    // MARK: - Basic Functionality Tests

    func testFirstMatchStrategy() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let sportsRequest = makeSampleRequest(content: "What's the latest NBA score?")
        let result = try await router.determineDomain(for: sportsRequest)
        XCTAssertEqual(result, "sports")
    }

    func testHighestPriorityStrategy() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "private", "general"],
            rules: [makeSportsRule(), makeFinanceRule(), makePIIRule()],
            defaultDomain: "general",
            evaluationStrategy: .highestPriority
        )

        // This should match both sports (priority 10) and PII (priority 100)
        // PII should win due to higher priority
        let mixedRequest = makeSampleRequest(content: "Send my basketball stats to john@example.com")
        let result = try await router.determineDomain(for: mixedRequest)
        XCTAssertEqual(result, "private")
    }

    func testTopKThenResolve() async throws {
        let resolver: ([LogicRule]) -> String? = { rules in
            // Return the domain of the rule with highest priority
            return rules.max(by: { $0.priority < $1.priority })?.domain
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "private", "general"],
            rules: [makeSportsRule(), makeFinanceRule(), makePIIRule()],
            defaultDomain: "general",
            evaluationStrategy: .topKThenResolve(k: 3, resolver: resolver)
        )

        let mixedRequest = makeSampleRequest(content: "Send my basketball loan info to john@example.com")
        let result = try await router.determineDomain(for: mixedRequest)
        XCTAssertEqual(result, "private")
    }

    func testProbabilisticWeights() async throws {
        let selector: ([LogicRule]) -> [(domain: String, weight: Double)] = { rules in
            return rules.map { (domain: $0.domain, weight: Double($0.priority)) }
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "private", "general"],
            rules: [makeSportsRule(), makeFinanceRule(), makePIIRule()],
            defaultDomain: "general",
            evaluationStrategy: .probabilisticWeights(selector: selector)
        )

        let mixedRequest = makeSampleRequest(content: "Send my basketball info to john@example.com")
        let result = try await router.determineDomain(for: mixedRequest)

        // Since PII has much higher weight (100 vs 10), it should almost always win
        // We'll just verify we get a valid domain
        XCTAssertTrue(["sports", "private"].contains(result!))
    }

    func testCustomStrategy() async throws {
        let customResolver: ([LogicRule]) -> String? = { rules in
            // Custom logic: prefer finance over sports, regardless of priority
            if rules.contains(where: { $0.domain == "finance" }) {
                return "finance"
            } else if rules.contains(where: { $0.domain == "sports" }) {
                return "sports"
            }
            return nil
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .custom(customResolver)
        )

        let mixedRequest = makeSampleRequest(content: "What's the basketball loan rate?")
        let result = try await router.determineDomain(for: mixedRequest)
        XCTAssertEqual(result, "finance")
    }

    // MARK: - Default Domain Fallback Tests (These will demonstrate the bug!)

    func testDefaultDomainFallback_FirstMatch() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        // BUG: This currently returns nil instead of "general"
        XCTAssertEqual(result, "general", "Should return defaultDomain when no rules match")
    }

    func testDefaultDomainFallback_HighestPriority() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .highestPriority
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        // BUG: This currently returns nil instead of "general" 
        XCTAssertEqual(result, "general", "Should return defaultDomain when no rules match")
    }

    func testDefaultDomainFallback_TopKThenResolve() async throws {
        let resolver: ([LogicRule]) -> String? = { rules in
            return rules.first?.domain
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .topKThenResolve(k: 2, resolver: resolver)
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        // BUG: This currently returns nil instead of "general"
        XCTAssertEqual(result, "general", "Should return defaultDomain when no rules match")
    }

    func testDefaultDomainFallback_ProbabilisticWeights() async throws {
        let selector: ([LogicRule]) -> [(domain: String, weight: Double)] = { rules in
            return rules.map { (domain: $0.domain, weight: 1.0) }
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .probabilisticWeights(selector: selector)
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        // BUG: This currently returns nil instead of "general"
        XCTAssertEqual(result, "general", "Should return defaultDomain when no rules match")
    }

    func testDefaultDomainFallback_Custom() async throws {
        let customResolver: ([LogicRule]) -> String? = { rules in
            return rules.first?.domain
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance", "general"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: "general",
            evaluationStrategy: .custom(customResolver)
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        // BUG: This currently returns nil instead of "general"
        XCTAssertEqual(result, "general", "Should return defaultDomain when no rules match")
    }

    func testNilDefaultDomain() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["sports", "finance"],
            rules: [makeSportsRule(), makeFinanceRule()],
            defaultDomain: nil,
            evaluationStrategy: .firstMatch
        )

        let unmatchedRequest = makeSampleRequest(content: "What's the weather like today?")
        let result = try await router.determineDomain(for: unmatchedRequest)

        XCTAssertNil(result, "Should return nil when no rules match and no defaultDomain is set")
    }

    // MARK: - Rule Builder Tests

    func testRegexRuleBuilder() async throws {
        let rule = LogicRule.regex(
            name: "Test",
            pattern: #"\btest\b"#,
            domain: "testing",
            priority: 5
        )

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["testing", "general"],
            rules: [rule],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let matchingRequest = makeSampleRequest(content: "This is a test message")
        let result = try await router.determineDomain(for: matchingRequest)
        XCTAssertEqual(result, "testing")

        let nonMatchingRequest = makeSampleRequest(content: "This is testing")
        let nonResult = try await router.determineDomain(for: nonMatchingRequest)
        XCTAssertEqual(nonResult, "general")
    }

    func testTokensRuleBuilder() async throws {
        let rule = LogicRule.tokens(
            name: "Long Content",
            domain: "detailed",
            priority: 1
        ) { tokenCount in
            tokenCount > 50
        }

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["detailed", "general"],
            rules: [rule],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let longRequest = makeSampleRequest(content: String(repeating: "word ", count: 100))
        let result = try await router.determineDomain(for: longRequest)
        XCTAssertEqual(result, "detailed")

        let shortRequest = makeSampleRequest(content: "short")
        let shortResult = try await router.determineDomain(for: shortRequest)
        XCTAssertEqual(shortResult, "general")
    }

    func testHoursRuleBuilder() async throws {
        let businessHours = 9...17
        let mockClock: () -> Date = {
            var components = DateComponents()
            components.hour = 14 // 2 PM
            return Calendar.current.date(from: components) ?? Date()
        }

        let rule = LogicRule.hours(
            name: "Business Hours",
            hours: businessHours,
            domain: "business",
            priority: 1,
            clock: mockClock
        )

        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["business", "general"],
            rules: [rule],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let anyRequest = makeSampleRequest(content: "Any message")
        let result = try await router.determineDomain(for: anyRequest)
        XCTAssertEqual(result, "business")
    }

    // MARK: - Edge Cases

    func testEmptyRules() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["general"],
            rules: [],
            defaultDomain: "general",
            evaluationStrategy: .firstMatch
        )

        let anyRequest = makeSampleRequest(content: "Any message")
        let result = try await router.determineDomain(for: anyRequest)
        XCTAssertEqual(result, "general")
    }

    func testCaseInsensitiveDomains() async throws {
        let router = LogicDomainRouter(
            name: "TestRouter",
            supportedDomains: ["SPORTS", "Finance", "general"],
            rules: [
                LogicRule(name: "Mixed Case", domain: "SPORTS", priority: 1) { _ in true }
            ],
            defaultDomain: "GENERAL",
            evaluationStrategy: .firstMatch
        )

        let anyRequest = makeSampleRequest(content: "Any message")
        let result = try await router.determineDomain(for: anyRequest)
        XCTAssertEqual(result, "sports") // Should be lowercased
    }
}
