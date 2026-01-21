//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

/// Simple ownership edge: Enumeration -> EnumLiteral
public struct HasLiteralEdge: EdgeData {
    public var edgeType: EdgeType {
        return .hasLiteral
    }
    
    public func toDictionary() -> [String: Any] {
        return ["type": edgeType.rawValue]
    }
}
