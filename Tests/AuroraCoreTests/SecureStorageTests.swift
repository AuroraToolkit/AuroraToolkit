//
//  SecureStorageTests.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 12/26/24.
//

import XCTest
@testable import AuroraCore

#if os(macOS)
final class SecureStorageTests: XCTestCase {

    let testServiceName = "TestService"
    let testAPIKey = "test-api-key"
    let testBaseURL = "https://test.example.com"

    override func setUpWithError() throws {
        // Ensure the test environment starts clean
        SecureStorage.clearAll(for: testServiceName)
    }

    override func tearDownWithError() throws {
        // Clean up after tests
        SecureStorage.clearAll(for: testServiceName)
    }

    func testSaveAndGetAPIKey() throws {
        // Save API key
        try SecureStorage.saveAPIKey(testAPIKey, for: testServiceName)

        // Retrieve API key
        let retrievedKey = SecureStorage.getAPIKey(for: testServiceName)
        XCTAssertEqual(retrievedKey, testAPIKey, "Retrieved API key should match the saved key.")
    }

    func testGetAPIKeyForNonexistentService() throws {
        // Attempt to retrieve an API key for a nonexistent service
        let retrievedKey = SecureStorage.getAPIKey(for: "NonexistentService")
        XCTAssertNil(retrievedKey, "API key for a nonexistent service should return nil.")
    }

    func testDeleteAPIKey() throws {
        // Save API key
        try SecureStorage.saveAPIKey(testAPIKey, for: testServiceName)

        // Delete API key
        SecureStorage.deleteAPIKey(for: testServiceName)

        // Attempt to retrieve the deleted key
        let retrievedKey = SecureStorage.getAPIKey(for: testServiceName)
        XCTAssertNil(retrievedKey, "Deleted API key should return nil.")
    }

    func testSaveAndGetBaseURL() throws {
        // Save base URL
        try SecureStorage.saveBaseURL(testBaseURL, for: testServiceName)

        // Retrieve base URL
        let retrievedURL = SecureStorage.getBaseURL(for: testServiceName)
        XCTAssertEqual(retrievedURL, testBaseURL, "Retrieved base URL should match the saved URL.")
    }

    func testGetBaseURLForNonexistentService() throws {
        // Attempt to retrieve a base URL for a nonexistent service
        let retrievedURL = SecureStorage.getBaseURL(for: "NonexistentService")
        XCTAssertNil(retrievedURL, "Base URL for a nonexistent service should return nil.")
    }

    func testDeleteBaseURL() throws {
        // Save base URL
        try SecureStorage.saveBaseURL(testBaseURL, for: testServiceName)

        // Delete base URL
        SecureStorage.deleteBaseURL(for: testServiceName)

        // Attempt to retrieve the deleted base URL
        let retrievedURL = SecureStorage.getBaseURL(for: testServiceName)
        XCTAssertNil(retrievedURL, "Deleted base URL should return nil.")
    }

    func testClearAll() throws {
        // Save multiple items
        try SecureStorage.saveAPIKey(testAPIKey, for: testServiceName)
        try SecureStorage.saveBaseURL(testBaseURL, for: testServiceName)

        // Verify multiple items are saved
        XCTAssertNotNil(SecureStorage.getAPIKey(for: testServiceName))
        XCTAssertNotNil(SecureStorage.getBaseURL(for: testServiceName))

        // Clear all items
        SecureStorage.clearAll(for: testServiceName)

        // Verify that all items are removed
        XCTAssertNil(SecureStorage.getAPIKey(for: testServiceName), "API key should be cleared.")
        XCTAssertNil(SecureStorage.getBaseURL(for: testServiceName), "Base URL should be cleared.")
    }

    func testOverwriteAPIKey() throws {
        let newAPIKey = "new-api-key"

        // Save initial API key
        try SecureStorage.saveAPIKey(testAPIKey, for: testServiceName)

        // Overwrite with a new API key
        try SecureStorage.saveAPIKey(newAPIKey, for: testServiceName)

        // Retrieve and verify the updated API key
        let retrievedKey = SecureStorage.getAPIKey(for: testServiceName)
        XCTAssertEqual(retrievedKey, newAPIKey, "Retrieved API key should match the updated key.")
    }

    func testOverwriteBaseURL() throws {
        let newBaseURL = "https://new.example.com"

        // Save initial base URL
        try SecureStorage.saveBaseURL(testBaseURL, for: testServiceName)

        // Overwrite with a new base URL
        try SecureStorage.saveBaseURL(newBaseURL, for: testServiceName)

        // Retrieve and verify the updated base URL
        let retrievedURL = SecureStorage.getBaseURL(for: testServiceName)
        XCTAssertEqual(retrievedURL, newBaseURL, "Retrieved base URL should match the updated URL.")
    }
}

#else
    /// Secure storage tests are not supported on iOS test environments
#endif
