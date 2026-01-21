//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

/// Type reference edge: Attribute -> Class/Enum (for attribute type)
public struct HasTypeEdge: EdgeData {
    public var edgeType: EdgeType {
        return .hasType
    }
    
    public func toDictionary() -> [String: Any] {
        return ["type": edgeType.rawValue]
    }
}
