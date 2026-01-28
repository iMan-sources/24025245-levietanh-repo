//
//  GraphExtractor.swift
//  ThesisCLI
//
//  Created by Le Anh on 22/1/26.
//
import Foundation

/// Internal key used to uniquely identify an association from the perspective
/// of a given class. This allows multiple associations to the same target
/// class (with different roles or multiplicities) to be preserved.
private struct AssociationKey: Hashable {
    let target: String
    let role: String?
    let multiplicity: String
}

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
    /// - Parameter graph: The MultiDiGraph containing all nodes
    /// - Returns: CandidateMapping with candidates and their corresponding node IDs
    public func extractDesc(from graph: MultiDiGraph) -> CandidateMapping {
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
    
    // MARK: - Class Information Extraction
                    
    /// Extract class information from nodes in the Steiner tree
    /// - Parameters:
    ///   - graph: The MultiDiGraph containing all nodes and edges
    ///   - steinerResult: The result from Steiner tree computation
    ///   - onlySteinerNodes: If true, only extract information from nodes in Steiner tree. If false, extract all information from graph (default: false)
    /// - Returns: Array of ClassInfo containing attributes, operations, and associations for each class
    public func extractClassInformation(
        from graph: MultiDiGraph,
        steinerResult: SteinerTreeResult,
        onlySteinerNodes: Bool = false
    ) -> [ClassInfo] {
        // Step 1: Identify class nodes in Steiner tree
        var classNodes: [String] = []
        let steinerNodeIds = steinerResult.nodes
        
        for nodeId in steinerNodeIds {
            guard let node = graph.getNode(nodeId) else { continue }
            let nodeType = node.attributes["type"] as? String ?? ""
            
            // Check if it's a Class (including interfaces), Enumeration, or AssociationClass
            if nodeType == "Class" || nodeType == "Enumeration" || nodeType == "AssociationClass" {
                classNodes.append(nodeId)
            }
        }
        
        // Step 2: For each class, collect attributes, operations, and associations
        var classInfos: [ClassInfo] = []
        
        for className in classNodes {
            // Collect attributes
            let attributes = collectAttributes(for: className, in: graph, steinerNodes: steinerNodeIds, onlySteinerNodes: onlySteinerNodes)
            
            // Collect operations
            let operations = collectOperations(for: className, in: graph, steinerNodes: steinerNodeIds, onlySteinerNodes: onlySteinerNodes)
            
            // Collect associations
            let associations = collectAssociations(for: className, in: graph, steinerNodes: steinerNodeIds, onlySteinerNodes: onlySteinerNodes)
            
            let classInfo = ClassInfo(
                className: className,
                attributes: attributes,
                operations: operations,
                associations: associations
            )
            classInfos.append(classInfo)
        }
        
        return classInfos
    }
    
    // MARK: - Private Helper Methods
    
    /// Collect attributes for a class from both Steiner tree nodes and graph edges
    private func collectAttributes(
        for className: String,
        in graph: MultiDiGraph,
        steinerNodes: Set<String>,
        onlySteinerNodes: Bool
    ) -> [AttributeInfo] {
        var attributes: [String: AttributeInfo] = [:]
        
        // 1. Find attributes in Steiner tree nodes
        for nodeId in steinerNodes {
            guard let node = graph.getNode(nodeId) else { continue }
            let nodeType = node.attributes["type"] as? String ?? ""
            
            if nodeType == "Attribute" {
                let owner = node.attributes["owner"] as? String ?? ""
                if owner == className {
                    let name = node.attributes["name"] as? String ?? nodeId
                    let attrType = node.attributes["attrType"] as? String
                    attributes[name] = AttributeInfo(name: name, dataType: attrType)
                }
            }
        }
        
        // 2. Find attributes via OWNS_ATTR edges from graph (skip if onlySteinerNodes is true)
        if !onlySteinerNodes {
            let outgoingEdges = graph.getOutgoingEdges(from: className)
            for edge in outgoingEdges {
                let edgeType = edge.attributes["type"] as? String ?? ""
                if edgeType == "OWNS_ATTR" {
                    let attrNodeId = edge.destination
                    if let attrNode = graph.getNode(attrNodeId) {
                        let name = attrNode.attributes["name"] as? String ?? attrNodeId
                        let attrType = attrNode.attributes["attrType"] as? String
                        // Only add if not already found (deduplication)
                        if attributes[name] == nil {
                            attributes[name] = AttributeInfo(name: name, dataType: attrType)
                        }
                    }
                }
            }
        }
        
        return Array(attributes.values).sorted { $0.name < $1.name }
    }
    
    /// Collect operations for a class from both Steiner tree nodes and graph edges
    private func collectOperations(
        for className: String,
        in graph: MultiDiGraph,
        steinerNodes: Set<String>,
        onlySteinerNodes: Bool
    ) -> [OperationInfo] {
        var operations: [String: OperationInfo] = [:]
        
        // 1. Find operations in Steiner tree nodes
        for nodeId in steinerNodes {
            guard let node = graph.getNode(nodeId) else { continue }
            let nodeType = node.attributes["type"] as? String ?? ""
            
            if nodeType == "Operation" {
                let owner = node.attributes["owner"] as? String ?? ""
                if owner == className {
                    let name = node.attributes["name"] as? String ?? nodeId
                    let returnType = node.attributes["returnType"] as? String
                    operations[name] = OperationInfo(name: name, returnType: returnType)
                }
            }
        }
        
        // 2. Find operations via OWNS_OP edges from graph (skip if onlySteinerNodes is true)
        if !onlySteinerNodes {
            let outgoingEdges = graph.getOutgoingEdges(from: className)
            for edge in outgoingEdges {
                let edgeType = edge.attributes["type"] as? String ?? ""
                if edgeType == "OWNS_OP" {
                    let opNodeId = edge.destination
                    if let opNode = graph.getNode(opNodeId) {
                        let name = opNode.attributes["name"] as? String ?? opNodeId
                        let returnType = opNode.attributes["returnType"] as? String
                        // Only add if not already found (deduplication)
                        if operations[name] == nil {
                            operations[name] = OperationInfo(name: name, returnType: returnType)
                        }
                    }
                }
            }
        }
        
        return Array(operations.values).sorted { $0.name < $1.name }
    }
    
    /// Collect associations for a class from graph edges
    private func collectAssociations(
        for className: String,
        in graph: MultiDiGraph,
        steinerNodes: Set<String>,
        onlySteinerNodes: Bool
    ) -> [AssociationInfo] {
        // Use dictionary with composite key to deduplicate only exact duplicates
        // while still allowing multiple associations to the same target with
        // different roles or multiplicities.
        var associationsDict: [AssociationKey: AssociationInfo] = [:]
        
        // 1. Check outgoing ASSOC edges (this class -> other class)
        let outgoingEdges = graph.getOutgoingEdges(from: className)
        for edge in outgoingEdges {
            let edgeType = edge.attributes["type"] as? String ?? ""
            if edgeType == "ASSOC" {
                let target = edge.destination
                // Only include if target is a class/enumeration/association class (not attribute/operation)
                if let targetNode = graph.getNode(target) {
                    let targetType = targetNode.attributes["type"] as? String ?? ""
                    if targetType == "Class" || targetType == "Enumeration" || targetType == "AssociationClass" {
                        // If onlySteinerNodes is true, only include if target is in Steiner tree
                        if onlySteinerNodes && !steinerNodes.contains(target) {
                            continue
                        }
                        // For outgoing edges, from this class's perspective we want the
                        // role and multiplicity at the OTHER end (destination).
                        let role = edge.attributes["roleDst"] as? String
                        let multiplicity = edge.attributes["multDst"] as? String ?? "0..*"
                        let key = AssociationKey(
                            target: target,
                            role: role,
                            multiplicity: multiplicity
                        )
                        associationsDict[key] = AssociationInfo(
                            target: target,
                            role: role,
                            multiplicity: multiplicity
                        )
                    }
                }
            }
        }
        
        // 2. Check incoming ASSOC edges (other class -> this class)
        let incomingEdges = graph.getIncomingEdges(to: className)
        for edge in incomingEdges {
            let edgeType = edge.attributes["type"] as? String ?? ""
            if edgeType == "ASSOC" {
                let source = edge.source
                // Only include if source is a class/enumeration/association class
                if let sourceNode = graph.getNode(source) {
                    let sourceType = sourceNode.attributes["type"] as? String ?? ""
                    if sourceType == "Class" || sourceType == "Enumeration" || sourceType == "AssociationClass" {
                        // If onlySteinerNodes is true, only include if source is in Steiner tree
                        if onlySteinerNodes && !steinerNodes.contains(source) {
                            continue
                        }
                        // For incoming edges, from this class's perspective we want the
                        // role and multiplicity at the OTHER end (source).
                        let role = edge.attributes["roleSrc"] as? String
                        let multiplicity = edge.attributes["multSrc"] as? String ?? "0..*"
                        let key = AssociationKey(
                            target: source,
                            role: role,
                            multiplicity: multiplicity
                        )
                        // Only add if not already present (deduplication)
                        if associationsDict[key] == nil {
                            associationsDict[key] = AssociationInfo(
                                target: source,
                                role: role,
                                multiplicity: multiplicity
                            )
                        }
                    }
                }
            }
        }
        
        return Array(associationsDict.values).sorted {
            if $0.target == $1.target {
                return ($0.role ?? "") < ($1.role ?? "")
            }
            return $0.target < $1.target
        }
    }
}
