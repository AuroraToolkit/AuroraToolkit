//
//  SummaryItem.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import Foundation

/// Represents a summary of one or more context items.
/// Contains references to the original items that were summarized.
public struct SummaryItem: Identifiable, Codable, Equatable {
    /// Unique identifier for the summary.
    public let id: UUID
    
    /// The content of the summary (typically text, but can be other types in the future).
    public var content: ContentType
    
    /// The date the summary was created.
    public var creationDate: Date
    
    /// The estimated token count for the summary content.
    public var tokenCount: Int
    
    /// References to the original items that were summarized.
    public var summarizedItemIDs: [UUID]
    
    /// Initializes a new `SummaryItem`.
    ///
    /// - Parameters:
    ///   - content: The content of the summary.
    ///   - creationDate: The date the summary was created (default is the current date).
    ///   - summarizedItemIDs: The IDs of the original items that were summarized.
    public init(content: ContentType, creationDate: Date = Date(), summarizedItemIDs: [UUID]) {
        id = UUID()
        self.content = content
        self.creationDate = creationDate
        self.tokenCount = content.estimatedTokenCount
        self.summarizedItemIDs = summarizedItemIDs
    }
    
    /// Convenience initializer for text summaries.
    ///
    /// - Parameters:
    ///   - text: The text content of the summary.
    ///   - creationDate: The date the summary was created (default is the current date).
    ///   - summarizedItemIDs: The IDs of the original items that were summarized.
    public init(text: String, creationDate: Date = Date(), summarizedItemIDs: [UUID]) {
        self.init(content: .text(text), creationDate: creationDate, summarizedItemIDs: summarizedItemIDs)
    }
    
    /// Extracts the text value if the summary is text-based.
    public var text: String? {
        return content.textValue
    }
}

