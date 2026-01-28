//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

// MARK: - Operation Node

/// Represents an Operation (method) node in the UML diagram
///
/// Example:
///     let op = OperationNodeData(
///         id: "book(f: Flight)@Passenger",
///         name: "book",
///         params: [
///             OperationParameter(name: "f", type: "Flight")
///         ],
///         returnType: "Boolean",
///         visibility: "+",
///         owner: "Passenger"
///     )


/// Represents a parameter in an operation
public struct OperationParameter: Codable {
    /// Parameter name
    public let name: String
    
    /// Parameter type (nil if not specified)
    public var type: String?
    
    public init(name: String, type: String? = nil) {
        self.name = name
        self.type = type
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["name": name]
        if let type = type {
            dict["type"] = type
        }
        return dict
    }
}

public struct OperationNodeData: NodeData {
    /// Unique identifier in format "name(params)@OwnerClass"
    public let id: String
    
    /// Operation name
    public let name: String
    
    /// List of parameters
    public var params: [OperationParameter]
    
    /// Return type (nil for void)
    public var returnType: String?
    
    /// Visibility: "+", "-", "#", "~" or nil
    public var visibility: String?
    
    /// Whether this is a derived operation
    public var isDerived: Bool
    
    /// Name of the owning class
    public let owner: String
    
    /// Semantic description
    public var semanticDesc: String
    
    /// Node type (always .operation)
    public var nodeType: NodeType {
        return .operation
    }
    
    public init(id: String, name: String, params: [OperationParameter] = [], returnType: String? = nil, visibility: String? = nil, isDerived: Bool = false, owner: String, semanticDesc: String = "") {
        self.id = id
        self.name = name
        self.params = params
        self.returnType = returnType
        self.visibility = visibility
        self.isDerived = isDerived
        self.owner = owner
        self.semanticDesc = semanticDesc
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": nodeType.rawValue,
            "name": name,
            "params": params.map { $0.toDictionary() },
            "isDerived": isDerived,
            "owner": owner,
            "semantic_desc": semanticDesc
        ]
        
        if let returnType = returnType {
            dict["returnType"] = returnType
        }
        if let visibility = visibility {
            dict["visibility"] = visibility
        }
        
        return dict
    }
}
