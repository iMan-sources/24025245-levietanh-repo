import Foundation

/// Parses PlantUML class diagrams into structured data.
/// This implementation corresponds to the Python PUMLParser class in puml_parser.py
///
/// Example usage:
///     let parser = PUMLParser()
///     let parsedData = try parser.parserPUML(content: pumlString)
///     print("Found \(parsedData.classes.count) classes")
///
/// The parser is split into multiple extensions for better organization:
/// - MainParsing: Entry point for parsing PUML content
/// - ClassParsing: Class, interface, and enum declaration parsing
/// - MemberParsing: Attribute and operation parsing
/// - RelationshipParsing: Association, generalization, and realization parsing
/// - Helpers: Utility functions for parsing
/// - RegexMatching: Regular expression pattern matching
public class PUMLParser {
    /// Warnings collected during parsing
    ///
    /// - Input: Automatically populated during parsing operations
    /// - Output: Array of warning messages describing non-critical issues
    internal var warnings: [String] = []
    
    /// Counter for generating unique edge IDs
    ///
    /// - Input: Initialized to 0, auto-incremented during association parsing
    /// - Output: Current edge counter value
    internal var edgeCounter: Int = 0
    
    public init() {}
}

// MARK: - Parser Errors

enum ParserError: Error {
    case invalidOperation
    case invalidAssociation
}

// MARK: - Extensions

extension ParsedAssociation {
    func withId(_ id: String) -> ParsedAssociation {
        var copy = self
        copy.id = id
        return copy
    }
}
