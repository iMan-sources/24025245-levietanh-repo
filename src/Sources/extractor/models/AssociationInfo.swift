//
//  AssociationInfo.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//

/// Information about a class association
public struct AssociationInfo {
    public let target: String
    public let role: String?
    public let multiplicity: String
    
    public init(target: String, role: String?, multiplicity: String) {
        self.target = target
        self.role = role
        self.multiplicity = multiplicity
    }
}
