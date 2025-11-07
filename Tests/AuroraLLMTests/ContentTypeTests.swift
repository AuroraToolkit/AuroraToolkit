//
//  ContentTypeTests.swift
//  AuroraTests
//
//  Created by Dan Murrell Jr on 11/7/25.
//

import XCTest
@testable import AuroraLLM

final class ContentTypeTests: XCTestCase {
    
    func testTextContentType() {
        // Given
        let contentType = ContentType.text("Hello, World!")
        
        // Then
        XCTAssertEqual(contentType.textValue, "Hello, World!")
        XCTAssertEqual(contentType.estimatedTokenCount, 3) // "Hello, World!" is ~12 chars / 4 = 3
    }
    
    func testTextValueExtraction() {
        // Given
        let contentType = ContentType.text("Test text")
        
        // When
        let textValue = contentType.textValue
        
        // Then
        XCTAssertEqual(textValue, "Test text")
    }
    
    func testTextValueForNonTextContent() {
        // Given
        // Future: When we add .image, .video, etc., textValue should return nil
        // For now, only .text exists, so this test verifies the pattern
        
        // When/Then
        // Currently all content types are text, so this is a placeholder for future types
        let contentType = ContentType.text("Test")
        XCTAssertNotNil(contentType.textValue)
    }
    
    func testTokenCountEstimation() {
        // Given
        let shortText = ContentType.text("Hi")
        let longText = ContentType.text(String(repeating: "A", count: 100))
        
        // Then
        XCTAssertEqual(shortText.estimatedTokenCount, 0) // 2 chars / 4 = 0 (integer division)
        XCTAssertEqual(longText.estimatedTokenCount, 25) // 100 chars / 4 = 25
    }
    
    func testExtractTextForSummarization() {
        // Given
        let contentType = ContentType.text("This is test content for summarization")
        
        // When
        let extractedText = contentType.extractTextForSummarization()
        
        // Then
        XCTAssertEqual(extractedText, "This is test content for summarization")
    }
    
    func testContentTypeEquality() {
        // Given
        let type1 = ContentType.text("Hello")
        let type2 = ContentType.text("Hello")
        let type3 = ContentType.text("World")
        
        // Then
        XCTAssertEqual(type1, type2)
        XCTAssertNotEqual(type1, type3)
    }
    
    func testContentTypeCodable() throws {
        // Given
        let contentType = ContentType.text("Test content")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // When
        let data = try encoder.encode(contentType)
        let decoded = try decoder.decode(ContentType.self, from: data)
        
        // Then
        XCTAssertEqual(contentType, decoded)
        XCTAssertEqual(decoded.textValue, "Test content")
    }
}

