import Foundation

// MARK: - Class Parsing Extension

extension PUMLParser {
    /// Parse a class/enum/interface block from PUML content.
    ///
    /// This function orchestrates the parsing of a complete class declaration including
    /// its body with attributes, operations, and enum literals.
    ///
    /// - Input:
    ///   - lines: [String] - Array of all lines in the PUML file
    ///   - startIdx: Int - Index of the line containing the class declaration
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - ParsedClass?: Parsed class data (nil if parsing fails)
    ///     - Int: Index of the next line to parse after this block
    ///
    /// - Example:
    /// ```swift
    /// // Given lines containing:
    /// // "class Airport {"
    /// // "  + name : String"
    /// // "}"
    /// let (parsedClass, nextIdx) = try parseClassBlock(lines: lines, startIdx: 0)
    /// // parsedClass.name == "Airport"
    /// // nextIdx == 3
    /// ```
    ///
    /// - Throws: ParserError if critical parsing errors occur
    internal func parseClassBlock(lines: [String], startIdx: Int) throws -> (ParsedClass?, Int) {
        let firstLine = lines[startIdx].trimmingCharacters(in: .whitespaces)
        
        // Extract class metadata (type, name, stereotypes)
        guard let metadata = extractClassMetadata(from: firstLine) else {
            return (nil, startIdx + 1)
        }
        
        // Collect all lines within the class block (between { and })
        let (blockLines, nextIdx) = collectBlockLines(from: lines, startingAt: startIdx)
        
        // Parse members (attributes, operations, enum literals)
        let members = parseClassMembers(lines: blockLines, className: metadata.name, isEnum: metadata.isEnum)
        
        let nodeType = metadata.isEnum ? "Enumeration" : "Class"
        
        let parsedClass = ParsedClass(
            type: nodeType,
            name: metadata.name,
            isAbstract: metadata.isAbstract,
            isInterface: metadata.isInterface,
            stereotypes: metadata.stereotypes,
            attributes: members.attributes,
            operations: members.operations,
            enumLiterals: members.enumLiterals
        )
        
        return (parsedClass, nextIdx)
    }
    
    /// Extract metadata from a class declaration line.
    ///
    /// - Input:
    ///   - line: String - First line of class declaration (e.g., "abstract class MyClass <<stereotype>>")
    ///
    /// - Output:
    ///   - ClassMetadata? containing:
    ///     - name: String - Class name
    ///     - isAbstract: Bool - Whether class is abstract
    ///     - isInterface: Bool - Whether this is an interface
    ///     - isEnum: Bool - Whether this is an enumeration
    ///     - stereotypes: [String] - Array of stereotype strings
    ///   - Returns nil if the line cannot be parsed as a class declaration
    ///
    /// - Example:
    /// ```swift
    /// let metadata = extractClassMetadata(from: "abstract class Vehicle <<entity>>")
    /// // metadata.name == "Vehicle"
    /// // metadata.isAbstract == true
    /// // metadata.stereotypes == ["entity"]
    /// ```
    private func extractClassMetadata(from line: String) -> ClassMetadata? {
        // Determine type flags
        let isAbstract = line.contains("abstract")
        let isInterface = line.contains("interface")
        let isEnum = line.contains("enum")
        
        // Extract name using regex
        guard let name = matchClassName(line: line) else {
            return nil
        }
        
        // Extract stereotypes
        let stereotypes = extractStereotypes(from: line)
        
        return ClassMetadata(
            name: name,
            isAbstract: isAbstract,
            isInterface: isInterface,
            isEnum: isEnum,
            stereotypes: stereotypes
        )
    }
    
    /// Collect all lines within a class block by tracking brace matching.
    ///
    /// - Input:
    ///   - lines: [String] - Array of all lines in the PUML file
    ///   - startIdx: Int - Index of the line containing the class declaration
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - [String]: Array of lines inside the class block (content between { and })
    ///     - Int: Index of the line after the closing brace
    ///
    /// - Example:
    /// ```swift
    /// // Given lines: ["class A {", "  + x : Int", "}", "class B {"]
    /// let (blockLines, nextIdx) = collectBlockLines(from: lines, startingAt: 0)
    /// // blockLines == ["  + x : Int"]
    /// // nextIdx == 3
    /// ```
    private func collectBlockLines(from lines: [String], startingAt startIdx: Int) -> ([String], Int) {
        let firstLine = lines[startIdx].trimmingCharacters(in: .whitespaces)
        
        var braceCount = countBraces(in: firstLine).opening - countBraces(in: firstLine).closing
        var idx = startIdx + 1
        var blockLines: [String] = []
        
        // Check if there's content on the same line as opening brace
        if let openBraceIdx = firstLine.firstIndex(of: "{") {
            if let closeBraceIdx = firstLine.lastIndex(of: "}"), openBraceIdx < closeBraceIdx {
                // Both braces on same line
                let content = String(firstLine[firstLine.index(after: openBraceIdx)..<closeBraceIdx])
                if !content.trimmingCharacters(in: .whitespaces).isEmpty {
                    blockLines.append(content)
                }
                braceCount = 0
            } else {
                // Opening brace found, extract content after it
                let content = String(firstLine[firstLine.index(after: openBraceIdx)...])
                if !content.trimmingCharacters(in: .whitespaces).isEmpty {
                    blockLines.append(content)
                }
                braceCount = 1
            }
        }
        
        // Collect lines until closing brace
        while idx < lines.count && braceCount > 0 {
            let line = lines[idx]
            if let closeBraceIdx = line.firstIndex(of: "}"), braceCount == 1 {
                // Extract content before closing brace
                let content = String(line[..<closeBraceIdx])
                if !content.trimmingCharacters(in: .whitespaces).isEmpty {
                    blockLines.append(content)
                }
                braceCount = 0
            } else {
                let braces = countBraces(in: line)
                braceCount += braces.opening - braces.closing
                if braceCount > 0 {
                    blockLines.append(line)
                }
            }
            idx += 1
        }
        
        return (blockLines, idx)
    }
    
    /// Parse class members (attributes, operations, enum literals) from block lines.
    ///
    /// - Input:
    ///   - lines: [String] - Lines inside the class block
    ///   - className: String - Name of the owning class
    ///   - isEnum: Bool - Whether this is an enumeration
    ///
    /// - Output:
    ///   - ClassMembers structure containing:
    ///     - attributes: [ParsedAttribute] - Array of parsed attributes
    ///     - operations: [ParsedOperation] - Array of parsed operations/methods
    ///     - enumLiterals: [ParsedEnumLiteral] - Array of enum literals (empty if not enum)
    ///
    /// - Example:
    /// ```swift
    /// let lines = ["+ name : String", "+ getName() : String"]
    /// let members = parseClassMembers(lines: lines, className: "Person", isEnum: false)
    /// // members.attributes.count == 1
    /// // members.operations.count == 1
    /// ```
    private func parseClassMembers(lines: [String], className: String, isEnum: Bool) -> ClassMembers {
        var attributes: [ParsedAttribute] = []
        var operations: [ParsedOperation] = []
        var enumLiterals: [ParsedEnumLiteral] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("'") {
                continue
            }
            
            if isEnum {
                // Enum literal or operation
                if trimmedLine.contains("(") && trimmedLine.contains(")") {
                    if let op = try? parseOperation(line: trimmedLine, owner: className) {
                        operations.append(op)
                    }
                } else {
                    // Simple enum literal
                    let litName = trimmedLine.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
                    if !litName.isEmpty {
                        enumLiterals.append(ParsedEnumLiteral(
                            id: "\(litName)@\(className)",
                            name: litName,
                            enumName: className
                        ))
                    }
                }
            } else {
                // Attribute or operation
                if trimmedLine.contains("(") && trimmedLine.contains(")") {
                    if let op = try? parseOperation(line: trimmedLine, owner: className) {
                        operations.append(op)
                    }
                } else {
                    if let attr = try? parseAttribute(line: trimmedLine, owner: className) {
                        attributes.append(attr)
                    }
                }
            }
        }
        
        return ClassMembers(
            attributes: attributes,
            operations: operations,
            enumLiterals: enumLiterals
        )
    }
}

// MARK: - Helper Structures

/// Metadata extracted from a class declaration line.
private struct ClassMetadata {
    let name: String
    let isAbstract: Bool
    let isInterface: Bool
    let isEnum: Bool
    let stereotypes: [String]
}

/// Members parsed from a class block.
private struct ClassMembers {
    let attributes: [ParsedAttribute]
    let operations: [ParsedOperation]
    let enumLiterals: [ParsedEnumLiteral]
}
