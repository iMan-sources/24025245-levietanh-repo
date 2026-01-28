//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

// MARK: - Generalization Edge

/// Generalization (inheritance) edge: Child -> Parent
///
/// Example:
///     let gen = GeneralizationEdge(
///         semanticDesc: "passenger plane is a specific type of aircraft..."
///     )
public struct GeneralizationEdge: EdgeData {
    /// Semantic description
    public var semanticDesc: String
    
    public var edgeType: EdgeType {
        return .generalizes
    }
    
    public init(semanticDesc: String = "") {
        self.semanticDesc = semanticDesc
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": edgeType.rawValue,
            "semantic_desc": semanticDesc
        ]
    }
}
