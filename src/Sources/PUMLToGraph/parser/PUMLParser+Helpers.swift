import Foundation

// MARK: - Helper Functions Extension

extension PUMLParser {
    /// Parse visibility modifier from the beginning of a line.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "+ name : String")
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - String? - Visibility symbol ("+", "-", "#", "~") or nil if not present
    ///     - String - Remaining line after visibility is removed
    ///
    /// - Example:
    /// ```swift
    /// let (vis, remaining) = parseVisibility(line: "+ name : String")
    /// // vis == "+"
    /// // remaining == "name : String"
    /// ```
    internal func parseVisibility(line: String) -> (String?, String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("+") {
            return ("+", String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
        } else if trimmed.hasPrefix("-") {
            return ("-", String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
        } else if trimmed.hasPrefix("#") {
            return ("#", String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
        } else if trimmed.hasPrefix("~") {
            return ("~", String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
        }
        return (nil, trimmed)
    }
    
    /// Parse derived indicator (/) from the beginning of a line.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "/ age : Int")
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - Bool - True if line starts with "/", false otherwise
    ///     - String - Remaining line after "/" is removed
    ///
    /// - Example:
    /// ```swift
    /// let (isDerived, remaining) = parseDerived(line: "/ age : Int")
    /// // isDerived == true
    /// // remaining == "age : Int"
    /// ```
    internal func parseDerived(line: String) -> (Bool, String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("/") {
            return (true, String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces))
        }
        return (false, trimmed)
    }
    
    /// Extract stereotypes from a line containing <<stereotype>> notation.
    ///
    /// - Input:
    ///   - line: String - Line containing stereotypes (e.g., "class User <<entity, aggregate>>")
    ///
    /// - Output:
    ///   - [String]: Array of stereotype strings
    ///   - Returns empty array if no stereotypes found
    ///
    /// - Example:
    /// ```swift
    /// let stereotypes = extractStereotypes(from: "class User <<entity, aggregate>>")
    /// // stereotypes == ["entity", "aggregate"]
    /// ```
    internal func extractStereotypes(from line: String) -> [String] {
        guard let range = line.range(of: "<<(.+?)>>", options: .regularExpression) else {
            return []
        }
        let match = String(line[range])
        let content = match.dropFirst(2).dropLast(2)
        return content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    /// Extract properties from a line containing {property} notation.
    ///
    /// Properties can be simple flags or key-value pairs.
    ///
    /// - Input:
    ///   - line: String - Line containing properties (e.g., "name : String {readOnly, maxLength=50}")
    ///
    /// - Output:
    ///   - Optional tuple containing:
    ///     - properties: [String: Any] - Dictionary of properties
    ///       - Simple flags are stored as key: true
    ///       - Key-value pairs are stored as key: value
    ///     - withoutProperties: String - Line with properties removed
    ///   - Returns nil if no properties found
    ///
    /// - Example:
    /// ```swift
    /// let result = extractProperties(from: "name : String {readOnly, maxLength=50}")
    /// // result.properties == ["readOnly": true, "maxLength": "50"]
    /// // result.withoutProperties == "name : String"
    /// ```
    internal func extractProperties(from line: String) -> (properties: [String: Any], withoutProperties: String)? {
        guard let range = line.range(of: "\\{(.+?)\\}", options: .regularExpression) else {
            return nil
        }
        
        let match = String(line[range])
        let content = match.dropFirst().dropLast()
        var properties: [String: Any] = [:]
        
        for prop in content.components(separatedBy: ",") {
            let trimmed = prop.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("=") {
                let parts = trimmed.components(separatedBy: "=")
                properties[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            } else {
                properties[trimmed] = true
            }
        }
        
        let withoutProps = line.replacingOccurrences(of: match, with: "").trimmingCharacters(in: .whitespaces)
        return (properties, withoutProps)
    }
    
    /// Count opening and closing braces in a line.
    ///
    /// - Input:
    ///   - line: String - Line to analyze
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - opening: Int - Count of "{" characters
    ///     - closing: Int - Count of "}" characters
    ///
    /// - Example:
    /// ```swift
    /// let braces = countBraces(in: "class A { int x; }")
    /// // braces.opening == 1
    /// // braces.closing == 1
    /// ```
    internal func countBraces(in line: String) -> (opening: Int, closing: Int) {
        let opening = line.filter { $0 == "{" }.count
        let closing = line.filter { $0 == "}" }.count
        return (opening, closing)
    }
    
    /// Normalize multiplicity notation to standard "min..max" format.
    ///
    /// Transformations:
    /// - "*" → "0..*"
    /// - "5" → "5..5"
    /// - "0..5" → "0..5" (unchanged)
    /// - nil or empty → "0..*"
    /// - Invalid formats → "0..*" (with warning)
    ///
    /// - Input:
    ///   - mult: String? - Multiplicity string to normalize
    ///
    /// - Output:
    ///   - String: Normalized multiplicity in "min..max" format
    ///
    /// - Example:
    /// ```swift
    /// let mult1 = normalizeMultiplicity("*")     // "0..*"
    /// let mult2 = normalizeMultiplicity("5")     // "5..5"
    /// let mult3 = normalizeMultiplicity("1..5")  // "1..5"
    /// let mult4 = normalizeMultiplicity(nil)     // "0..*"
    /// ```
    public func normalizeMultiplicity(_ mult: String?) -> String {
        guard let mult = mult, !mult.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "0..*"
        }
        
        let trimmed = mult.trimmingCharacters(in: .whitespaces)
        
        // "*" means unbounded (0..*)
        if trimmed == "*" {
            return "0..*"
        }
        
        // Single number means exact count (n..n)
        if trimmed.allSatisfy({ $0.isNumber }) {
            return "\(trimmed)..\(trimmed)"
        }
        
        // Already in range format
        if trimmed.contains("..") {
            return trimmed
        }
        
        // Invalid format, log warning and default to 0..*
        warnings.append("Invalid multiplicity '\(mult)', defaulting to '0..*'")
        return "0..*"
    }
}
