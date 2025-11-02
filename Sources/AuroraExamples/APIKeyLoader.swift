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
    
    /// Loads .env file from examples directory or project root
    static func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        
        let fileManager = FileManager.default
        
        // 1. Check relative to source file location (for development)
        if let sourceDir = getSourceDirectory() {
            let envPath = (sourceDir as NSString).appendingPathComponent(".env")
            if fileManager.fileExists(atPath: envPath) {
                loadFromFile(path: envPath)
                return
            }
        }
        
        // 2. Check relative to executable (for CLI runs)
        if let executablePath = Bundle.main.executablePath {
            let executableDir = (executablePath as NSString).deletingLastPathComponent
            let envPath = (executableDir as NSString).appendingPathComponent(".env")
            if fileManager.fileExists(atPath: envPath) {
                loadFromFile(path: envPath)
                return
            }
        }
        
        // 3. Check current working directory
        let currentDirEnv = (fileManager.currentDirectoryPath as NSString).appendingPathComponent(".env")
        if fileManager.fileExists(atPath: currentDirEnv) {
            loadFromFile(path: currentDirEnv)
            return
        }
        
        // 4. Find project root by looking for Package.swift, then check Sources/AuroraExamples/.env
        var currentDir = fileManager.currentDirectoryPath
        for _ in 0..<10 {
            let packagePath = (currentDir as NSString).appendingPathComponent("Package.swift")
            if fileManager.fileExists(atPath: packagePath) {
                var examplesEnvPath = (currentDir as NSString).appendingPathComponent("Sources")
                examplesEnvPath = (examplesEnvPath as NSString).appendingPathComponent("AuroraExamples")
                examplesEnvPath = (examplesEnvPath as NSString).appendingPathComponent(".env")
                if fileManager.fileExists(atPath: examplesEnvPath) {
                    loadFromFile(path: examplesEnvPath)
                    return
                }
                break
            }
            let parentDir = (currentDir as NSString).deletingLastPathComponent
            if parentDir == currentDir || parentDir == "/" {
                break
            }
            currentDir = parentDir
        }
    }
    
    /// Gets the directory containing this source file (for development)
    private static func getSourceDirectory() -> String? {
        // This file is in Sources/AuroraExamples, so find that directory
        // #file returns the path to this source file at compile time
        let filePath = #file
        let fileURL = URL(fileURLWithPath: filePath)
        return fileURL.deletingLastPathComponent().path
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
                // Inject into ProcessInfo so convenience APIs can access it
                setenv(key, value, 1)
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

