//
//  Context.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 8/20/24.
//

import Foundation

/// Represents the entire context for a conversation or task.
///
/// A `Context` stores a collection of `ContextElement` instances (items and summaries) and `Bookmark` instances,
/// which represent the content and notable points in a conversation or task.
/// The context is uniquely identified by its `UUID` and contains metadata about the associated LLM service.
public struct Context: Codable, Equatable {
    /// Unique identifier for the context.
    public let id: UUID

    /// A collection of `ContextElement` instances (items and summaries) that make up the content of the context.
    internal var elements: [ContextElement] = []

    /// A collection of `ContextItem` instances (computed from elements for backward compatibility).
    /// Items are returned in chronological order (oldest first).
    public var items: [ContextItem] {
        get {
            return elements.compactMap { $0.asItem }
                .sorted { $0.creationDate < $1.creationDate }
        }
        set {
            // Replace all elements with new items, sorted by creation date
            elements = newValue.map { .item($0) }
                .sorted { $0.creationDate < $1.creationDate }
        }
    }

    /// A collection of `SummaryItem` instances (computed from elements).
    /// Summaries are returned in chronological order (oldest first).
    public var summaries: [SummaryItem] {
        return elements.compactMap { $0.asSummary }
            .sorted { $0.creationDate < $1.creationDate }
    }

    /// A collection of `Bookmark` instances within the context.
    public private(set) var bookmarks: [Bookmark] = []

    /// The name of the LLM service vendor associated with this context.
    public var llmServiceVendor: String

    /// The creation date for the context.
    public let creationDate: Date

    /// Initializes a new `Context` with a unique identifier and associated LLM service information.
    ///
    /// - Parameters:
    ///    - llmServiceVendor: The name of the LLM service vendor associated with this context.
    ///    - creationDate: The date when the context was created. Defaults to the current date.
    public init(llmServiceVendor: String, creationDate: Date = Date()) {
        id = UUID()
        self.llmServiceVendor = llmServiceVendor
        self.creationDate = creationDate
    }

    /// Adds a new item to the context.
    ///
    /// - Parameters:
    ///    - content: The content of the new `ContextItem`.
    ///    - creationDate: The date the item was created (default is the current date).
    ///    - isSummarized: A flag indicating whether the item has been summarized (default is `false`).
    public mutating func addItem(content: String, creationDate: Date = Date(), isSummarized: Bool = false) {
        let newItem = ContextItem(text: content, creationDate: creationDate, isSummarized: isSummarized)
        elements.append(.item(newItem))
    }

    /// Adds a new summary to the context.
    ///
    /// - Parameters:
    ///    - summary: The `SummaryItem` to add.
    public mutating func addSummary(_ summary: SummaryItem) {
        elements.append(.summary(summary))
    }

    /// Adds a new bookmark to the context for a specific item.
    ///
    /// - Parameters:
    ///    - item: The `ContextItem` to be bookmarked.
    ///    - label: A label describing the purpose of the bookmark.
    public mutating func addBookmark(for item: ContextItem, label: String) {
        let newBookmark = Bookmark(contextItemID: item.id, label: label)
        bookmarks.append(newBookmark)
    }

    /// Retrieves a `ContextElement` by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the element.
    ///
    /// - Returns: The `ContextElement` if found, otherwise `nil`.
    public func getElement(by id: UUID) -> ContextElement? {
        return elements.first(where: { $0.id == id })
    }

    /// Retrieves a `ContextItem` by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the item.
    ///
    /// - Returns: The `ContextItem` if found, otherwise `nil`.
    public func getItem(by id: UUID) -> ContextItem? {
        return getElement(by: id)?.asItem
    }

    /// Retrieves a `SummaryItem` by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the summary.
    ///
    /// - Returns: The `SummaryItem` if found, otherwise `nil`.
    public func getSummary(by id: UUID) -> SummaryItem? {
        return getElement(by: id)?.asSummary
    }

    /// Retrieves a `Bookmark` by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the bookmark.
    ///
    /// - Returns: The `Bookmark` if found, otherwise `nil`.
    public func getBookmark(by id: UUID) -> Bookmark? {
        return bookmarks.first(where: { $0.id == id })
    }

    /// Removes elements from the context by their index set.
    ///
    /// - Parameter offsets: An `IndexSet` of the elements to be removed.
    public mutating func removeElements(atOffsets offsets: IndexSet) {
        for index in offsets.reversed() {
            elements.remove(at: index)
        }
    }

    /// Removes items from the context by their index set (backward compatibility).
    ///
    /// - Parameter offsets: An `IndexSet` of the items to be removed.
    public mutating func removeItems(atOffsets offsets: IndexSet) {
        // Remove elements at the specified offsets
        removeElements(atOffsets: offsets)
    }

    /// Updates an element within the context.
    ///
    /// - Parameter element: The `ContextElement` to be updated.
    public mutating func updateElement(_ element: ContextElement) {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index] = element
        }
    }

    /// Updates an item within the context.
    ///
    /// - Parameter updatedItem: The `ContextItem` to be updated.
    public mutating func updateItem(_ updatedItem: ContextItem) {
        updateElement(.item(updatedItem))
    }

    /// Retrieves the most recent `N` elements from the context.
    /// Elements are returned in chronological order (oldest first).
    ///
    /// - Parameter limit: The number of recent elements to retrieve.
    ///
    /// - Returns: An array of the most recent `ContextElement` instances, sorted by creation date.
    public func getRecentElements(limit: Int) -> [ContextElement] {
        let sortedElements = elements.sorted { $0.creationDate < $1.creationDate }
        return Array(sortedElements.suffix(limit))
    }

    /// Retrieves the most recent `N` items from the context.
    /// Items are returned in chronological order (oldest first).
    ///
    /// - Parameter limit: The number of recent items to retrieve.
    ///
    /// - Returns: An array of the most recent `ContextItem` instances, sorted by creation date.
    public func getRecentItems(limit: Int) -> [ContextItem] {
        // items property already returns sorted items, so we just need the suffix
        return Array(items.suffix(limit))
    }

    /// Summarizes a range of items within the context and replaces them with a summary item.
    /// Note: This method operates on the sorted items array, so the range indices correspond to chronological order.
    ///
    /// - Parameters:
    ///    - range: The range of items to summarize (indices correspond to chronologically sorted items).
    ///    - summarizer: A closure that summarizes the text content of the items.
    public mutating func summarizeItemsInRange(range: Range<Int>, summarizer: (String) -> String) {
        // Get sorted items for the range
        let sortedItems = items
        let itemsToSummarize = Array(sortedItems[range])
        let groupText = itemsToSummarize.map { $0.text }.joined(separator: "\n")
        let summaryText = summarizer(groupText)
        
        // Create summary with references to original items
        let summaryItem = SummaryItem(
            text: summaryText,
            summarizedItemIDs: itemsToSummarize.map { $0.id }
        )

        // Find and remove the corresponding elements in the elements array
        // We need to find elements by ID since elements might not be in the same order
        let itemIDs = Set(itemsToSummarize.map { $0.id })
        elements.removeAll { element in
            if case .item(let item) = element {
                return itemIDs.contains(item.id)
            }
            return false
        }
        
        // Add the summary element, maintaining chronological order
        elements.append(.summary(summaryItem))
        // Re-sort elements to maintain chronological order
        elements.sort { $0.creationDate < $1.creationDate }
    }

    /// Conformance to `Equatable` for comparison between contexts.
    ///
    /// - Parameters:
    ///    - lhs: The left-hand side `Context` to compare.
    ///    - rhs: The right-hand side `Context` to compare.
    ///
    /// - Returns: `true` if the contexts are equal, otherwise `false`.
    public static func == (lhs: Context, rhs: Context) -> Bool {
        return lhs.id == rhs.id &&
            lhs.elements == rhs.elements &&
            lhs.bookmarks == rhs.bookmarks &&
            lhs.llmServiceVendor == rhs.llmServiceVendor &&
            abs(lhs.creationDate.timeIntervalSince(rhs.creationDate)) < 1.0 // Ignore differences smaller than 1 second
    }
}
