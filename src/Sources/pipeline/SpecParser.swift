import Foundation

// MARK: - Domain Models

/// Represents a single specification with its natural language description and optional OCL constraint
public struct Specification: Identifiable {
    /// Unique identifier for the specification
    public let id: UUID
    
    /// Name of the domain this specification belongs to
    public let domainName: String
    
    /// Natural language description of the specification
    public let naturalLanguage: String
    
    /// OCL constraint string, or nil if the specification is marked as "NA"
    public let oclConstraint: String?
    
    public init(id: UUID = UUID(), domainName: String, naturalLanguage: String, oclConstraint: String?) {
        self.id = id
        self.domainName = domainName
        self.naturalLanguage = naturalLanguage
        self.oclConstraint = oclConstraint
    }
}

/// Groups specifications by domain
public struct SpecDomain {
    /// Name of the domain
    public let name: String
    
    /// List of specifications for this domain
    public let specifications: [Specification]
    
    public init(name: String, specifications: [Specification]) {
        self.name = name
        self.specifications = specifications
    }
}

/// Convenience wrapper for a collection of spec domains with utility methods
public struct SpecCollection {
    /// All spec domains
    public let domains: [SpecDomain]
    
    public init(domains: [SpecDomain]) {
        self.domains = domains
    }
    
    /// Returns all specifications that have an OCL constraint (non-nil)
    public func allWithOCL() -> [Specification] {
        return domains.flatMap { $0.specifications.filter { $0.oclConstraint != nil } }
    }
    
    /// Finds a domain by name
    public func domain(named name: String) -> SpecDomain? {
        return domains.first { $0.name == name }
    }
    
    /// Returns all specifications across all domains
    public func allSpecifications() -> [Specification] {
        return domains.flatMap { $0.specifications }
    }
}

// MARK: - Error Types

/// Errors that can occur during spec parsing
public enum SpecParserError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case decodingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Specification file not found at path: \(path)"
        case .invalidFormat(let message):
            return "Invalid file format: \(message)"
        case .decodingFailed(let message):
            return "Failed to decode JSON: \(message)"
        }
    }
}

// MARK: - Raw JSON Structures

/// Intermediate structure matching the JSON format exactly
private struct RawSpecDomain: Decodable {
    let specifications: [String: String]
}

/// Type alias for the raw JSON file structure
private typealias RawSpecFile = [String: RawSpecDomain]

// MARK: - SpecParser

/// Parser for reading and parsing specification JSON files
public struct SpecParser {
    
    public init() {}
    
    /// Parses a specification file from the given file path
    ///
    /// - Parameter path: Absolute or relative path to the specification JSON file
    /// - Returns: Array of `SpecDomain` objects containing parsed specifications
    /// - Throws: `SpecParserError` if the file cannot be read or parsed
    public func parse(fromFilePath path: String) throws -> [SpecDomain] {
        // Check if file exists
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else {
            throw SpecParserError.fileNotFound(path)
        }
        
        // Read file data
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw SpecParserError.fileNotFound("\(path): \(error.localizedDescription)")
        }
        
        // Decode JSON
        let decoder = JSONDecoder()
        let rawSpecFile: RawSpecFile
        do {
            rawSpecFile = try decoder.decode(RawSpecFile.self, from: data)
        } catch {
            throw SpecParserError.decodingFailed(error.localizedDescription)
        }
        
        // Map to domain objects
        var domains: [SpecDomain] = []
        
        for (domainName, rawDomain) in rawSpecFile {
            var specifications: [Specification] = []
            
            for (naturalLanguage, oclOrNA) in rawDomain.specifications {
                // Map "NA" to nil, otherwise use the OCL string
                let oclConstraint = oclOrNA == "NA" ? nil : oclOrNA
                
                let spec = Specification(
                    domainName: domainName,
                    naturalLanguage: naturalLanguage,
                    oclConstraint: oclConstraint
                )
                specifications.append(spec)
            }
            
            let domain = SpecDomain(name: domainName, specifications: specifications)
            domains.append(domain)
        }
        
        return domains
    }
    
    /// Parses the default specification file located at `resources/specs/specification.json`
    /// relative to the Sources directory
    ///
    /// - Returns: Array of `SpecDomain` objects containing parsed specifications
    /// - Throws: `SpecParserError` if the file cannot be found or parsed
    public func parseDefaultSpecFile() throws -> [SpecDomain] {
        // Use the same pattern as main.swift for path resolution
        // SpecParser.swift is in pipeline/, so we need to go up one level to Sources/
        let currentFile = #file
        let currentDir = (currentFile as NSString).deletingLastPathComponent // pipeline/
        let sourcesDir = (currentDir as NSString).deletingLastPathComponent // Sources/
        let specPath = (sourcesDir as NSString).appendingPathComponent("resources/specs/specification.json")
        
        return try parse(fromFilePath: specPath)
    }
}
