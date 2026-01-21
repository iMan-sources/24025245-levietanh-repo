//
//  NodeData.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation
/// Node type definitions for the UML graph
///
/// Defines all the different types of nodes that can appear in a UML class diagram graph,
/// including classes, attributes, operations, and enum literals.

/// Enum representing the type of a node in the graph
public enum NodeType: String, Codable {
    case classNode = "Class"
    case enumeration = "Enumeration"
    case attribute = "Attribute"
    case operation = "Operation"
    case enumLiteral = "EnumLiteral"
    case associationClass = "AssociationClass"
}


/// Protocol that all node data types conform to
public protocol NodeData {
    var id: String { get }
    var nodeType: NodeType { get }
    func toDictionary() -> [String: Any]
}
