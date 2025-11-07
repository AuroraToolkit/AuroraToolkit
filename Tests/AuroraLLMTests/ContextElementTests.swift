//
//  ContextElementTests.swift
//  AuroraTests
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import XCTest
@testable import AuroraLLM

final class ContextElementTests: XCTestCase {
    
    func testContextElementItem() {
        // Given
        let item = ContextItem(text: "Test item")
        
        // When
        let element = ContextElement.item(item)
        
        // Then
        XCTAssertEqual(element.id, item.id)
        XCTAssertEqual(element.text, "Test item")
        XCTAssertNotNil(element.asItem)
        XCTAssertNil(element.asSummary)
        XCTAssertEqual(element.asItem?.id, item.id)
    }
    
    func testContextElementSummary() {
        // Given
        let itemIDs = [UUID()]
        let summary = SummaryItem(text: "Test summary", summarizedItemIDs: itemIDs)
        
        // When
        let element = ContextElement.summary(summary)
        
        // Then
        XCTAssertEqual(element.id, summary.id)
        XCTAssertEqual(element.text, "Test summary")
        XCTAssertNil(element.asItem)
        XCTAssertNotNil(element.asSummary)
        XCTAssertEqual(element.asSummary?.id, summary.id)
    }
    
    func testContextElementContentType() {
        // Given
        let item = ContextItem(text: "Item text")
        let summary = SummaryItem(text: "Summary text", summarizedItemIDs: [UUID()])
        
        // When
        let itemElement = ContextElement.item(item)
        let summaryElement = ContextElement.summary(summary)
        
        // Then
        if case .text(let itemText) = itemElement.contentType {
            XCTAssertEqual(itemText, "Item text")
        } else {
            XCTFail("Item content type should be text")
        }
        
        if case .text(let summaryText) = summaryElement.contentType {
            XCTAssertEqual(summaryText, "Summary text")
        } else {
            XCTFail("Summary content type should be text")
        }
    }
    
    func testContextElementCreationDate() {
        // Given
        let customDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let item = ContextItem(text: "Item", creationDate: customDate)
        let summary = SummaryItem(text: "Summary", creationDate: customDate, summarizedItemIDs: [UUID()])
        
        // When
        let itemElement = ContextElement.item(item)
        let summaryElement = ContextElement.summary(summary)
        
        // Then
        XCTAssertEqual(itemElement.creationDate.timeIntervalSince1970, customDate.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(summaryElement.creationDate.timeIntervalSince1970, customDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testContextElementEquality() {
        // Given
        let item1 = ContextItem(text: "Item")
        let item2 = ContextItem(text: "Item")
        let summary1 = SummaryItem(text: "Summary", summarizedItemIDs: [UUID()])
        let summary2 = SummaryItem(text: "Summary", summarizedItemIDs: [UUID()])
        
        // When
        let element1 = ContextElement.item(item1)
        let element2 = ContextElement.item(item2)
        let element3 = ContextElement.summary(summary1)
        let element4 = ContextElement.summary(summary2)
        
        // Then
        // Elements with same item should be equal (if items are equal)
        // Note: Items have different IDs, so they won't be equal
        // But we can test the pattern matching
        if case .item(let extractedItem1) = element1,
           case .item(let extractedItem2) = element2 {
            XCTAssertEqual(extractedItem1.text, extractedItem2.text)
        }
        
        if case .summary(let extractedSummary1) = element3,
           case .summary(let extractedSummary2) = element4 {
            XCTAssertEqual(extractedSummary1.text, extractedSummary2.text)
        }
    }
    
    func testContextElementCodable() throws {
        // Given
        let item = ContextItem(text: "Test item")
        let summary = SummaryItem(text: "Test summary", summarizedItemIDs: [UUID()])
        let itemElement = ContextElement.item(item)
        let summaryElement = ContextElement.summary(summary)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let itemData = try encoder.encode(itemElement)
        let summaryData = try encoder.encode(summaryElement)
        let decodedItem = try decoder.decode(ContextElement.self, from: itemData)
        let decodedSummary = try decoder.decode(ContextElement.self, from: summaryData)
        
        // Then
        if case .item(let decodedItemValue) = decodedItem {
            XCTAssertEqual(decodedItemValue.text, item.text)
        } else {
            XCTFail("Decoded item element should be an item")
        }
        
        if case .summary(let decodedSummaryValue) = decodedSummary {
            XCTAssertEqual(decodedSummaryValue.text, summary.text)
        } else {
            XCTFail("Decoded summary element should be a summary")
        }
    }
    
    func testContextElementTextAccess() {
        // Given
        let item = ContextItem(text: "Item text")
        let summary = SummaryItem(text: "Summary text", summarizedItemIDs: [UUID()])
        
        // When
        let itemElement = ContextElement.item(item)
        let summaryElement = ContextElement.summary(summary)
        
        // Then
        XCTAssertEqual(itemElement.text, "Item text")
        XCTAssertEqual(summaryElement.text, "Summary text")
    }
}

