//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//

import Foundation

/// Information about a class attribute
public struct AttributeInfo {
    public let name: String
    public let dataType: String?
    
    public init(name: String, dataType: String?) {
        self.name = name
        self.dataType = dataType
    }
}
