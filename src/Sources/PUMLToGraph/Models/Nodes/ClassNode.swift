//
//  ClassNode.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//
import Foundation
// MARK: - Class Node

/// Represents a Class or Interface node in the UML diagram
///
/// Example:
///     let classNode = ClassNodeData(
///         id: "Airport",
///         name: "Airport",
///         isAbstract: false,
///         isInterface: false,
///         stereotypes: ["Entity"],
///         semanticDesc: "Class airport represents a domain entity."
///     )
public struct ClassNodeData: NodeData {
    /// Node identifier (same as class name)
    public let id: String
    
    /// Class name
    public let name: String
    
    /// Whether this is an abstract class
    public var isAbstract: Bool
    
    /// Whether this is an interface
    public var isInterface: Bool
    
    /// List of stereotypes (e.g., <<Entity>>, <<Service>>)
    public var stereotypes: [String]
    
    /// Semantic description for S-BERT vectorization
    public var semanticDesc: String
    
    /// Node type (always .classNode or .enumeration)
    public var nodeType: NodeType {
        return .classNode
    }
    
    public init(id: String, name: String,
                isAbstract: Bool = false,
                isInterface: Bool = false,
                stereotypes: [String] = [],
                semanticDesc: String = "") {
        self.id = id
        self.name = name
        self.isAbstract = isAbstract
        self.isInterface = isInterface
        self.stereotypes = stereotypes
        self.semanticDesc = semanticDesc
    }
    
    /// Convert to dictionary for graph storage
    public func toDictionary() -> [String: Any] {
        return [
            "type": nodeType.rawValue,
            "name": name,
            "isAbstract": isAbstract,
            "isInterface": isInterface,
            "stereotypes": stereotypes,
            "semantic_desc": semanticDesc
        ]
    }
}
