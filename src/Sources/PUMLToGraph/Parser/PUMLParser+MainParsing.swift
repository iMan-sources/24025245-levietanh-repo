import Foundation

// MARK: - Main Parsing Extension

extension PUMLParser {
    /// Parse PUML content into structured data.
    ///
    /// This is the main entry point for parsing PlantUML class diagrams. It processes
    /// the entire PUML file content and extracts classes, enums, interfaces, and their
    /// relationships (associations, generalizations, realizations).
    ///
    /// - Input:
    ///   - content: String - Complete PUML file content including @startuml and @enduml markers
    ///
    /// - Output:
    ///   - ParsedData structure containing:
    ///     - classes: Dictionary mapping class names to ParsedClass objects
    ///     - associations: Array of ParsedAssociation objects representing relationships
    ///     - generalizations: Array of ParsedGeneralization objects (inheritance)
    ///     - realizations: Array of ParsedRealization objects (interface implementation)
    ///     - associationClasses: Array of ParsedAssociationClass objects
    ///     - warnings: Array of warning messages from parsing
    ///
    /// - Example:
    /// ```swift
    /// let pumlContent = """
    /// @startuml
    /// class Airport {
    ///   + name : String
    ///   + code : String
    /// }
    /// class Flight {
    ///   + number : String
    /// }
    /// Airport "1" -- "*" Flight : operates >
    /// @enduml
    /// """
    /// let parser = PUMLParser()
    /// let parsedData = try parser.parserPUML(content: pumlContent)
    /// print("Found \(parsedData.classes.count) classes")
    /// ```
    ///
    /// - Throws: ParserError if critical parsing errors occur
    public func parserPUML(content: String) throws -> ParsedData {
        // Reset state for fresh parsing
        warnings = []
        edgeCounter = 0
        
        let lines: [String] = content.components(separatedBy: .newlines)
        
        var classes: [String: ParsedClass] = [:]
        var associations: [ParsedAssociation] = []
        var generalizations: [ParsedGeneralization] = []
        var realizations: [ParsedRealization] = []
        var associationClasses: [ParsedAssociationClass] = []
        var referencedClasses: Set<String> = []
        
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Skip comments, empty lines, and directives
            if line.isEmpty || line.hasPrefix("'") || line.hasPrefix("@") {
                i += 1
                continue
            }
            
            // Parse class/enum/interface declarations
            if let _ = try? matchClassDeclaration(line) {
                let (classData, nextIdx) = try parseClassBlock(lines: lines, startIdx: i)
                if let classData = classData {
                    classes[classData.name] = classData
                }
                i = nextIdx
                continue
            }
            
            // Parse associations and relationships
            if let assoc = try? parseAssociation(line: line) {
                switch assoc {
                case .association(let a):
                    associations.append(a)
                    referencedClasses.insert(a.classA)
                    referencedClasses.insert(a.classB)
                case .generalization(let g):
                    generalizations.append(g)
                    referencedClasses.insert(g.child)
                    referencedClasses.insert(g.parent)
                case .realization(let r):
                    realizations.append(r)
                    referencedClasses.insert(r.className)
                    referencedClasses.insert(r.interfaceName)
                case .associationClass(let ac):
                    associationClasses.append(ac)
                    referencedClasses.insert(ac.classA)
                    referencedClasses.insert(ac.classB)
                    referencedClasses.insert(ac.assocClass)
                }
            }
            
            i += 1
        }
        
        // Create placeholder classes for referenced but undeclared classes
        for refClass in referencedClasses {
            if classes[refClass] == nil {
                warnings.append("Missing class declaration for '\(refClass)', creating placeholder")
                classes[refClass] = ParsedClass(
                    type: "Class",
                    name: refClass,
                    isAbstract: false,
                    isInterface: false,
                    stereotypes: [],
                    attributes: [],
                    operations: [],
                    enumLiterals: []
                )
            }
        }
        
        return ParsedData(
            classes: classes,
            associations: associations,
            generalizations: generalizations,
            realizations: realizations,
            associationClasses: associationClasses,
            warnings: warnings
        )
    }
}
