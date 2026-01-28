import Foundation

// MARK: - Regex Matching Extension

extension PUMLParser {
    /// Match a class/interface/enum declaration line.
    ///
    /// Tests if a line contains a class declaration and returns the class name if found.
    ///
    /// - Input:
    ///   - line: String - Line to test (e.g., "abstract class Vehicle", "enum Color")
    ///
    /// - Output:
    ///   - String?: Class name if the line is a class declaration, nil otherwise
    ///
    /// - Example:
    /// ```swift
    /// let name1 = try matchClassDeclaration("class Airport")
    /// // name1 == "Airport"
    /// 
    /// let name2 = try matchClassDeclaration("interface Flyable")
    /// // name2 == "Flyable"
    /// 
    /// let name3 = try matchClassDeclaration("+ name : String")
    /// // name3 == nil
    /// ```
    ///
    /// - Throws: Can throw NSRegularExpression initialization errors
    internal func matchClassDeclaration(_ line: String) throws -> String? {
        let pattern = "(class|abstract\\s+class|interface|enum)\\s+(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        return nsString.substring(with: match.range(at: 2))
    }
    
    /// Extract the class name from a class declaration line.
    ///
    /// Similar to matchClassDeclaration but focused on extracting just the name.
    ///
    /// - Input:
    ///   - line: String - Class declaration line
    ///
    /// - Output:
    ///   - String?: Extracted class name, nil if not found
    ///
    /// - Example:
    /// ```swift
    /// let name = matchClassName(line: "abstract class Vehicle")
    /// // name == "Vehicle"
    /// ```
    internal func matchClassName(line: String) -> String? {
        let pattern = "(?:class|abstract\\s+class|interface|enum)\\s+(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        return nsString.substring(with: match.range(at: 1))
    }
}
