//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

// MARK: - Attribute Node

/// Represents an Attribute node in the UML diagram
///
/// Example:
///     let attr = AttributeNodeData(
///         id: "name@Airport",
///         name: "name",
///         attrType: "String",
///         visibility: "+",
///         isDerived: false,
///         owner: "Airport",
///         semanticDesc: "name is an attribute of class airport with data type string."
///     )
public struct AttributeNodeData: NodeData {
    /// Unique identifier in format "name@OwnerClass"
    public let id: String
    
    /// Attribute name
    public let name: String
    
    /// Data type (e.g., "String", "Integer", "Date")
    public var attrType: String?
    
    /// Visibility: "+", "-", "#", "~" or nil
    public var visibility: String?
    
    /// Whether this is a derived attribute (starts with /)
    public var isDerived: Bool
    
    /// Name of the owning class
    public let owner: String
    
    /// Additional UML properties from {}
    public var properties: [String: Any]
    
    /// Semantic description
    public var semanticDesc: String
    
    /// Node type (always .attribute)
    public var nodeType: NodeType {
        return .attribute
    }
    
    public init(id: String,
                name: String,
                attrType: String? = nil,
                visibility: String? = nil,
                isDerived: Bool = false,
                owner: String,
                properties: [String: Any] = [:],
                semanticDesc: String = "") {
        self.id = id
        self.name = name
        self.attrType = attrType
        self.visibility = visibility
        self.isDerived = isDerived
        self.owner = owner
        self.properties = properties
        self.semanticDesc = semanticDesc
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "type": nodeType.rawValue,
            "name": name,
            "isDerived": isDerived,
            "owner": owner,
            "semantic_desc": semanticDesc
        ]
        
        if let attrType = attrType {
            dict["attrType"] = attrType
        }
        if let visibility = visibility {
            dict["visibility"] = visibility
        }
        
        // Merge properties into the dictionary
        for (key, value) in properties {
            dict[key] = value
        }
        
        return dict
    }
}
