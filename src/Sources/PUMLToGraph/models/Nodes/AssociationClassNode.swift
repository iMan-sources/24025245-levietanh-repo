//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

// MARK: - Association Class Node

/// Represents an Association Class node
/// An association class is a special class that acts as an association between two other classes
public struct AssociationClassNodeData: NodeData {
    /// Node identifier (same as class name)
    public let id: String
    
    /// Class name
    public let name: String
    
    /// The two classes this association connects
    public var associationBetween: [String]
    
    /// Whether this is an abstract class
    public var isAbstract: Bool
    
    /// Whether this is an interface
    public var isInterface: Bool
    
    /// List of stereotypes
    public var stereotypes: [String]
    
    /// Semantic description
    public var semanticDesc: String
    
    /// Node type (always .associationClass)
    public var nodeType: NodeType {
        return .associationClass
    }
    
    public init(id: String, name: String, associationBetween: [String] = [], isAbstract: Bool = false, isInterface: Bool = false, stereotypes: [String] = [], semanticDesc: String = "") {
        self.id = id
        self.name = name
        self.associationBetween = associationBetween
        self.isAbstract = isAbstract
        self.isInterface = isInterface
        self.stereotypes = stereotypes
        self.semanticDesc = semanticDesc
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": nodeType.rawValue,
            "name": name,
            "associationBetween": associationBetween,
            "isAbstract": isAbstract,
            "isInterface": isInterface,
            "stereotypes": stereotypes,
            "semantic_desc": semanticDesc
        ]
    }
}
