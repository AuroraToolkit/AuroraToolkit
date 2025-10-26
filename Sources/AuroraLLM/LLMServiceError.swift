//
//  LLMServiceError.swift
//
//
//  Created by Dan Murrell Jr on 9/13/24.
//

import Foundation

/// `LLMServiceError` defines a set of error types that can occur while interacting with LLM services.
/// These errors provide more granular control and understanding of the failure points within the service.
public enum LLMServiceError: Error, LocalizedError, Equatable {
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
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing for the requested service"
        case .invalidResponse(let statusCode):
            return "Invalid response from service with status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode response data from service"
        case .invalidURL:
            return "Invalid URL provided for service request"
        case .serviceUnavailable(let message):
            return "Service is unavailable: \(message)"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .custom(let message):
            return message
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .missingAPIKey:
            return "No API key found in secure storage or environment variables"
        case .invalidResponse(let statusCode):
            return "Service returned HTTP status code \(statusCode)"
        case .decodingError:
            return "Response data could not be decoded into expected format"
        case .invalidURL:
            return "The constructed or provided URL is malformed"
        case .serviceUnavailable(let message):
            return message
        case .requestFailed(let message):
            return message
        case .custom(let message):
            return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey:
            return "Configure an API key using SecureStorage.saveAPIKey() or set the appropriate environment variable"
        case .invalidResponse:
            return "Check service status and verify request parameters"
        case .decodingError:
            return "Verify the service response format and check for API changes"
        case .invalidURL:
            return "Check the base URL configuration and ensure it's properly formatted"
        case .serviceUnavailable:
            return "Check service status and try again later"
        case .requestFailed:
            return "Review request parameters and check network connectivity"
        case .custom:
            return "Review the error message and check service configuration"
        }
    }
}
