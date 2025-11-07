//
//  ContentType.swift
//  Aurora
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import Foundation

/// Represents the type of content stored in a context item.
/// Supports multiple content types for future multi-modal support.
public enum ContentType: Codable, Equatable {
    case text(String)
    // Future: .image(ImageContent), .video(VideoContent), .file(FileContent), etc.
    
    /// Extracts the text value if the content is text-based.
    public var textValue: String? {
        if case .text(let string) = self {
            return string
        }
        return nil
    }
    
    /// Estimates the token count for this content type.
    public var estimatedTokenCount: Int {
        switch self {
        case .text(let string):
            // Rough estimate: 1 token per 4 characters (average)
            return string.count / 4
        }
    }
    
    /// Extracts text for summarization purposes.
    /// For text content, returns the string. For other types, returns nil.
    public func extractTextForSummarization() -> String? {
        return textValue
    }
}

