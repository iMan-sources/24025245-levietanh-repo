/// Semantic Text Generator
///
/// Generates natural language semantic descriptions for UML elements.
/// These descriptions are optimized for S-BERT vectorization and semantic similarity matching.
///
/// This implementation corresponds to the Python SemanticGenerator class in semantic_generator.py
///
/// Example usage:
///     let generator = SemanticGenerator()
///     let desc = generator.generateClassDesc(classData: parsedClass)

import Foundation

/// Generates semantic text descriptions for UML elements
public class SemanticGenerator {
    
    public init() {}
    
    // MARK: - Identifier Splitting
    
    /// Split camelCase and snake_case identifiers into words
    ///
    /// Examples:
    ///     "flightScheduler" → "flight scheduler"
    ///     "max_nr_passenger" → "max nr passenger"
    ///     "departTime" → "depart time"
    ///
    /// Args:
    ///     text: Input identifier
    ///
    /// Returns:
    ///     Space-separated lowercase words
    public static func splitIdentifier(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        
        var result = text
        
        // Replace underscores with spaces
        result = result.replacingOccurrences(of: "_", with: " ")
        
        // Insert space between lowercase and uppercase: aB -> a B
        result = result.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        // Insert space between multiple uppercase and lowercase: ABCd -> AB Cd
        result = result.replacingOccurrences(
            of: "([A-Z]+)([A-Z][a-z])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        return result.lowercased().trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Class Description
    
    /// Generate semantic description for a Class
    ///
    /// Pattern: "Class {ClassName} represents a domain entity."
    /// With enrichment for stereotypes/interfaces.
    ///
    /// Args:
    ///     classData: ParsedClass structure
    ///
    /// Returns:
    ///     Semantic description string
    ///
    /// Example:
    ///     "Class airport represents a domain entity."
    ///     "Class flyable represents a domain entity. It is defined as an interface."
    public func generateClassDesc(classData: ParsedClass) -> String {
        let className = Self.splitIdentifier(classData.name)
        
        // Base template
        var desc = "Class \(className) represents a domain entity."
        
        // Enrichment for stereotypes
        let stereoLower = classData.stereotypes.map { $0.lowercased() }
        
        if stereoLower.contains("interface") || classData.isInterface {
            desc += " It is defined as an interface."
        } else if stereoLower.contains("abstract") || classData.isAbstract {
            desc += " It is defined as an abstract class."
        }
        
        // Handle Enumeration type
        if classData.type == "Enumeration" && !classData.enumLiterals.isEmpty {
            let literalNames = classData.enumLiterals.map { Self.splitIdentifier($0.name) }
            desc = "\(className) is an enumeration type defined by a fixed set of values: \(literalNames.joined(separator: ", "))."
        }
        
        return desc
    }
    
    // MARK: - Attribute Description
    
    /// Generate semantic description for an Attribute
    ///
    /// Pattern: "{name} is an attribute of class {Context} with data type {Type}."
    /// With semantic enrichment based on data type.
    ///
    /// Args:
    ///     attr: ParsedAttribute structure
    ///     context: Name of the owning class
    ///
    /// Returns:
    ///     Semantic description string
    ///
    /// Example:
    ///     "name is an attribute of class airport with data type string. It represents textual information."
    ///     "depart time is an attribute of class flight with data type date. It represents a point in time."
    public func generateAttributeDesc(attr: ParsedAttribute, context: String) -> String {
        let attrName = Self.splitIdentifier(attr.name)
        let contextSplit = Self.splitIdentifier(context)
        
        // Base template
        var desc = "\(attrName) is an attribute of class \(contextSplit)"
        
        if let attrType = attr.type {
            let attrTypeSplit = Self.splitIdentifier(attrType)
            desc += " with data type \(attrTypeSplit)"
        }
        
        desc += "."
        
        // Semantic enrichment based on type
        if let attrType = attr.type {
            let typeLower = attrType.lowercased()
            
            // Numeric types
            if typeLower.contains("int") || typeLower.contains("integer") ||
                typeLower.contains("real") || typeLower.contains("float") ||
                typeLower.contains("double") || typeLower.contains("number") ||
                typeLower.contains("numeric") {
                desc += " It represents a numeric value used for calculation."
            }
            // Boolean types
            else if typeLower.contains("bool") {
                desc += " It represents a logical state or flag."
            }
            // Date/Time types
            else if typeLower.contains("date") || typeLower.contains("time") ||
                        typeLower.contains("datetime") || typeLower.contains("timestamp") {
                desc += " It represents a point in time."
            }
            // String types
            else if typeLower.contains("string") || typeLower.contains("str") ||
                        typeLower.contains("text") {
                desc += " It represents textual information."
            }
            
            // ID fields (heuristic: check if name contains id/key/code)
            let nameLower = attr.name.lowercased()
            if nameLower.contains("id") || nameLower.contains("key") ||
                nameLower.contains("code") {
                desc += " It is used for unique identification."
            }
        }
        
        return desc
    }
    
    // MARK: - Operation Description
    
    /// Generate semantic description for an Operation
    ///
    /// Pattern: "{name} is an operation of class {Context} that accepts inputs {params} and returns {ReturnType}."
    /// With enrichment for Boolean/Void return types.
    ///
    /// Args:
    ///     op: ParsedOperation structure
    ///     context: Name of the owning class
    ///
    /// Returns:
    ///     Semantic description string
    ///
    /// Example:
    ///     "book is an operation of class passenger that accepts inputs f of type flight and returns boolean. It checks a condition or validates a rule."
    public func generateOperationDesc(op: ParsedOperation, context: String) -> String {
        let opName = Self.splitIdentifier(op.name)
        let contextSplit = Self.splitIdentifier(context)
        
        // Format parameters
        var paramStrs: [String] = []
        for param in op.params {
            let paramName = Self.splitIdentifier(param.name)
            if let paramType = param.type {
                let paramTypeSplit = Self.splitIdentifier(paramType)
                paramStrs.append("\(paramName) of type \(paramTypeSplit)")
            } else {
                paramStrs.append(paramName)
            }
        }
        
        let paramsText = paramStrs.isEmpty ? "no inputs" : paramStrs.joined(separator: ", ")
        
        // Base template
        var desc = "\(opName) is an operation of class \(contextSplit) that accepts inputs \(paramsText)"
        
        if let returnType = op.returnType {
            let returnTypeSplit = Self.splitIdentifier(returnType)
            desc += " and returns \(returnTypeSplit)"
        } else {
            desc += " and returns void"
        }
        
        desc += "."
        
        // Enrichment based on return type
        if let returnType = op.returnType {
            let returnTypeLower = returnType.lowercased()
            if returnTypeLower.contains("bool") {
                desc += " It checks a condition or validates a rule."
            }
        } else {
            // Void or no return type
            desc += " It performs an action or state change."
        }
        
        return desc
    }
    
    // MARK: - Generalization Description
    
    /// Generate semantic description for a Generalization relationship
    ///
    /// Pattern: "{Child} is a specific type of {Parent} and inherits all its attributes and operations."
    ///
    /// Args:
    ///     child: Name of child class
    ///     parent: Name of parent class
    ///
    /// Returns:
    ///     Semantic description string
    ///
    /// Example:
    ///     "passenger plane is a specific type of aircraft and inherits all its attributes and operations."
    public func generateGeneralizationDesc(child: String, parent: String) -> String {
        let childSplit = Self.splitIdentifier(child)
        let parentSplit = Self.splitIdentifier(parent)
        
        return "\(childSplit) is a specific type of \(parentSplit) and inherits all its attributes and operations."
    }
    
    // MARK: - Association Description
    
    /// Generate semantic description for an Association relationship
    ///
    /// Pattern: "Class {Source} {Verb Phrase} {Quantifier} {Target} objects through role {RoleName}."
    ///
    /// Args:
    ///     assoc: ParsedAssociation structure
    ///     source: Source class name
    ///     target: Target class name
    ///     roleName: Role name (if any)
    ///     multiplicity: Multiplicity string (e.g., "1", "0..1", "*", "1..*")
    ///     isReverse: Whether this is the reverse direction of a bidirectional association
    ///
    /// Returns:
    ///     Semantic description string
    ///
    /// Example:
    ///     "Class airport is associated with a collection of multiple flight objects through role origin."
    public func generateAssociationDesc(assoc: ParsedAssociation, source: String, target: String, roleName: String?, multiplicity: String, isReverse: Bool) -> String {
        let sourceSplit = Self.splitIdentifier(source)
        let targetSplit = Self.splitIdentifier(target)
        
        // Determine verb phrase
        let verbPhrase = getVerbPhrase(assoc: assoc, isReverse: isReverse)
        
        // Determine quantifier based on multiplicity
        let quantifier = getQuantifier(multiplicity: multiplicity)
        
        // Format role name
        let roleText: String
        if let roleName = roleName {
            let roleSplit = Self.splitIdentifier(roleName)
            roleText = " through role \(roleSplit)"
        } else {
            roleText = " through an unnamed role"
        }
        
        return "Class \(sourceSplit) \(verbPhrase) \(quantifier) \(targetSplit) objects\(roleText)."
    }
    
    // MARK: - Helper Methods
    
    /// Determine the verb phrase for an association
    ///
    /// Priority:
    /// 1. Label on edge (if present)
    /// 2. Aggregation: "has an aggregation of" or "is aggregated by"
    /// 3. Composition: "contains" or "is composed of"
    /// 4. Default: "is associated with"
    private func getVerbPhrase(assoc: ParsedAssociation, isReverse: Bool) -> String {
        // Check for label
        if let label = assoc.label {
            return Self.splitIdentifier(label)
        }
        
        // Check aggregation kind
        let aggKind = assoc.aggKind
        
        if aggKind == "composite" {
            return isReverse ? "is composed of" : "contains"
        } else if aggKind == "shared" {
            return isReverse ? "is aggregated by" : "has an aggregation of"
        } else {
            // Default association
            return "is associated with"
        }
    }
    
    /// Convert multiplicity to quantifier phrase
    ///
    /// Rules:
    /// - "0..1" or "1" → "a single"
    /// - "*", "0..*", "1..*" → "a collection of multiple"
    private func getQuantifier(multiplicity: String) -> String {
        let mult = multiplicity.trimmingCharacters(in: .whitespaces)
        
        // Single or optional
        if mult == "1" || mult == "1..1" || mult == "0..1" {
            return "a single"
        }
        
        // Multiple (any form of *)
        if mult.contains("*") || mult.contains("..*") {
            return "a collection of multiple"
        }
        
        // Check if it's a range like "2..5" - treat as collection
        if mult.contains("..") {
            return "a collection of multiple"
        }
        
        // Single number > 1 - still treat as collection
        if let num = Int(mult), num > 1 {
            return "a collection of multiple"
        }
        
        // Default to single
        return "a single"
    }
}

