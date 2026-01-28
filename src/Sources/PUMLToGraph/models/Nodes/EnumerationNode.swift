//
//  EnumerationNode.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation
// MARK: - Enumeration Node

/// Represents an Enumeration node in the UML diagram
public struct EnumerationNodeData: NodeData {
    /// Node identifier (same as enum name)
    public let id: String
    
    /// Enumeration name
    public let name: String
    
    /// List of stereotypes
    public var stereotypes: [String]
    
    /// Semantic description
    public var semanticDesc: String
    
    /// Normalized text components for multi-vector mode (each component is a separate sentence)
    /// Components include: core identity, subtypes (if any), and each association
    public var normalizedText: [String]
    
    /// Node type (always .enumeration)
    public var nodeType: NodeType {
        return .enumeration
    }
    
    public init(id: String, name: String, stereotypes: [String] = [], semanticDesc: String = "", normalizedText: [String] = []) {
        self.id = id
        self.name = name
        self.stereotypes = stereotypes
        self.semanticDesc = semanticDesc
        self.normalizedText = normalizedText
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": nodeType.rawValue,
            "name": name,
            "stereotypes": stereotypes,
            "semantic_desc": semanticDesc,
            "normalized_text": normalizedText
        ]
    }
}

// MARK: - Enum Literal Node

/// Represents an enumeration literal (enum value) node
///
/// Example:
///     let literal = EnumLiteralNodeData(
///         id: "NEW@Status",
///         name: "NEW",
///         enumName: "Status"
///     )
public struct EnumLiteralNodeData: NodeData {
    /// Unique identifier in format "literalName@EnumName"
    public let id: String
    
    /// Literal name
    public let name: String
    
    /// Name of the parent enumeration
    public let enumName: String
    
    /// Node type (always .enumLiteral)
    public var nodeType: NodeType {
        return .enumLiteral
    }
    
    public init(id: String, name: String, enumName: String) {
        self.id = id
        self.name = name
        self.enumName = enumName
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": nodeType.rawValue,
            "name": name,
            "enum": enumName
        ]
    }
}

