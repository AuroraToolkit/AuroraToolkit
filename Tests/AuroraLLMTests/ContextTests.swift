//
//  ContextTests.swift
//  AuroraTests
//
//  Created by Dan Murrell Jr on 8/21/24.
//

import XCTest
@testable import AuroraCore
@testable import AuroraLLM

final class ContextTests: XCTestCase {

    var context: Context!

    override func setUp() {
        super.setUp()
        context = Context(llmServiceVendor: "openai")
    }

    override func tearDown() {
        context = nil
        super.tearDown()
    }

    // Test that a new Context sets the creationDate correctly
    func testContextCreationDate() {
        // Given
        let expectedDate = Date()

        // When
        let context = Context(llmServiceVendor: "openai", creationDate: expectedDate)

        // Then
        let calendar = Calendar.current
        let roundedExpectedDate = calendar.date(bySetting: .nanosecond, value: 0, of: expectedDate)
        let roundedCreationDate = calendar.date(bySetting: .nanosecond, value: 0, of: context.creationDate)

        XCTAssertEqual(roundedCreationDate, roundedExpectedDate, "The creationDate should be set correctly upon initialization.")
    }

    // Test adding a new item to the context
    func testAddItem() {
        // Given
        let content = "New item"

        // When
        context.addItem(content: content)

        // Then
        XCTAssertEqual(context.items.count, 1)
        XCTAssertEqual(context.items.first?.text, content)
        XCTAssertFalse(context.items.first?.isSummarized ?? true)
    }

    // Test that the context's creationDate persists through encoding and decoding
    func testContextPersistenceWithCreationDate() {
        // Given
        let expectedDate = Date(timeIntervalSince1970: 1000) // Use a fixed timestamp for the test
        context = Context(llmServiceVendor: "openai", creationDate: expectedDate)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Set the encoding and decoding strategy for dates
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970

        // When
        do {
            let encodedData = try encoder.encode(context)
            let decodedContext = try decoder.decode(Context.self, from: encodedData)

            // Then
            XCTAssertEqual(decodedContext.creationDate, expectedDate, "The creationDate should persist after encoding and decoding.")
        } catch {
            XCTFail("Failed to encode or decode the context: \(error)")
        }
    }

    // Test adding and retrieving a bookmark
    func testAddBookmark() {
        // Given
        let content = "Item with Bookmark"
        context.addItem(content: content)
        let addedItem = context.items.first!
        let label = "Important Bookmark"

        // When
        context.addBookmark(for: addedItem, label: label)

        // Then
        XCTAssertEqual(context.bookmarks.count, 1)
        XCTAssertEqual(context.bookmarks.first?.label, label)
    }

    // Test removing an item by its index
    func testRemoveItems() {
        // Given
        let content = "Item to be removed"
        context.addItem(content: content)

        // When
        context.removeItems(atOffsets: IndexSet(integer: 0))

        // Then
        XCTAssertEqual(context.items.count, 0)
    }

    // Test updating an item in the context
    func testUpdateItem() {
        // Given
        let originalContent = "Original content"
        context.addItem(content: originalContent)
        var updatedItem = context.items.first!
        updatedItem.text = "Updated content"

        // When
        context.updateItem(updatedItem)

        // Then
        XCTAssertEqual(context.items.first?.text, "Updated content")
    }

    // Test retrieving an item by its ID
    func testGetItemById() {
        // Given
        let content = "Retrieve by ID"
        context.addItem(content: content)
        let addedItem = context.items.first!

        // When
        let retrievedItem = context.getItem(by: addedItem.id)

        // Then
        XCTAssertEqual(retrievedItem?.text, addedItem.text)
    }

    // Test summarizing a range of items
    func testSummarizeItemsInRange() {
        // Given
        let items = ["Item 1", "Item 2", "Item 3"]
        items.forEach { context.addItem(content: $0) }
        let summarizer: (String) -> String = { text in
            return "Summary of \(text.components(separatedBy: "\n").count) items."
        }

        // When
        context.summarizeItemsInRange(range: 0..<2, summarizer: summarizer)

        // Then
        // Summaries are now separate from items, so items count decreases
        XCTAssertEqual(context.items.count, 1) // 1 non-summarized item remains
        XCTAssertEqual(context.summaries.count, 1) // 1 summary was created
        XCTAssertEqual(context.summaries.first?.text, "Summary of 2 items.")
    }

    // Test persistence of the context by encoding and decoding
    func testContextPersistence() {
        // Given
        let content = "Persistent Item"
        context.addItem(content: content)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // When
        do {
            let encodedData = try encoder.encode(context)
            let decodedContext = try decoder.decode(Context.self, from: encodedData)

            // Then
            XCTAssertEqual(decodedContext.items.count, context.items.count)
            XCTAssertEqual(decodedContext.items.first?.text, context.items.first?.text)
        } catch {
            XCTFail("Failed to encode or decode the context: \(error)")
        }
    }

    func testGetBookmarkByID() {
        // Given
        context.addItem(content: "Item 1")
        let firstItem = context.items.first!

        // Add a bookmark for the first item
        context.addBookmark(for: firstItem, label: "First Bookmark")

        // When
        let retrievedBookmark = context.getBookmark(by: context.bookmarks.first!.id)

        // Then
        XCTAssertNotNil(retrievedBookmark, "The bookmark should be retrieved successfully.")
        XCTAssertEqual(retrievedBookmark?.label, "First Bookmark", "The bookmark label should match.")
    }

    func testGetRecentItems() {
        // Given
        context.addItem(content: "Item 1")
        context.addItem(content: "Item 2")
        context.addItem(content: "Item 3")

        // When
        let recentItems = context.getRecentItems(limit: 2)

        // Then
        XCTAssertEqual(recentItems.count, 2, "There should be 2 recent items.")
        XCTAssertEqual(recentItems.first?.text, "Item 2", "The first recent item should be 'Item 2'.")
        XCTAssertEqual(recentItems.last?.text, "Item 3", "The last recent item should be 'Item 3'.")
    }
    
    // MARK: - Chronological Order Tests
    
    func testItemsAreInChronologicalOrder() {
        // Given - Add items with different creation dates
        var context = Context(llmServiceVendor: "TestService")
        let date1 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date2 = Date().addingTimeInterval(-1800) // 30 minutes ago
        let date3 = Date() // Now
        
        context.addItem(content: "First item", creationDate: date1)
        context.addItem(content: "Second item", creationDate: date2)
        context.addItem(content: "Third item", creationDate: date3)
        
        // When
        let items = context.items
        
        // Then - Items should be in chronological order (oldest first)
        XCTAssertEqual(items.count, 3, "Should have 3 items")
        XCTAssertEqual(items[0].text, "First item", "First item should be oldest")
        XCTAssertEqual(items[1].text, "Second item", "Second item should be middle")
        XCTAssertEqual(items[2].text, "Third item", "Third item should be newest")
        
        // Verify creation dates are in ascending order
        XCTAssertTrue(items[0].creationDate < items[1].creationDate, "First item should be older than second")
        XCTAssertTrue(items[1].creationDate < items[2].creationDate, "Second item should be older than third")
    }
    
    func testItemsAddedOutOfOrderAreStillChronological() {
        // Given - Add items out of chronological order
        var context = Context(llmServiceVendor: "TestService")
        let date1 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date2 = Date().addingTimeInterval(-1800) // 30 minutes ago
        let date3 = Date() // Now
        
        // Add in reverse order
        context.addItem(content: "Third item", creationDate: date3)
        context.addItem(content: "First item", creationDate: date1)
        context.addItem(content: "Second item", creationDate: date2)
        
        // When
        let items = context.items
        
        // Then - Items should be sorted by creation date (oldest first)
        XCTAssertEqual(items.count, 3, "Should have 3 items")
        XCTAssertEqual(items[0].text, "First item", "First item should be oldest")
        XCTAssertEqual(items[1].text, "Second item", "Second item should be middle")
        XCTAssertEqual(items[2].text, "Third item", "Third item should be newest")
        
        // Verify creation dates are in ascending order
        XCTAssertTrue(items[0].creationDate < items[1].creationDate, "First item should be older than second")
        XCTAssertTrue(items[1].creationDate < items[2].creationDate, "Second item should be older than third")
    }
    
    func testElementsAreInChronologicalOrder() {
        // Given - Add items and summaries with different creation dates
        var context = Context(llmServiceVendor: "TestService")
        let date1 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date2 = Date().addingTimeInterval(-1800) // 30 minutes ago
        let date3 = Date() // Now
        
        context.addItem(content: "First item", creationDate: date1)
        let summary = SummaryItem(text: "Summary", creationDate: date2, summarizedItemIDs: [UUID()])
        context.addSummary(summary)
        context.addItem(content: "Third item", creationDate: date3)
        
        // When
        let elements = context.elements
        
        // Then - Elements should be in chronological order
        XCTAssertEqual(elements.count, 3, "Should have 3 elements")
        XCTAssertTrue(elements[0].creationDate < elements[1].creationDate, "First element should be older than second")
        XCTAssertTrue(elements[1].creationDate < elements[2].creationDate, "Second element should be older than third")
    }
    
    func testGetRecentItemsReturnsChronologicallyOrderedItems() {
        // Given
        var context = Context(llmServiceVendor: "TestService")
        let date1 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date2 = Date().addingTimeInterval(-1800) // 30 minutes ago
        let date3 = Date() // Now
        
        context.addItem(content: "First item", creationDate: date1)
        context.addItem(content: "Second item", creationDate: date2)
        context.addItem(content: "Third item", creationDate: date3)
        
        // When
        let recentItems = context.getRecentItems(limit: 2)
        
        // Then - Recent items should still be in chronological order
        XCTAssertEqual(recentItems.count, 2, "Should have 2 recent items")
        XCTAssertEqual(recentItems[0].text, "Second item", "First recent item should be second oldest")
        XCTAssertEqual(recentItems[1].text, "Third item", "Second recent item should be newest")
        XCTAssertTrue(recentItems[0].creationDate < recentItems[1].creationDate, "Recent items should be chronologically ordered")
    }
    
    func testGetRecentElementsReturnsChronologicallyOrderedElements() {
        // Given
        var context = Context(llmServiceVendor: "TestService")
        let date1 = Date().addingTimeInterval(-3600) // 1 hour ago
        let date2 = Date().addingTimeInterval(-1800) // 30 minutes ago
        let date3 = Date() // Now
        
        context.addItem(content: "First item", creationDate: date1)
        let summary = SummaryItem(text: "Summary", creationDate: date2, summarizedItemIDs: [UUID()])
        context.addSummary(summary)
        context.addItem(content: "Third item", creationDate: date3)
        
        // When
        let recentElements = context.getRecentElements(limit: 2)
        
        // Then - Recent elements should still be in chronological order
        XCTAssertEqual(recentElements.count, 2, "Should have 2 recent elements")
        XCTAssertTrue(recentElements[0].creationDate < recentElements[1].creationDate, "Recent elements should be chronologically ordered")
    }
    
    func testItemsWithSameCreationDateMaintainInsertionOrder() {
        // Given - Add items with the same creation date
        var context = Context(llmServiceVendor: "TestService")
        let sameDate = Date()
        
        context.addItem(content: "First item", creationDate: sameDate)
        context.addItem(content: "Second item", creationDate: sameDate)
        context.addItem(content: "Third item", creationDate: sameDate)
        
        // When
        let items = context.items
        
        // Then - Items with same date should maintain insertion order
        XCTAssertEqual(items.count, 3, "Should have 3 items")
        XCTAssertEqual(items[0].text, "First item", "First item should be first")
        XCTAssertEqual(items[1].text, "Second item", "Second item should be second")
        XCTAssertEqual(items[2].text, "Third item", "Third item should be third")
    }
}
