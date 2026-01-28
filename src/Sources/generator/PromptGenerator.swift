//
//  PromptGenerator.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//

import Foundation

public class PromptGenerator {
    
    /// Generate prompt string from array of ClassInfo
    /// - Parameter classInfos: Array of ClassInfo to format
    /// - Returns: Formatted string prompt following the template
    public func generatePrompt(from classInfos: [ClassInfo]) -> String {
        guard !classInfos.isEmpty else {
            return ""
        }
        
        let formattedClasses = classInfos.map { formatClassInfo($0) }
        return formattedClasses.joined(separator: "\n\n")
    }
    
    // MARK: - Private Helper Methods
    
    /// Format a single ClassInfo into prompt string
    private func formatClassInfo(_ classInfo: ClassInfo) -> String {
        var result = "-- UML properties of class \(classInfo.className)\n"
        result += "{\n"
        
        // Format attributes
        result += formatAttributes(classInfo.attributes)
        
        // Format operations
        result += formatOperations(classInfo.operations)
        
        // Format associations
        result += formatAssociations(classInfo.associations)
        
        result += "}"
        return result
    }
    
    /// Format attributes array
    private func formatAttributes(_ attributes: [AttributeInfo]) -> String {
        var result = "  \"attributes\": [\n"
        
        if attributes.isEmpty {
            result += "  ],\n"
        } else {
            let attributeStrings = attributes.map { attr in
                let dataType = attr.dataType ?? "Any"
                return "    {\n      \"\(escapeJSONString(attr.name))\": \"\(escapeJSONString(dataType))\"\n    }"
            }
            result += attributeStrings.joined(separator: ",\n")
            result += "\n  ],\n"
        }
        
        return result
    }
    
    /// Format operations array
    private func formatOperations(_ operations: [OperationInfo]) -> String {
        var result = "  \"operations\": [\n"
        
        if operations.isEmpty {
            result += "  ],\n"
        } else {
            let operationStrings = operations.map { op in
                let returnType = op.returnType ?? "Void"
                return "    {\n      \"\(escapeJSONString(op.name))\": \"\(escapeJSONString(returnType))\"\n    }"
            }
            result += operationStrings.joined(separator: ",\n")
            result += "\n  ],\n"
        }
        
        return result
    }
    
    /// Format associations array
    private func formatAssociations(_ associations: [AssociationInfo]) -> String {
        var result = "  \"associations\": [\n"
        
        if associations.isEmpty {
            result += "  ]\n"
        } else {
            let associationStrings = associations.map { assoc in
                var assocObj = "    {\n"
                assocObj += "      \"target\": \"\(escapeJSONString(assoc.target))\",\n"
                
                if let role = assoc.role {
                    assocObj += "      \"role\": \"\(escapeJSONString(role))\",\n"
                } else {
                    assocObj += "      \"role\": null,\n"
                }
                
                assocObj += "      \"multiplicity\": \"\(escapeJSONString(assoc.multiplicity))\"\n"
                assocObj += "    }"
                return assocObj
            }
            result += associationStrings.joined(separator: ",\n")
            result += "\n  ]\n"
        }
        
        return result
    }
    
    /// Escape special characters in JSON strings
    private func escapeJSONString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
