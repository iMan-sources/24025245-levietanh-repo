//
//  EdgeData.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation
/// Edge type definitions for the UML graph
///
/// Defines all the different types of edges (relationships) that can appear in a UML
/// class diagram graph, including ownership, associations, generalizations, and realizations.


/// Enum representing the type of an edge in the graph
public enum EdgeType: String, Codable {
    case ownsAttr = "OWNS_ATTR"      // Class owns Attribute
    case ownsOp = "OWNS_OP"          // Class owns Operation
    case hasLiteral = "HAS_LITERAL"  // Enumeration has EnumLiteral
    case hasType = "HAS_TYPE"        // Attribute has type Class/Enum
    case assoc = "ASSOC"             // Association between classes
    case generalizes = "GENERALIZES" // Inheritance (child -> parent)
    case realizes = "REALIZES"       // Interface implementation
}

/// Protocol that all edge data types conform to
public protocol EdgeData {
    var edgeType: EdgeType { get }
    func toDictionary() -> [String: Any]
}

// MARK: - Association Edge

/// Aggregation kind for associations
public enum AggregationKind: String, Codable {
    case none = "none"           // Simple association
    case shared = "shared"       // Aggregation (o--)
    case composite = "composite" // Composition (*--)
}

/// Navigability for associations
public enum Navigability: String, Codable {
    case bidirectional = "bi"    // A <-> B
    case sourceToDestination = "src→dst"  // A -> B
    case destinationToSource = "dst→src"  // A <- B
}

// MARK: - Edge Helper Functions

/// Helper to create edge attributes dictionary from EdgeData
public func createEdgeAttributes(from edgeData: EdgeData) -> [String: Any] {
    return edgeData.toDictionary()
}

/// Helper to create simple edge attributes with just type
public func createSimpleEdgeAttributes(type: EdgeType) -> [String: Any] {
    return ["type": type.rawValue]
}
