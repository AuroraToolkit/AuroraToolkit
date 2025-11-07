//
//  ContextElement.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import Foundation

/// Represents an element in a context, which can be either an original item or a summary.
public enum ContextElement: Identifiable, Codable, Equatable {
    case item(ContextItem)
    case summary(SummaryItem)
    
    /// The unique identifier for this element.
    public var id: UUID {
        switch self {
        case .item(let item):
            return item.id
        case .summary(let summary):
            return summary.id
        }
    }
    
    /// The content type of this element.
    public var contentType: ContentType {
        switch self {
        case .item(let item):
            return item.content
        case .summary(let summary):
            return summary.content
        }
    }
    
    /// The creation date of this element.
    public var creationDate: Date {
        switch self {
        case .item(let item):
            return item.creationDate
        case .summary(let summary):
            return summary.creationDate
        }
    }
    
    /// Extracts the text value if the element is text-based.
    public var text: String? {
        return contentType.textValue
    }
    
    /// Returns the item if this is an item case, otherwise nil.
    public var asItem: ContextItem? {
        if case .item(let item) = self {
            return item
        }
        return nil
    }
    
    /// Returns the summary if this is a summary case, otherwise nil.
    public var asSummary: SummaryItem? {
        if case .summary(let summary) = self {
            return summary
        }
        return nil
    }
}

