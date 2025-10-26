//
//  TokenHandling.swift
//
//
//  Created by Dan Murrell Jr on 9/1/24.
//

import Foundation

public extension String {
    /// Estimates the token count for a given string.
    /// Assumes 1 token per 4 characters as a rough estimation.
    func estimatedTokenCount() -> Int {
        return max(1, count / 4)
    }

    /**
     Checks if the combined token count of the string and an optional context is within the allowed token limit, considering the buffer.

     - Parameters:
        - context: An optional context string to be combined with the current string.
        - tokenLimit: The maximum allowed token count (default is 1024).
        - buffer: The buffer percentage to reduce the token limit (default is 5%).

     - Returns: A Boolean value indicating whether the combined token count is within the adjusted limit.
     */
    func isWithinTokenLimit(context: String? = nil, tokenLimit: Int = 1024, buffer: Double = 0.05) -> Bool {
        let combinedString = self + (context ?? "")
        let combinedTokenCount = combinedString.estimatedTokenCount()
        let adjustedLimit = Int(floor(Double(tokenLimit) * (1 - buffer)))
        return combinedTokenCount <= adjustedLimit
    }

    /**
     Trims the string according to the specified trimming strategy.

     - Parameters:
        - strategy: The trimming strategy to use (.start, .middle, .end).
        - tokenLimit: The maximum allowed token count after trimming.
        - buffer: A buffer percentage to reduce the maximum token limit.

     - Returns: The trimmed string.
     */
    func trimmedToFit(tokenLimit: Int, buffer: Double = 0.05, strategy: TrimmingStrategy) -> String {
        guard strategy != .none else { return self }
        
        let adjustedLimit = Int(Double(tokenLimit) * (1 - buffer))
        let currentTokens = estimatedTokenCount()
        
        guard currentTokens > adjustedLimit else { return self }
        
        // Calculate target character count upfront to avoid iterative trimming
        let targetChars = adjustedLimit * 4
        
        switch strategy {
        case .start:
            let dropCount = max(0, count - targetChars)
            return String(dropFirst(dropCount))
        case .end:
            let dropCount = max(0, count - targetChars)
            return String(dropLast(dropCount))
        case .middle:
            let dropCount = max(0, count - targetChars)
            let dropFromEachSide = dropCount / 2
            let startIndex = index(startIndex, offsetBy: dropFromEachSide)
            let endIndex = index(endIndex, offsetBy: -dropFromEachSide)
            return String(self[startIndex..<endIndex])
        case .none:
            return self
        }
    }

    /// Enum defining trimming strategies.
    enum TrimmingStrategy: CustomStringConvertible {
        case start
        case middle
        case end
        case none

        public var description: String {
            switch self {
            case .start: return "start"
            case .middle: return "middle"
            case .end: return "end"
            case .none: return "none"
            }
        }
    }
}
