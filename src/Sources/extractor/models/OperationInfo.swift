//
//  OperationInfo.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//

/// Information about a class operation
public struct OperationInfo {
    public let name: String
    public let returnType: String?
    
    public init(name: String, returnType: String?) {
        self.name = name
        self.returnType = returnType
    }
}
