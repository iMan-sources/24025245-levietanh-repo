import Foundation

// MARK: - Relationship Parsing Extension

extension PUMLParser {
    /// Result type for association parsing that can represent different relationship types.
    enum AssociationResult {
        case association(ParsedAssociation)
        case generalization(ParsedGeneralization)
        case realization(ParsedRealization)
        case associationClass(ParsedAssociationClass)
    }
    
    /// Parse an association or relationship line.
    ///
    /// This function identifies and parses different types of UML relationships:
    /// - Association: A -- B, A --> B, A o-- B, A *-- B
    /// - Generalization (inheritance): A --|> B or B <|-- A
    /// - Realization (interface): A ..|> B
    /// - Association Class: (A, B) .. ClassName
    ///
    /// - Input:
    ///   - line: String - Raw relationship line from PUML
    ///
    /// - Output:
    ///   - AssociationResult enum containing one of:
    ///     - .association(ParsedAssociation): Regular association with navigability, aggregation, roles
    ///     - .generalization(ParsedGeneralization): Inheritance relationship (child -> parent)
    ///     - .realization(ParsedRealization): Interface implementation
    ///     - .associationClass(ParsedAssociationClass): Association class pattern
    ///
    /// - Example:
    /// ```swift
    /// let result = try parseAssociation(line: "Airport \"1\" --> \"*\" Flight")
    /// if case .association(let assoc) = result {
    ///   // assoc.classA == "Airport"
    ///   // assoc.navigability == "src→dst"
    /// }
    /// ```
    ///
    /// - Throws: ParserError.invalidAssociation if the line doesn't match any relationship pattern
    internal func parseAssociation(line: String) throws -> AssociationResult {
        var processedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Remove inline comments
        if let commentIdx = processedLine.range(of: "//") {
            processedLine = String(processedLine[..<commentIdx.lowerBound])
        }
        
        // Check for association class pattern: (A, B) .. ClassName
        if let assocClassMatch = matchAssociationClass(line: processedLine) {
            return .associationClass(assocClassMatch)
        }
        
        // Check for generalization (inheritance): A --|> B or B <|-- A
        if let genMatch = matchGeneralization(line: processedLine) {
            return .generalization(genMatch)
        }
        
        // Check for realization (interface implementation): A ..|> B
        if let realMatch = matchRealization(line: processedLine) {
            return .realization(realMatch)
        }
        
        // Parse regular association with navigability and aggregation
        if let assocMatch = matchAssociation(line: processedLine) {
            let edgeId = "e\(edgeCounter)"
            edgeCounter += 1
            return .association(assocMatch.withId(edgeId))
        }
        
        throw ParserError.invalidAssociation
    }
    
    /// Match and parse an association class declaration.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "(Airport, Flight) .. Booking")
    ///
    /// - Output:
    ///   - ParsedAssociationClass? containing:
    ///     - classA: First class in the association
    ///     - classB: Second class in the association
    ///     - assocClass: Name of the association class
    ///   - Returns nil if pattern doesn't match
    ///
    /// - Example:
    /// ```swift
    /// let ac = matchAssociationClass(line: "(Person, Company) .. Employment")
    /// // ac.classA == "Person"
    /// // ac.classB == "Company"
    /// // ac.assocClass == "Employment"
    /// ```
    private func matchAssociationClass(line: String) -> ParsedAssociationClass? {
        let pattern = "\\((\\w+)\\s*,\\s*(\\w+)\\)\\s*\\.\\.\\s*(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        
        return ParsedAssociationClass(
            classA: nsString.substring(with: match.range(at: 1)),
            classB: nsString.substring(with: match.range(at: 2)),
            assocClass: nsString.substring(with: match.range(at: 3))
        )
    }
    
    /// Match and parse a generalization (inheritance) relationship.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "Car --|> Vehicle" or "Vehicle <|-- Car")
    ///
    /// - Output:
    ///   - ParsedGeneralization? containing:
    ///     - child: Name of the child/subclass
    ///     - parent: Name of the parent/superclass
    ///   - Returns nil if pattern doesn't match
    ///
    /// - Example:
    /// ```swift
    /// let gen = matchGeneralization(line: "Dog --|> Animal")
    /// // gen.child == "Dog"
    /// // gen.parent == "Animal"
    /// ```
    private func matchGeneralization(line: String) -> ParsedGeneralization? {
        // Pattern: A --|> B (A inherits from B)
        if line.contains("--|>") {
            let parts = line.components(separatedBy: "--|>")
            if parts.count == 2 {
                return ParsedGeneralization(
                    child: parts[0].trimmingCharacters(in: .whitespaces),
                    parent: parts[1].trimmingCharacters(in: .whitespaces)
                )
            }
        }
        
        // Pattern: B <|-- A (A inherits from B, reversed notation)
        if line.contains("<|--") {
            let parts = line.components(separatedBy: "<|--")
            if parts.count == 2 {
                return ParsedGeneralization(
                    child: parts[1].trimmingCharacters(in: .whitespaces),
                    parent: parts[0].trimmingCharacters(in: .whitespaces)
                )
            }
        }
        
        return nil
    }
    
    /// Match and parse a realization (interface implementation) relationship.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "ArrayList ..|> List")
    ///
    /// - Output:
    ///   - ParsedRealization? containing:
    ///     - className: Name of the implementing class
    ///     - interfaceName: Name of the interface
    ///   - Returns nil if pattern doesn't match
    ///
    /// - Example:
    /// ```swift
    /// let real = matchRealization(line: "HashMap ..|> Map")
    /// // real.className == "HashMap"
    /// // real.interfaceName == "Map"
    /// ```
    private func matchRealization(line: String) -> ParsedRealization? {
        if line.contains("..|>") {
            let parts = line.components(separatedBy: "..|>")
            if parts.count == 2 {
                return ParsedRealization(
                    className: parts[0].trimmingCharacters(in: .whitespaces),
                    interfaceName: parts[1].trimmingCharacters(in: .whitespaces)
                )
            }
        }
        return nil
    }
    
    /// Match and parse a regular association with navigability and aggregation.
    ///
    /// - Input:
    ///   - line: String - Line to parse (e.g., "Airport \"1\" --> \"*\" Flight : operates >")
    ///
    /// - Output:
    ///   - ParsedAssociation? containing:
    ///     - id: Empty (to be assigned by caller)
    ///     - classA: Source class name
    ///     - classB: Target class name
    ///     - navigability: "bi" (bidirectional), "src→dst", or "dst→src"
    ///     - aggKind: "none", "shared" (o--), or "composite" (*--)
    ///     - roleA: Optional role name at source end
    ///     - multA: Multiplicity at source end (normalized to "x..y" format)
    ///     - roleB: Optional role name at target end
    ///     - multB: Multiplicity at target end (normalized to "x..y" format)
    ///     - label: Optional association label
    ///   - Returns nil if pattern doesn't match
    ///
    /// - Example:
    /// ```swift
    /// let assoc = matchAssociation(line: "Person \"employer 1\" -- \"employees *\" Company")
    /// // assoc.classA == "Person"
    /// // assoc.roleB == "employer"
    /// // assoc.multB == "1..1"
    /// ```
    private func matchAssociation(line: String) -> ParsedAssociation? {
        var processedLine = line
        var navigability = "bi"
        var aggKind = "none"
        
        // Extract navigability from arrow notation
        if processedLine.contains("-->") {
            navigability = "src→dst"
            processedLine = processedLine.replacingOccurrences(of: "-->", with: "--")
        } else if processedLine.contains("<--") {
            navigability = "dst→src"
            processedLine = processedLine.replacingOccurrences(of: "<--", with: "--")
        }
        
        // Extract aggregation kind from diamond notation
        if processedLine.contains("o--") || processedLine.contains("--o") {
            aggKind = "shared"
            processedLine = processedLine.replacingOccurrences(of: "o--", with: "--")
            processedLine = processedLine.replacingOccurrences(of: "--o", with: "--")
        } else if processedLine.contains("*--") || processedLine.contains("--*") {
            aggKind = "composite"
            processedLine = processedLine.replacingOccurrences(of: "*--", with: "--")
            processedLine = processedLine.replacingOccurrences(of: "--*", with: "--")
        }
        
        // Extract optional label (after colon)
        var label: String? = nil
        if processedLine.contains(":") {
            let parts = processedLine.split(separator: ":", maxSplits: 1)
            processedLine = String(parts[0])
            label = String(parts[1]).trimmingCharacters(in: .whitespaces)
        }
        
        // Parse main association pattern: A "role1 mult1" -- "role2 mult2" B
        let pattern = "(\\w+)(?:\\s+\"([^\"]+)\")?\\s*--\\s*(?:\"([^\"]+)\")?\\s*(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = processedLine as NSString
        guard let match = regex.firstMatch(in: processedLine, range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        
        let classA = nsString.substring(with: match.range(at: 1))
        let roleAStr = match.range(at: 2).location != NSNotFound ? nsString.substring(with: match.range(at: 2)) : nil
        let roleBStr = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
        let classB = nsString.substring(with: match.range(at: 4))
        
        let (roleA, multA) = parseRoleMultiplicity(roleAStr)
        let (roleB, multB) = parseRoleMultiplicity(roleBStr)
        
        return ParsedAssociation(
            id: "",  // Will be set by caller
            classA: classA,
            classB: classB,
            navigability: navigability,
            aggKind: aggKind,
            roleA: roleA,
            multA: normalizeMultiplicity(multA),
            roleB: roleB,
            multB: normalizeMultiplicity(multB),
            label: label
        )
    }
    
    /// Parse a role/multiplicity string into separate components.
    ///
    /// - Input:
    ///   - str: String? - Role and/or multiplicity string (e.g., "employees *", "1..5", "manager")
    ///
    /// - Output:
    ///   - Tuple containing:
    ///     - role: String? - Role name if present
    ///     - mult: String? - Multiplicity if present (e.g., "*", "1", "0..5")
    ///   - Returns (nil, nil) if input is nil
    ///
    /// - Example:
    /// ```swift
    /// let (role, mult) = parseRoleMultiplicity("employees *")
    /// // role == "employees"
    /// // mult == "*"
    /// 
    /// let (role2, mult2) = parseRoleMultiplicity("0..1")
    /// // role2 == nil
    /// // mult2 == "0..1"
    /// ```
    private func parseRoleMultiplicity(_ str: String?) -> (role: String?, mult: String?) {
        guard let str = str else { return (nil, nil) }
        
        let pattern = "(\\d+\\.\\.\\.?\\d+|\\d+\\.\\.\\.?\\*|\\d+|\\*)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (str.trimmingCharacters(in: .whitespaces), nil)
        }
        
        let nsString = str as NSString
        if let match = regex.firstMatch(in: str, range: NSRange(location: 0, length: nsString.length)) {
            let mult = nsString.substring(with: match.range)
            let role = str.replacingOccurrences(of: mult, with: "").trimmingCharacters(in: .whitespaces)
            return (role.isEmpty ? nil : role, mult)
        }
        
        return (str.trimmingCharacters(in: .whitespaces), nil)
    }
}
