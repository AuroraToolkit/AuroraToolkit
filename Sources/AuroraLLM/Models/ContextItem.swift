//
//  ContextItem.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 8/20/24.
//

import Foundation

/// A representation of an individual item within a context. Each `ContextItem` has content
/// (currently text, but supports multi-modal types), a creation date, a flag indicating whether
/// it has been summarized, and an estimated token count.
///
/// `ContextItem`s are uniquely identified by their `UUID` and can be checked for age and equality.
public struct ContextItem: Identifiable, Codable, Equatable {
    /// Unique identifier for the `ContextItem`.
    public let id: UUID

    /// The content of the `ContextItem` (text, or other types in the future).
    private var _content: ContentType

    /// The text content of the `ContextItem` (computed property for backward compatibility).
    public var text: String {
        get {
            return _content.textValue ?? ""
        }
        set {
            _content = .text(newValue)
            tokenCount = _content.estimatedTokenCount
        }
    }

    /// The content of the `ContextItem`.
    public var content: ContentType {
        get {
            return _content
        }
        set {
            _content = newValue
            tokenCount = _content.estimatedTokenCount
        }
    }

    /// The date the `ContextItem` was created.
    public var creationDate: Date

    /// A flag indicating whether the `ContextItem` has been summarized.
    public var isSummarized: Bool

    /// The estimated token count for the content of the `ContextItem`.
    public var tokenCount: Int

    /// Initializes a new `ContextItem` with the specified text content and optional parameters for creation date and summary status.
    ///
    /// - Parameters:
    ///    - text: The text content of the `ContextItem`.
    ///    - creationDate: The date the item was created (default is the current date).
    ///    - isSummarized: A flag indicating whether the item has been summarized (default is `false`).
    public init(text: String, creationDate: Date = Date(), isSummarized: Bool = false) {
        id = UUID()
        self._content = .text(text)
        self.creationDate = creationDate
        self.isSummarized = isSummarized
        self.tokenCount = ContentType.text(text).estimatedTokenCount
    }

    /// Initializes a new `ContextItem` with the specified content.
    ///
    /// - Parameters:
    ///    - content: The content of the `ContextItem`.
    ///    - creationDate: The date the item was created (default is the current date).
    ///    - isSummarized: A flag indicating whether the item has been summarized (default is `false`).
    public init(content: ContentType, creationDate: Date = Date(), isSummarized: Bool = false) {
        id = UUID()
        self._content = content
        self.creationDate = creationDate
        self.isSummarized = isSummarized
        self.tokenCount = content.estimatedTokenCount
    }

    /// Helper method to estimate the token count for a given text.
    ///
    /// This is a rough estimate that assumes 1 token per 4 characters (on average).
    ///
    /// - Parameter text: The text content to estimate token count for.
    ///
    /// - Returns: The estimated number of tokens.
    public static func estimateTokenCount(for text: String) -> Int {
        return ContentType.text(text).estimatedTokenCount
    }

    /// Checks if the `ContextItem` is older than a specified number of days.
    ///
    /// - Parameter days: The number of days to compare against.
    ///
    /// - Returns: `true` if the item is older than the specified number of days, otherwise `false`.
    public func isOlderThan(days: Int) -> Bool {
        guard let daysAgo = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return false
        }
        return creationDate < daysAgo
    }

    /// Conformance to `Equatable` for comparison between `ContextItem`s.
    ///
    /// - Parameters:
    ///    - lhs: The left-hand side `ContextItem` to compare.
    ///    - rhs: The right-hand side `ContextItem` to compare.
    ///
    /// - Returns: `true` if the `ContextItem`s are equal, otherwise `false`.
    public static func == (lhs: ContextItem, rhs: ContextItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs._content == rhs._content &&
            lhs.creationDate == rhs.creationDate &&
            lhs.isSummarized == rhs.isSummarized &&
            lhs.tokenCount == rhs.tokenCount
    }
}
