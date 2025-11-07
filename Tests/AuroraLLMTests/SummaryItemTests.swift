//
//  SummaryItemTests.swift
//  AuroraTests
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import XCTest
@testable import AuroraLLM

final class SummaryItemTests: XCTestCase {
    
    func testSummaryItemInitialization() {
        // Given
        let itemIDs = [UUID(), UUID()]
        let summaryText = "Summary of items"
        
        // When
        let summaryItem = SummaryItem(text: summaryText, summarizedItemIDs: itemIDs)
        
        // Then
        XCTAssertEqual(summaryItem.text, summaryText)
        XCTAssertEqual(summaryItem.summarizedItemIDs, itemIDs)
        XCTAssertEqual(summaryItem.summarizedItemIDs.count, 2)
    }
    
    func testSummaryItemWithContentType() {
        // Given
        let itemIDs = [UUID()]
        let contentType = ContentType.text("Summary content")
        
        // When
        let summaryItem = SummaryItem(content: contentType, summarizedItemIDs: itemIDs)
        
        // Then
        XCTAssertEqual(summaryItem.content, contentType)
        XCTAssertEqual(summaryItem.text, "Summary content")
        XCTAssertEqual(summaryItem.summarizedItemIDs, itemIDs)
    }
    
    func testSummaryItemTokenCount() {
        // Given
        let summaryText = String(repeating: "A", count: 100) // 100 chars = ~25 tokens
        let itemIDs = [UUID()]
        
        // When
        let summaryItem = SummaryItem(text: summaryText, summarizedItemIDs: itemIDs)
        
        // Then
        XCTAssertEqual(summaryItem.tokenCount, 25) // 100 / 4 = 25
    }
    
    func testSummaryItemReferencesMultipleItems() {
        // Given
        let itemID1 = UUID()
        let itemID2 = UUID()
        let itemID3 = UUID()
        let itemIDs = [itemID1, itemID2, itemID3]
        
        // When
        let summaryItem = SummaryItem(text: "Summary", summarizedItemIDs: itemIDs)
        
        // Then
        XCTAssertEqual(summaryItem.summarizedItemIDs.count, 3)
        XCTAssertTrue(summaryItem.summarizedItemIDs.contains(itemID1))
        XCTAssertTrue(summaryItem.summarizedItemIDs.contains(itemID2))
        XCTAssertTrue(summaryItem.summarizedItemIDs.contains(itemID3))
    }
    
    func testSummaryItemEquality() {
        // Given
        let itemIDs = [UUID()]
        let summary1 = SummaryItem(text: "Summary", summarizedItemIDs: itemIDs)
        let summary2 = SummaryItem(text: "Summary", summarizedItemIDs: itemIDs)
        
        // Then
        // Note: IDs are different (generated), so they won't be equal
        // But content and references should match
        XCTAssertEqual(summary1.text, summary2.text)
        XCTAssertEqual(summary1.summarizedItemIDs, summary2.summarizedItemIDs)
    }
    
    func testSummaryItemCodable() throws {
        // Given
        let itemIDs = [UUID(), UUID()]
        let summaryItem = SummaryItem(text: "Test summary", summarizedItemIDs: itemIDs)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let data = try encoder.encode(summaryItem)
        let decoded = try decoder.decode(SummaryItem.self, from: data)
        
        // Then
        XCTAssertEqual(summaryItem.text, decoded.text)
        XCTAssertEqual(summaryItem.summarizedItemIDs, decoded.summarizedItemIDs)
        XCTAssertEqual(summaryItem.tokenCount, decoded.tokenCount)
    }
    
    func testSummaryItemCreationDate() {
        // Given
        let customDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let itemIDs = [UUID()]
        
        // When
        let summaryItem = SummaryItem(text: "Summary", creationDate: customDate, summarizedItemIDs: itemIDs)
        
        // Then
        XCTAssertEqual(summaryItem.creationDate.timeIntervalSince1970, customDate.timeIntervalSince1970, accuracy: 1.0)
    }
}

