//
//  APIKeyLoader.swift
//
//  Simple utility for loading API keys from .env file, environment variables, or SecureStorage
//

import Foundation
import AuroraCore

/// Simple loader for API keys (examples only)
/// Checks in order: .env file -> ProcessInfo environment -> SecureStorage
enum APIKeyLoader {
    private static var envVars: [String: String] = [:]
    private static var hasLoaded = false
    
    /// Loads .env file if present in project root (or working directory)
    static func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        let fileManager = FileManager.default
        var currentDir = fileManager.currentDirectoryPath
        
        // Search up to 5 directories for .env file
        for _ in 0..<5 {
            let envPath = (currentDir as NSString).appendingPathComponent(".env")
            if fileManager.fileExists(atPath: envPath) {
                loadFromFile(path: envPath)
                return
            }
            let parentDir = (currentDir as NSString).deletingLastPathComponent
            if parentDir == currentDir || parentDir == "/" {
                break
            }
            currentDir = parentDir
        }
    }
    
    private static func loadFromFile(path: String) {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return
        }
        
        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
            
            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(trimmed[trimmed.index(after: equalsIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            
            if !key.isEmpty {
                envVars[key] = value
            }
        }
    }
    
    /// Gets API key in order: .env file -> ProcessInfo environment -> SecureStorage
    /// - Parameters:
    ///   - key: The environment variable key (e.g., "OPENAI_API_KEY")
    ///   - serviceName: The service name for SecureStorage fallback (e.g., "OpenAI")
    /// - Returns: The API key value, or nil if not found in any location
    static func get(_ key: String, forService serviceName: String) -> String? {
        load()
        
        // 1. Check .env file first
        if let value = envVars[key], !value.isEmpty {
            return value
        }
        
        // 2. Check ProcessInfo environment variables
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value
        }
        
        // 3. Check SecureStorage (Keychain)
        return SecureStorage.getAPIKey(for: serviceName)
    }
}

