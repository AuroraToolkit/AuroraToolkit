//
//  ContextSummaryReferencesTests.swift
//  AuroraTests
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import XCTest
@testable import AuroraLLM

final class ContextSummaryReferencesTests: XCTestCase {
    
    var contextController: ContextController!
    var mockService: MockLLMService!
    var mockSummarizer: MockSummarizer!
    
    override func setUp() {
        super.setUp()
        mockService = MockLLMService(name: "TestService", maxOutputTokens: 100, expectedResult: .success(MockLLMResponse(text: "Summary")))
        mockSummarizer = MockSummarizer(expectedSummaries: ["Summary of items"])
        contextController = ContextController(llmService: mockService, summarizer: mockSummarizer)
    }
    
    override func tearDown() {
        contextController = nil
        super.tearDown()
    }
    
    func testSummaryReferencesOriginalItems() async throws {
        // Given
        contextController.addItem(content: "Item 1", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        contextController.addItem(content: "Item 2", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        let originalItems = contextController.getItems()
        let originalItemIDs = originalItems.map { $0.id }
        
        // When
        try await contextController.summarizeOlderContext()
        
        // Then
        let summaries = contextController.summarizedContext()
        XCTAssertEqual(summaries.count, 1, "Should have one summary")
        
        let summary = summaries.first!
        XCTAssertEqual(summary.summarizedItemIDs.count, 2, "Summary should reference 2 original items")
        XCTAssertTrue(summary.summarizedItemIDs.contains(originalItemIDs[0]), "Summary should reference first item")
        XCTAssertTrue(summary.summarizedItemIDs.contains(originalItemIDs[1]), "Summary should reference second item")
    }
    
    func testGetOriginalItemsFromSummary() async throws {
        // Given
        contextController.addItem(content: "Original item", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        let originalItem = contextController.getItems().first!
        
        // When
        try await contextController.summarizeOlderContext()
        
        // Then
        let summaries = contextController.summarizedContext()
        let summary = summaries.first!
        
        // Verify we can get the original item using the reference
        let referencedItem = contextController.getContext().getItem(by: summary.summarizedItemIDs.first!)
        XCTAssertNotNil(referencedItem, "Should be able to retrieve original item via summary reference")
        XCTAssertEqual(referencedItem?.text, "Original item", "Referenced item should match original")
    }
    
    func testMultipleSummariesReferenceDifferentItems() async throws {
        // Given
        contextController.addItem(content: "Item 1", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        contextController.addItem(content: "Item 2", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        let item1ID = contextController.getItems()[0].id
        let item2ID = contextController.getItems()[1].id
        
        // When - summarize first time
        try await contextController.summarizeOlderContext()
        
        // Add more items and summarize again
        contextController.addItem(content: "Item 3", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        try await contextController.summarizeOlderContext()
        
        // Then
        let summaries = contextController.summarizedContext()
        XCTAssertEqual(summaries.count, 2, "Should have 2 summaries")
        
        // First summary should reference items 1 and 2
        let firstSummary = summaries[0]
        XCTAssertTrue(firstSummary.summarizedItemIDs.contains(item1ID))
        XCTAssertTrue(firstSummary.summarizedItemIDs.contains(item2ID))
        
        // Second summary should reference item 3
        let secondSummary = summaries[1]
        XCTAssertTrue(secondSummary.summarizedItemIDs.contains(contextController.getItems().first(where: { $0.text == "Item 3" })?.id ?? UUID()))
    }
    
    func testSummaryPersistsWithReferences() async throws {
        // Given
        contextController.addItem(content: "Item to summarize", creationDate: Date().addingTimeInterval(-8 * 24 * 60 * 60))
        let originalItemID = contextController.getItems().first!.id
        
        // When
        try await contextController.summarizeOlderContext()
        let context = contextController.getContext()
        
        // Then - verify summary is in context and has references
        let summaries = context.summaries
        XCTAssertEqual(summaries.count, 1, "Summary should be in context")
        XCTAssertTrue(summaries.first?.summarizedItemIDs.contains(originalItemID) ?? false, "Summary should reference original item")
    }
}

