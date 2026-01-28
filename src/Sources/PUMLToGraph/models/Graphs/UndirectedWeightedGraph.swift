//
//  UndirectedWeightedGraph.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation

/// Represents an undirected weighted edge
public struct WeightedEdge {
    /// First node ID (always the smaller one lexicographically)
    public let node1: String
    
    /// Second node ID (always the larger one lexicographically)
    public let node2: String
    
    /// Weight of the edge
    public let weight: Double
    
    /// Initialize a weighted edge
    public init(node1: String, node2: String, weight: Double) {
        // Normalize: always store with node1 < node2
        if node1 < node2 {
            self.node1 = node1
            self.node2 = node2
        } else {
            self.node1 = node2
            self.node2 = node1
        }
        self.weight = weight
    }
}

/// An undirected weighted graph representation
/// Used for converting from directed MultiDiGraph
public class UndirectedWeightedGraph {
    /// Storage for all nodes in the graph
    private var nodes: [String: GraphNode]
    
    /// Storage for edges: maps normalized node pair to weight
    /// Key format: "node1-node2" where node1 < node2 lexicographically
    private var edges: [String: Double]
    
    /// Initialize an empty undirected weighted graph
    public init() {
        self.nodes = [:]
        self.edges = [:]
    }
    
    /// Initialize from nodes
    ///
    /// Args:
    ///     nodes: Array of GraphNode to initialize with
    public init(nodes: [GraphNode]) {
        self.nodes = [:]
        for node in nodes {
            self.nodes[node.id] = node
        }
        self.edges = [:]
    }
    
    // MARK: - Node Operations
    
    /// Add a node to the graph
    ///
    /// Args:
    ///     node: GraphNode to add
    public func addNode(_ node: GraphNode) {
        nodes[node.id] = node
    }
    
    /// Get a node by its ID
    ///
    /// Args:
    ///     id: Node identifier
    ///
    /// Returns:
    ///     The GraphNode if found, nil otherwise
    public func getNode(_ id: String) -> GraphNode? {
        return nodes[id]
    }
    
    /// Check if a node exists
    public func hasNode(_ id: String) -> Bool {
        return nodes[id] != nil
    }
    
    /// Get all nodes in the graph
    public func allNodes() -> [GraphNode] {
        return Array(nodes.values)
    }
    
    /// Get the number of nodes in the graph
    public func numberOfNodes() -> Int {
        return nodes.count
    }
    
    // MARK: - Edge Operations
    
    /// Add or update an edge between two nodes
    /// If an edge already exists, the weight will be updated to the minimum of existing and new weight
    ///
    /// Args:
    ///     node1: First node ID
    ///     node2: Second node ID
    ///     weight: Weight of the edge
    public func addEdge(node1: String, node2: String, weight: Double) {
        // Normalize node pair
        let (n1, n2) = node1 < node2 ? (node1, node2) : (node2, node1)
        let key = "\(n1)-\(n2)"
        
        // If edge exists, take minimum weight
        if let existingWeight = edges[key] {
            edges[key] = min(existingWeight, weight)
        } else {
            edges[key] = weight
        }
    }
    
    /// Get weight between two nodes
    ///
    /// Args:
    ///     node1: First node ID
    ///     node2: Second node ID
    ///
    /// Returns:
    ///     Weight if edge exists, nil otherwise
    public func getWeight(node1: String, node2: String) -> Double? {
        let (n1, n2) = node1 < node2 ? (node1, node2) : (node2, node1)
        let key = "\(n1)-\(n2)"
        return edges[key]
    }
    
    /// Check if an edge exists between two nodes
    ///
    /// Args:
    ///     node1: First node ID
    ///     node2: Second node ID
    ///
    /// Returns:
    ///     True if edge exists, false otherwise
    public func hasEdge(node1: String, node2: String) -> Bool {
        return getWeight(node1: node1, node2: node2) != nil
    }
    
    /// Get all edges as tuples (node1, node2, weight)
    /// node1 is always lexicographically smaller than node2
    ///
    /// Returns:
    ///     Array of (node1, node2, weight) tuples
    public func allEdges() -> [(String, String, Double)] {
        return edges.map { (key, weight) in
            let components = key.split(separator: "-")
            let node1 = String(components[0])
            let node2 = String(components[1])
            return (node1, node2, weight)
        }
    }
    
    /// Get all edges as WeightedEdge structs
    ///
    /// Returns:
    ///     Array of WeightedEdge
    public func allWeightedEdges() -> [WeightedEdge] {
        return edges.map { (key, weight) in
            let components = key.split(separator: "-")
            let node1 = String(components[0])
            let node2 = String(components[1])
            return WeightedEdge(node1: node1, node2: node2, weight: weight)
        }
    }
    
    /// Get the number of edges in the graph
    public func numberOfEdges() -> Int {
        return edges.count
    }
    
    /// Get neighbors of a node
    ///
    /// Args:
    ///     nodeId: Node identifier
    ///
    /// Returns:
    ///     Array of neighbor node IDs
    public func getNeighbors(of nodeId: String) -> [String] {
        var neighbors: [String] = []
        for (key, _) in edges {
            let components = key.split(separator: "-")
            let n1 = String(components[0])
            let n2 = String(components[1])
            
            if n1 == nodeId {
                neighbors.append(n2)
            } else if n2 == nodeId {
                neighbors.append(n1)
            }
        }
        return neighbors
    }
    
    // MARK: - JSON Export
    
    /// Convert graph to JSON-serializable dictionary
    ///
    /// Returns:
    ///     Dictionary containing nodes and edges arrays
    ///
    /// Example:
    ///     let jsonDict = graph.toJSON()
    ///     let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
    public func toJSON() -> [String: Any] {
        // Convert nodes to JSON-compatible format
        let nodesArray = allNodes().map { node -> [String: Any] in
            var nodeDict: [String: Any] = ["id": node.id]
            
            // Convert attributes to JSON-compatible format
            var sanitizedAttributes: [String: Any] = [:]
            for (key, value) in node.attributes {
                sanitizedAttributes[key] = sanitizeValue(value)
            }
            nodeDict["attributes"] = sanitizedAttributes
            
            return nodeDict
        }
        
        // Convert edges to JSON-compatible format
        let edgesArray = allEdges().map { (node1, node2, weight) -> [String: Any] in
            return [
                "node1": node1,
                "node2": node2,
                "weight": weight
            ]
        }
        
        return [
            "nodes": nodesArray,
            "edges": edgesArray
        ]
    }
    
    /// Sanitize values to be JSON-compatible
    ///
    /// Args:
    ///     value: Any value to sanitize
    ///
    /// Returns:
    ///     JSON-compatible value
    private func sanitizeValue(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var sanitized: [String: Any] = [:]
            for (key, val) in dict {
                sanitized[key] = sanitizeValue(val)
            }
            return sanitized
        } else if let array = value as? [Any] {
            return array.map { sanitizeValue($0) }
        } else if let string = value as? String {
            return string
        } else if let number = value as? NSNumber {
            return number
        } else if let bool = value as? Bool {
            return bool
        } else if value is NSNull {
            return NSNull()
        } else {
            // Convert any other type to string representation
            return String(describing: value)
        }
    }
    
    /// Export graph to JSON file
    ///
    /// Args:
    ///     filepath: Path to output JSON file
    ///
    /// Throws:
    ///     Error if file cannot be written
    ///
    /// Example:
    ///     try graph.exportToJSON(filepath: "output/undirected_graph.json")
    public func exportToJSON(filepath: String) throws {
        let jsonDict = toJSON()
        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: filepath))
    }
}
