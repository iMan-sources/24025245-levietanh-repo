import Foundation

/// Parsed PUML data structures
///
/// Defines intermediate data structures that hold parsed PlantUML content
/// before converting to graph format. These structures correspond to the
/// dictionary format returned by PUMLParser in the Python implementation.


// MARK: - Main Parsed Data Structure

/// Complete parsed PUML data structure
///
/// This matches the Python dictionary structure returned by parse_puml():
/// {
///     'classes': {...},
///     'associations': [...],
///     'generalizations': [...],
///     'realizations': [...],
///     'associationClasses': [...],
///     'warnings': [...]
/// }
public struct ParsedData {
    /// Dictionary of classes, keyed by class name
    public var classes: [String: ParsedClass]
    
    /// List of association relationships
    public var associations: [ParsedAssociation]
    
    /// List of generalization (inheritance) relationships
    public var generalizations: [ParsedGeneralization]
    
    /// List of realization (interface implementation) relationships
    public var realizations: [ParsedRealization]
    
    /// List of association class relationships
    public var associationClasses: [ParsedAssociationClass]
    
    /// Warnings generated during parsing
    public var warnings: [String]
    
    public init(classes: [String: ParsedClass] = [:],
                associations: [ParsedAssociation] = [],
                generalizations: [ParsedGeneralization] = [],
                realizations: [ParsedRealization] = [],
                associationClasses: [ParsedAssociationClass] = [],
                warnings: [String] = []) {
        self.classes = classes
        self.associations = associations
        self.generalizations = generalizations
        self.realizations = realizations
        self.associationClasses = associationClasses
        self.warnings = warnings
    }
}

// MARK: - Parsed Class

/// Parsed class/enum/interface structure
///
/// Corresponds to Python structure:
/// {
///     'type': 'Class' | 'Enumeration',
///     'name': str,
///     'isAbstract': bool,
///     'isInterface': bool,
///     'stereotypes': [str],
///     'attributes': [...],
///     'operations': [...],
///     'enumLiterals': [...]
/// }
public struct ParsedClass {
    /// Type: "Class" or "Enumeration"
    public var type: String
    
    /// Class name
    public var name: String
    
    /// Whether this is an abstract class
    public var isAbstract: Bool
    
    /// Whether this is an interface
    public var isInterface: Bool
    
    /// List of stereotypes
    public var stereotypes: [String]
    
    /// List of attributes
    public var attributes: [ParsedAttribute]
    
    /// List of operations
    public var operations: [ParsedOperation]
    
    /// List of enum literals (for enumerations only)
    public var enumLiterals: [ParsedEnumLiteral]
    
    public init(type: String, name: String, isAbstract: Bool = false, isInterface: Bool = false, stereotypes: [String] = [], attributes: [ParsedAttribute] = [], operations: [ParsedOperation] = [], enumLiterals: [ParsedEnumLiteral] = []) {
        self.type = type
        self.name = name
        self.isAbstract = isAbstract
        self.isInterface = isInterface
        self.stereotypes = stereotypes
        self.attributes = attributes
        self.operations = operations
        self.enumLiterals = enumLiterals
    }
}

// MARK: - Parsed Attribute

/// Parsed attribute structure
///
/// Corresponds to Python structure:
/// {
///     'id': 'name@ClassName',
///     'name': str,
///     'type': str | None,
///     'visibility': str | None,
///     'isDerived': bool,
///     'owner': str,
///     'properties': {...}
/// }
public struct ParsedAttribute {
    /// Unique ID in format "name@OwnerClass"
    public var id: String
    
    /// Attribute name
    public var name: String
    
    /// Data type (nil if not specified)
    public var type: String?
    
    /// Visibility: "+", "-", "#", "~" or nil
    public var visibility: String?
    
    /// Whether this is a derived attribute
    public var isDerived: Bool
    
    /// Name of the owning class
    public var owner: String
    
    /// Additional UML properties
    public var properties: [String: Any]
    
    public init(id: String, name: String, type: String? = nil, visibility: String? = nil, isDerived: Bool = false, owner: String, properties: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.type = type
        self.visibility = visibility
        self.isDerived = isDerived
        self.owner = owner
        self.properties = properties
    }
}

// MARK: - Parsed Operation

/// Parsed operation structure
///
/// Corresponds to Python structure:
/// {
///     'id': 'name(params)@OwnerClass',
///     'name': str,
///     'params': [...],
///     'returnType': str | None,
///     'visibility': str | None,
///     'isDerived': bool,
///     'owner': str
/// }
public struct ParsedOperation {
    /// Unique ID in format "name(params)@OwnerClass"
    public var id: String
    
    /// Operation name
    public var name: String
    
    /// List of parameters
    public var params: [ParsedParameter]
    
    /// Return type (nil for void)
    public var returnType: String?
    
    /// Visibility: "+", "-", "#", "~" or nil
    public var visibility: String?
    
    /// Whether this is a derived operation
    public var isDerived: Bool
    
    /// Name of the owning class
    public var owner: String
    
    public init(id: String, name: String, params: [ParsedParameter] = [], returnType: String? = nil, visibility: String? = nil, isDerived: Bool = false, owner: String) {
        self.id = id
        self.name = name
        self.params = params
        self.returnType = returnType
        self.visibility = visibility
        self.isDerived = isDerived
        self.owner = owner
    }
}

/// Parsed parameter structure
public struct ParsedParameter {
    /// Parameter name
    public var name: String
    
    /// Parameter type (nil if not specified)
    public var type: String?
    
    public init(name: String, type: String? = nil) {
        self.name = name
        self.type = type
    }
}

// MARK: - Parsed Enum Literal

/// Parsed enum literal structure
///
/// Corresponds to Python structure:
/// {
///     'id': 'literalName@EnumName',
///     'name': str,
///     'enum': str
/// }
public struct ParsedEnumLiteral {
    /// Unique ID in format "literalName@EnumName"
    public var id: String
    
    /// Literal name
    public var name: String
    
    /// Name of the parent enumeration
    public var enumName: String
    
    public init(id: String, name: String, enumName: String) {
        self.id = id
        self.name = name
        self.enumName = enumName
    }
}

// MARK: - Parsed Association

/// Parsed association relationship
///
/// Corresponds to Python structure:
/// {
///     'type': 'association',
///     'id': 'e0',
///     'classA': str,
///     'classB': str,
///     'navigability': 'bi' | 'src→dst' | 'dst→src',
///     'aggKind': 'none' | 'shared' | 'composite',
///     'roleA': str | None,
///     'multA': str,
///     'roleB': str | None,
///     'multB': str,
///     'label': str | None
/// }
public struct ParsedAssociation {
    /// Unique edge identifier
    public var id: String
    
    /// Source class name
    public var classA: String
    
    /// Destination class name
    public var classB: String
    
    /// Navigability: "bi", "src→dst", "dst→src"
    public var navigability: String
    
    /// Aggregation kind: "none", "shared", "composite"
    public var aggKind: String
    
    /// Role name at A end
    public var roleA: String?
    
    /// Multiplicity at A end
    public var multA: String
    
    /// Role name at B end
    public var roleB: String?
    
    /// Multiplicity at B end
    public var multB: String
    
    /// Optional association label
    public var label: String?
    
    public init(id: String, classA: String, classB: String, navigability: String = "bi", aggKind: String = "none", roleA: String? = nil, multA: String = "0..*", roleB: String? = nil, multB: String = "0..*", label: String? = nil) {
        self.id = id
        self.classA = classA
        self.classB = classB
        self.navigability = navigability
        self.aggKind = aggKind
        self.roleA = roleA
        self.multA = multA
        self.roleB = roleB
        self.multB = multB
        self.label = label
    }
}

// MARK: - Parsed Generalization

/// Parsed generalization (inheritance) relationship
///
/// Corresponds to Python structure:
/// {
///     'type': 'generalization',
///     'child': str,
///     'parent': str
/// }
public struct ParsedGeneralization {
    /// Child class name (subclass)
    public var child: String
    
    /// Parent class name (superclass)
    public var parent: String
    
    public init(child: String, parent: String) {
        self.child = child
        self.parent = parent
    }
}

// MARK: - Parsed Realization

/// Parsed realization (interface implementation) relationship
///
/// Corresponds to Python structure:
/// {
///     'type': 'realization',
///     'class': str,
///     'interface': str
/// }
public struct ParsedRealization {
    /// Implementing class name
    public var className: String
    
    /// Interface name
    public var interfaceName: String
    
    public init(className: String, interfaceName: String) {
        self.className = className
        self.interfaceName = interfaceName
    }
}

// MARK: - Parsed Association Class

/// Parsed association class relationship
///
/// Corresponds to Python structure:
/// {
///     'type': 'association_class',
///     'classA': str,
///     'classB': str,
///     'assocClass': str
/// }
public struct ParsedAssociationClass {
    /// First class in association
    public var classA: String
    
    /// Second class in association
    public var classB: String
    
    /// Association class name
    public var assocClass: String
    
    public init(classA: String, classB: String, assocClass: String) {
        self.classA = classA
        self.classB = classB
        self.assocClass = assocClass
    }
}

