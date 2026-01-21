//
//  OwnsOpEdge.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

/// Simple ownership edge: Class -> Operation
public struct OwnsOpEdge: EdgeData {
    public var edgeType: EdgeType {
        return .ownsOp
    }
    
    public func toDictionary() -> [String: Any] {
        return ["type": edgeType.rawValue]
    }
}
