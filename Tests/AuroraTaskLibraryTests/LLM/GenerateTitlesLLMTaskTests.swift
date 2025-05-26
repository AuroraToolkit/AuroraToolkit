//
//  GenerateTitlesLLMTaskTests.swift
//  AuroraToolkit
//
//  Created by Dan Murrell Jr on 1/4/25.
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM
@testable import AuroraTaskLibrary

final class GenerateTitlesLLMTaskTests: XCTestCase {

    func testGenerateTitlesLLMTaskSuccess() async throws {
        // Given
        let mockResponseText = """
        {
          "titles": {
            "The stock market saw significant gains today.": {
              "en": "Stock Market Posts Big Gains",
              "es": "El Mercado Bursátil Registra Grandes Ganancias"
            }
          }
        }
        """
        let mockService = MockLLMService(
            name: "Mock Title Generator",
            expectedResult: .success(MockLLMResponse(text: mockResponseText))
        )

        let task = GenerateTitlesLLMTask(
            llmService: mockService,
            strings: ["The stock market saw significant gains today."],
            languages: ["en", "es"]
        )

        // When
        guard case let .task(unwrappedTask) = task.toComponent() else {
            XCTFail("Failed to unwrap the Workflow.Task from the component.")
            return
        }

        let outputs = try await unwrappedTask.execute()

        // Then
        guard let titles = outputs["titles"] as? [String: [String: String]] else {
            XCTFail("Output 'titles' not found or invalid.")
            return
        }

        XCTAssertEqual(titles["The stock market saw significant gains today."]?["en"], "Stock Market Posts Big Gains", "The generated title in English should match.")
        XCTAssertEqual(titles["The stock market saw significant gains today."]?["es"], "El Mercado Bursátil Registra Grandes Ganancias", "The generated title in Spanish should match.")
    }

    func testGenerateTitlesLLMTaskEmptyInput() async {
        // Given
        let mockService = MockLLMService(
            name: "Mock Title Generator",
            expectedResult: .failure(NSError(domain: "GenerateTitlesTask", code: 1, userInfo: [NSLocalizedDescriptionKey: "No strings provided for title generation."]))
        )

        let task = GenerateTitlesLLMTask(
            llmService: mockService,
            strings: [],
            languages: ["en"]
        )

        // When/Then
        do {
            guard case let .task(unwrappedTask) = task.toComponent() else {
                XCTFail("Failed to unwrap the Workflow.Task from the component.")
                return
            }

            _ = try await unwrappedTask.execute()
            XCTFail("Expected an error to be thrown for empty input, but no error was thrown.")
        } catch {
            XCTAssertEqual((error as NSError).domain, "GenerateTitlesLLMTask", "Error domain should match.")
            XCTAssertEqual((error as NSError).code, 1, "Error code should match for empty input.")
        }
    }

    func testGenerateTitlesLLMTaskIntegrationWithOllama() async throws {
        // Given
        let stringsToTitle = [
            "Scientists discover a new element with groundbreaking properties.",
            "The latest smartphone offers features that are revolutionizing the industry."
        ]
        let ollamaService = OllamaService(name: "OllamaTest")

        let task = GenerateTitlesLLMTask(
            llmService: ollamaService,
            strings: stringsToTitle,
            languages: ["en", "es"]
        )

        // When
        guard case let .task(unwrappedTask) = task.toComponent() else {
            XCTFail("Failed to unwrap the Workflow.Task from the component.")
            return
        }

        let outputs = try await unwrappedTask.execute()

        // Then
        guard let titles = outputs["titles"] as? [String: [String: String]] else {
            XCTFail("Output 'titles' not found or invalid.")
            return
        }

        XCTAssertTrue(titles.keys.contains("Scientists discover a new element with groundbreaking properties."), "Generated titles should include all input strings.")
        XCTAssertTrue(titles.keys.contains("The latest smartphone offers features that are revolutionizing the industry."), "Generated titles should include all input strings.")

        for (text, translations) in titles {
            XCTAssertFalse(translations.isEmpty, "Each text should have translations for specified languages.")
            for (lang, title) in translations {
                XCTAssertFalse(title.isEmpty, "Generated title in \(lang) for '\(text)' should not be empty.")
            }
        }
    }
}
