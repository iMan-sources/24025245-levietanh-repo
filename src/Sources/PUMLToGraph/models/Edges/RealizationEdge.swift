//
//  RealizationEdge.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

// MARK: - Realization Edge

/// Realization (interface implementation) edge: Class -> Interface
public struct RealizationEdge: EdgeData {
    public var edgeType: EdgeType {
        return .realizes
    }
    
    public func toDictionary() -> [String: Any] {
        return ["type": edgeType.rawValue]
    }
}
