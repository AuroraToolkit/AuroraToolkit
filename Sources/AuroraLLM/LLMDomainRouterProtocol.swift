//
//  LLMDomainRouterProtocol.swift
//  AuroraCore
//
//  Created by Dan Murrell Jr on 12/11/24.
//

import Foundation

/// Protocol defining the behavior of a domain router in the LLMManager system.
public protocol LLMDomainRouterProtocol {
    /// The name of the domain router, used for logging and identification purposes.
    var name: String { get }

    /// A list of domains that the router supports.
    var supportedDomains: [String] { get }

    /// Optional fallback domain returned when no domain can be determined or when the determined domain is not in supportedDomains.
    ///
    /// - Note: The `fallbackDomain` is intentionally independent of `supportedDomains`. It represents a domain
    ///   that the router cannot classify, pointing to an external fallback service. If `fallbackDomain` is set
    ///   to a value that exists in `supportedDomains`, it suggests the router should be able to classify it,
    ///   which may indicate a configuration issue.
    var fallbackDomain: String? { get }

    /// Determines the domain for a given request using the associated LLM service.
    ///
    /// - Parameters:
    ///     - request: The `LLMRequest` containing the prompt or context for domain determination.
    ///
    /// - Returns: A string representing the determined domain, or `nil` if not posslbe.
    func determineDomain(for request: LLMRequest) async throws -> String?
}

/// Protocol defining the behavior of a domain router that can provide confidence scores for domain determination.
///
/// - Note: This protocol extends `LLMDomainRouterProtocol` to include a method for determining the domain with a confidence score.
public protocol ConfidentDomainRouter: LLMDomainRouterProtocol {
    /// Determines the domain for a given request using the associated LLM service.
    ///
    /// - Parameters:
    ///     - request: The `LLMRequest` containing the prompt or context for domain determination.
    ///
    /// - Returns: A string representing the determined domain, and double representing confidence, or `nil` if not possible.
    func determineDomainWithConfidence(for request: LLMRequest) async throws -> (String, Double)?
}
