//
//  SimpleGraph.swift
//  ThesisCLI
//
//  Created by Le Anh on 22/1/26.
//

import Foundation

/// A simple directed graph that allows only one edge between each pair of nodes.
/// Each edge has a weight for use in graph algorithms like Steiner Tree.

/// Represents a node in the graph
public struct GraphNode {
    /// Unique identifier for the node
    public let id: String
    
    /// Node attributes (type, name, properties, etc.)
    public var attributes: [String: Any]
    
    /// Initialize a graph node
    public init(id: String, attributes: [String: Any] = [:]) {
        self.id = id
        self.attributes = attributes
    }
}

/// Represents an edge in the simple graph (no key needed, has weight)
public struct GraphEdge {
    /// Source node ID
    public let source: String
    
    /// Destination node ID
    public let destination: String
    
    /// Edge weight for graph algorithms
    public var weight: Double
    
    /// Edge attributes (type, roles, multiplicities, etc.)
    public var attributes: [String: Any]
    
    /// Initialize a graph edge
    public init(source: String, destination: String, weight: Double = 1.0, attributes: [String: Any] = [:]) {
        self.source = source
        self.destination = destination
        self.weight = weight
        self.attributes = attributes
    }
}

/// Statistics about the graph structure
public struct GraphStatistics {
    /// Total number of nodes
    public let totalNodes: Int
    
    /// Total number of edges
    public let totalEdges: Int
    
    /// Count of each node type
    public let nodeTypeCount: [String: Int]
    
    /// Count of each edge type
    public let edgeTypeCount: [String: Int]
}

/// Edge weight configuration for different relationship types
public enum EdgeWeight {
    public static let assoc: Double = 1.0
    public static let generalizes: Double = 0.8
    public static let realizes: Double = 0.8
    public static let hasType: Double = 0.5
    public static let ownsAttr: Double = 0.3
    public static let ownsOp: Double = 0.2
    public static let hasLiteral: Double = 0.1
}

/// Example:
///     let graph = SimpleGraph()
///     graph.addNode("Airport", attributes: ["type": "Class"])
///     graph.addEdge(from: "Airport", to: "Flight", weight: 1.0, attributes: ["type": "ASSOC"])

/// Main graph structure that holds nodes and edges (simple graph - one edge per node pair)
public class SimpleGraph {
    /// Storage for all nodes in the graph
    private var nodes: [String: GraphNode]
    
    /// Adjacency map: source -> destination -> edge (only one edge per pair)
    private var adjacency: [String: [String: GraphEdge]]
    
    /// Reverse adjacency for incoming edges lookup
    private var reverseAdjacency: [String: [String: GraphEdge]]
    
    /// Global metadata for the graph (e.g., warnings from parsing)
    public var metadata: [String: Any]
    
    public init() {
        self.nodes = [:]
        self.adjacency = [:]
        self.reverseAdjacency = [:]
        self.metadata = [:]
    }
    
    // MARK: - Utility Methods
    
    /// Get nodes filtered by type
    ///
    /// Example:
    ///     let classes = graph.getNodesByType("Class")
    public func getNodesByType(_ type: String) -> [GraphNode] {
        return nodes.values.filter { node in
            if let nodeType = node.attributes["type"] as? String {
                return nodeType == type
            }
            return false
        }
    }
    
    /// Get edges filtered by type
    ///
    /// Example:
    ///     let associations = graph.getEdgesByType("ASSOC")
    public func getEdgesByType(_ type: String) -> [GraphEdge] {
        return allEdges().filter { edge in
            if let edgeType = edge.attributes["type"] as? String {
                return edgeType == type
            }
            return false
        }
    }
    
    /// Get statistics about the graph
    public func getStatistics() -> GraphStatistics {
        let nodeTypes = Dictionary(grouping: nodes.values) { node in
            node.attributes["type"] as? String ?? "Unknown"
        }.mapValues { $0.count }
        
        let edgeTypes = Dictionary(grouping: allEdges()) { edge in
            edge.attributes["type"] as? String ?? "Unknown"
        }.mapValues { $0.count }
        
        return GraphStatistics(
            totalNodes: numberOfNodes(),
            totalEdges: numberOfEdges(),
            nodeTypeCount: nodeTypes,
            edgeTypeCount: edgeTypes
        )
    }
}

// MARK: - Node Operations
extension SimpleGraph {
    /// Add a node to the graph with attributes
    ///
    /// Args:
    ///     id: Unique identifier for the node
    ///     attributes: Dictionary of node attributes
    ///
    /// Example:
    ///     graph.addNode("Airport", attributes: [
    ///         "type": "Class",
    ///         "name": "Airport",
    ///         "isAbstract": false
    ///     ])
    public func addNode(_ id: String, attributes: [String: Any] = [:]) {
        let node = GraphNode(id: id, attributes: attributes)
        nodes[id] = node
        
        // Initialize adjacency lists if not present
        if adjacency[id] == nil {
            adjacency[id] = [:]
        }
        if reverseAdjacency[id] == nil {
            reverseAdjacency[id] = [:]
        }
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
}

// MARK: - Edge Operations
extension SimpleGraph {
    /// Add an edge to the graph
    /// If an edge already exists between source and destination, keeps the one with lower weight.
    ///
    /// Args:
    ///     from: Source node ID
    ///     to: Destination node ID
    ///     weight: Edge weight (default 1.0)
    ///     attributes: Dictionary of edge attributes
    ///
    /// Example:
    ///     graph.addEdge(from: "Airport", to: "Flight", weight: 1.0, attributes: [
    ///         "type": "ASSOC",
    ///         "roleSrc": "origin",
    ///         "roleDst": "departingFlights"
    ///     ])
    public func addEdge(from source: String,
                        to destination: String,
                        weight: Double = 1.0,
                        attributes: [String: Any] = [:]) {
        // Ensure both nodes exist
        if !hasNode(source) {
            addNode(source)
        }
        if !hasNode(destination) {
            addNode(destination)
        }
        
        let newEdge = GraphEdge(source: source, destination: destination, weight: weight, attributes: attributes)
        
        // Check if edge already exists
        if let existingEdge = adjacency[source]?[destination] {
            // Keep edge with lower weight (more important relationship)
            if newEdge.weight < existingEdge.weight {
                adjacency[source]![destination] = newEdge
                reverseAdjacency[destination]![source] = newEdge
            }
            // If weights are equal, keep existing (first one wins)
        } else {
            // Add new edge
            adjacency[source, default: [:]][destination] = newEdge
            reverseAdjacency[destination, default: [:]][source] = newEdge
        }
    }
    
    /// Add an edge, always replacing existing edge (for compatibility with GraphBuilder)
    /// Used when we need to ensure the edge is added regardless of weight
    public func setEdge(from source: String,
                        to destination: String,
                        weight: Double = 1.0,
                        attributes: [String: Any] = [:]) {
        // Ensure both nodes exist
        if !hasNode(source) {
            addNode(source)
        }
        if !hasNode(destination) {
            addNode(destination)
        }
        
        let edge = GraphEdge(source: source, destination: destination, weight: weight, attributes: attributes)
        adjacency[source, default: [:]][destination] = edge
        reverseAdjacency[destination, default: [:]][source] = edge
    }
    
    /// Get edge from source to destination
    ///
    /// Args:
    ///     from: Source node ID
    ///     to: Destination node ID
    ///
    /// Returns:
    ///     The edge if exists, nil otherwise
    public func getEdge(from source: String, to destination: String) -> GraphEdge? {
        return adjacency[source]?[destination]
    }
    
    /// Check if an edge exists between two nodes
    public func hasEdge(from source: String, to destination: String) -> Bool {
        return adjacency[source]?[destination] != nil
    }
    
    /// Get all outgoing edges from a node
    public func getOutgoingEdges(from source: String) -> [GraphEdge] {
        guard let edges = adjacency[source] else { return [] }
        return Array(edges.values)
    }
    
    /// Get all incoming edges to a node
    public func getIncomingEdges(to destination: String) -> [GraphEdge] {
        guard let edges = reverseAdjacency[destination] else { return [] }
        return Array(edges.values)
    }
    
    /// Get all edges in the graph
    public func allEdges() -> [GraphEdge] {
        return adjacency.values.flatMap { $0.values }
    }
    
    /// Get the total number of edges in the graph
    public func numberOfEdges() -> Int {
        return adjacency.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - JSON Export
extension SimpleGraph {
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
        let edgesArray = allEdges().map { edge -> [String: Any] in
            var edgeDict: [String: Any] = [
                "source": edge.source,
                "destination": edge.destination,
                "weight": edge.weight,
                // Generate key for compatibility with visualizer (using source-destination as key)
                "key": "\(edge.source)-\(edge.destination)"
            ]
            
            // Convert attributes to JSON-compatible format
            var sanitizedAttributes: [String: Any] = [:]
            for (key, value) in edge.attributes {
                sanitizedAttributes[key] = sanitizeValue(value)
            }
            edgeDict["attributes"] = sanitizedAttributes
            
            return edgeDict
        }
        
        return [
            "nodes": nodesArray,
            "edges": edgesArray,
            "metadata": sanitizeValue(metadata) as? [String: Any] ?? [:]
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
    ///     try graph.exportToJSON(filepath: "output/graph.json")
    public func exportToJSON(filepath: String) throws {
        let jsonDict = toJSON()
        let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: filepath))
    }
}
