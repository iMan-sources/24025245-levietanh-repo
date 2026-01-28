//
//  OwnsAttrEdge.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation
// MARK: - Simple Edge Types

/// Simple ownership edge: Class -> Attribute
public struct OwnsAttrEdge: EdgeData {
    public var edgeType: EdgeType {
        return .ownsAttr
    }
    
    public func toDictionary() -> [String: Any] {
        return ["type": edgeType.rawValue]
    }
}
