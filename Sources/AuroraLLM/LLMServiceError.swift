//
//  LLMServiceError.swift
//
//
//  Created by Dan Murrell Jr on 9/13/24.
//

import Foundation

/// `LLMServiceError` defines a set of error types that can occur while interacting with LLM services.
/// These errors provide more granular control and understanding of the failure points within the service.
public enum LLMServiceError: Error, Equatable {
    /// Error thrown when the API key is missing for a service that requires authentication.
    case missingAPIKey

    /// Error thrown when the response from the API is invalid, typically due to an unexpected status code.
    case invalidResponse(statusCode: Int)

    /// Error thrown when the service encounters an issue decoding the response data.
    case decodingError

    /// Error thrown when the constructed or provided URL is invalid.
    case invalidURL

    /// Error thrown when a service is not available on the current platform or configuration.
    case serviceUnavailable(message: String)

    /// Error thrown when a request to the service fails.
    case requestFailed(message: String)

    /// Custom error type for providing more descriptive error messages.
    case custom(message: String)
}
