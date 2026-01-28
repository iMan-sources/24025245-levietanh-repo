//
//  ClassInfo.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//

/// Complete information about a class extracted from Steiner tree
public struct ClassInfo {
    public let className: String
    public let attributes: [AttributeInfo]
    public let operations: [OperationInfo]
    public let associations: [AssociationInfo]
    
    public init(className: String, attributes: [AttributeInfo], operations: [OperationInfo], associations: [AssociationInfo]) {
        self.className = className
        self.attributes = attributes
        self.operations = operations
        self.associations = associations
    }
}
