import Foundation

// MARK: - Member Parsing Extension

extension PUMLParser {
    /// Parse an attribute line into a structured ParsedAttribute object.
    ///
    /// Attributes follow the UML syntax: [visibility] [/] name : Type {properties}
    ///
    /// - Input:
    ///   - line: String - Raw attribute line (e.g., "+ name : String {readOnly}")
    ///   - owner: String - Name of the owning class/enum
    ///
    /// - Output:
    ///   - ParsedAttribute containing:
    ///     - id: Unique identifier in format "name@owner"
    ///     - name: Attribute name extracted from the line
    ///     - type: Optional type string (e.g., "String", "Int")
    ///     - visibility: "+", "-", "#", "~", or nil
    ///     - isDerived: Boolean indicating derived attribute (prefixed with /)
    ///     - owner: Name of the owning class
    ///     - properties: Dictionary of property constraints (e.g., {"readOnly": true})
    ///
    /// - Example:
    /// ```swift
    /// let attr = try parseAttribute(line: "+ name : String {readOnly}", owner: "Person")
    /// // attr.name == "name"
    /// // attr.type == "String"
    /// // attr.visibility == "+"
    /// // attr.properties == ["readOnly": true]
    /// ```
    ///
    /// - Throws: ParserError if the line cannot be parsed
    internal func parseAttribute(line: String, owner: String) throws -> ParsedAttribute {
        var remaining = line
        
        // Parse visibility (+, -, #, ~)
        let (visibility, afterVisibility) = parseVisibility(line: remaining)
        remaining = afterVisibility
        
        // Parse derived indicator (/)
        let (isDerived, afterDerived) = parseDerived(line: remaining)
        remaining = afterDerived
        
        // Remove inline comments (//)
        if let commentIdx = remaining.firstIndex(of: Character("/")) {
            if remaining.distance(from: commentIdx, to: remaining.endIndex) >= 2 {
                let nextIdx = remaining.index(after: commentIdx)
                if remaining[nextIdx] == Character("/") {
                    remaining = String(remaining[..<commentIdx])
                }
            }
        }
        
        remaining = remaining.trimmingCharacters(in: .whitespaces)
        
        // Extract properties enclosed in {braces}
        var properties: [String: Any] = [:]
        if let propsMatch = extractProperties(from: remaining) {
            properties = propsMatch.properties
            remaining = propsMatch.withoutProperties
        }
        
        // Parse name : type
        let components = remaining.components(separatedBy: ":")
        let name = components[0].trimmingCharacters(in: .whitespaces)
        let type = components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : nil
        
        let id = "\(name)@\(owner)"
        
        return ParsedAttribute(
            id: id,
            name: name,
            type: type,
            visibility: visibility,
            isDerived: isDerived,
            owner: owner,
            properties: properties
        )
    }
    
    /// Parse an operation line into a structured ParsedOperation object.
    ///
    /// Operations follow the UML syntax: [visibility] [/] name(param1: Type1, param2: Type2) : ReturnType
    ///
    /// - Input:
    ///   - line: String - Raw operation line (e.g., "+ calculateAge(birthYear: Int) : Int")
    ///   - owner: String - Name of the owning class
    ///
    /// - Output:
    ///   - ParsedOperation containing:
    ///     - id: Unique identifier in format "name(params)@owner"
    ///     - name: Operation name
    ///     - params: Array of ParsedParameter objects
    ///     - returnType: Optional return type string
    ///     - visibility: "+", "-", "#", "~", or nil
    ///     - isDerived: Boolean indicating derived operation
    ///     - owner: Name of the owning class
    ///
    /// - Example:
    /// ```swift
    /// let op = try parseOperation(line: "+ add(x: Int, y: Int) : Int", owner: "Calculator")
    /// // op.name == "add"
    /// // op.params.count == 2
    /// // op.returnType == "Int"
    /// ```
    ///
    /// - Throws: ParserError.invalidOperation if parentheses are missing or malformed
    internal func parseOperation(line: String, owner: String) throws -> ParsedOperation {
        var remaining = line
        
        // Parse visibility (+, -, #, ~)
        let (visibility, afterVisibility) = parseVisibility(line: remaining)
        remaining = afterVisibility
        
        // Parse derived indicator (/)
        let (isDerived, afterDerived) = parseDerived(line: remaining)
        remaining = afterDerived
        
        // Remove inline comments (//)
        if let commentIdx = remaining.range(of: "//") {
            remaining = String(remaining[..<commentIdx.lowerBound])
        }
        
        remaining = remaining.trimmingCharacters(in: .whitespaces)
        
        // Must have parentheses for method parameters
        guard let openParenIdx = remaining.firstIndex(of: "("),
              let closeParenIdx = remaining.firstIndex(of: ")") else {
            throw ParserError.invalidOperation
        }
        
        // Extract operation name
        let name = String(remaining[..<openParenIdx]).trimmingCharacters(in: .whitespaces)
        
        // Extract parameters string
        let paramsStr = String(remaining[remaining.index(after: openParenIdx)..<closeParenIdx])
        let params = parseParameters(paramsStr: paramsStr)
        
        // Extract return type (after : following the closing parenthesis)
        let afterParen = String(remaining[remaining.index(after: closeParenIdx)...])
        var returnType: String? = nil
        if let colonIdx = afterParen.firstIndex(of: ":") {
            returnType = String(afterParen[afterParen.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)
        }
        
        // Generate unique ID
        let id = paramsStr.isEmpty ? "\(name)()@\(owner)" : "\(name)(\(paramsStr))@\(owner)"
        
        return ParsedOperation(
            id: id,
            name: name,
            params: params,
            returnType: returnType,
            visibility: visibility,
            isDerived: isDerived,
            owner: owner
        )
    }
    
    /// Parse a comma-separated list of parameters.
    ///
    /// - Input:
    ///   - paramsStr: String - Parameters string without parentheses (e.g., "x: Int, y: Int")
    ///
    /// - Output:
    ///   - [ParsedParameter]: Array of ParsedParameter objects, each containing:
    ///     - name: Parameter name
    ///     - type: Optional type string
    ///   - Returns empty array if paramsStr is empty or whitespace
    ///
    /// - Example:
    /// ```swift
    /// let params = parseParameters(paramsStr: "name: String, age: Int")
    /// // params.count == 2
    /// // params[0].name == "name"
    /// // params[0].type == "String"
    /// ```
    internal func parseParameters(paramsStr: String) -> [ParsedParameter] {
        guard !paramsStr.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        return paramsStr.components(separatedBy: ",").map { param in
            let trimmed = param.trimmingCharacters(in: .whitespaces)
            let components = trimmed.components(separatedBy: ":")
            let name = components[0].trimmingCharacters(in: .whitespaces)
            let type = components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : nil
            return ParsedParameter(name: name, type: type)
        }
    }
}
