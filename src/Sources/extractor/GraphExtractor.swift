//
//  GraphExtractor.swift
//  ThesisCLI
//
//  Created by Le Anh on 22/1/26.
//
import Foundation

public class GraphExtractor {
    // MARK: - Candidate Mapping for Embedding Search
    
    /// Maps embedding candidates back to their source node IDs
    public struct CandidateMapping {
        /// Text candidates to embed
        public let candidates: [String]
        /// Node ID for each candidate (nodeIds[i] corresponds to candidates[i])
        public let nodeIds: [String]
    }
    
    /// Extract text candidates from graph nodes for embedding
    /// - For Class/Enumeration nodes: uses normalized_text array (each component becomes a candidate)
    /// - For other nodes: uses semantic_desc string
    /// - Parameter graph: The SimpleGraph containing all nodes
    /// - Returns: CandidateMapping with candidates and their corresponding node IDs
    public func extractDesc(from graph: SimpleGraph) -> CandidateMapping {
        var candidates: [String] = []
        var nodeIds: [String] = []
        
        for node in graph.allNodes() {
            let nodeType = node.attributes["type"] as? String ?? ""
            
            if nodeType == "Class" || nodeType == "Enumeration" {
                // For Class/Enumeration: use normalized_text array
                if let normalizedText = node.attributes["normalized_text"] as? [String] {
                    for text in normalizedText where !text.isEmpty {
                        candidates.append(text)
                        nodeIds.append(node.id)
                    }
                }
            } else {
                // For other nodes: use semantic_desc
                if let semanticDesc = node.attributes["semantic_desc"] as? String, !semanticDesc.isEmpty {
                    candidates.append(semanticDesc)
                    nodeIds.append(node.id)
                }
            }
        }
        
        return CandidateMapping(candidates: candidates, nodeIds: nodeIds)
    }
}
