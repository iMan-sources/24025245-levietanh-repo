//
//  MultiDiGraph.swift
//  ThesisCLI
//
//  Created by Le Anh on 21/1/26.
//

import Foundation
/// A directed graph that allows multiple edges between the same pair of nodes.
/// This is essential for representing UML associations where two classes can have
/// multiple different relationships.

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

/// Represents an edge in the graph
public struct GraphEdge {
    /// Source node ID
    public let source: String
    
    /// Destination node ID
    public let destination: String
    
    /// Unique key for this edge (allows multiple edges between same nodes)
    public let key: String
    
    /// Edge attributes (type, roles, multiplicities, etc.)
    public var attributes: [String: Any]
    
    /// Initialize a graph edge
    public init(source: String, destination: String, key: String, attributes: [String: Any] = [:]) {
        self.source = source
        self.destination = destination
        self.key = key
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


/// Example:
///     let graph = MultiDiGraph()
///     graph.addNode("Airport", attributes: ["type": "Class"])
///     graph.addEdge(from: "Airport", to: "Flight", key: "e0", attributes: ["type": "ASSOC"])

/// Main graph structure that holds nodes and edges
public class MultiDiGraph {
    /// Storage for all nodes in the graph
    private var nodes: [String: GraphNode]
    
    /// Adjacency list: maps source node -> list of outgoing edges
    private var outgoingEdges: [String: [GraphEdge]]
    
    /// Adjacency list: maps destination node -> list of incoming edges
    private var incomingEdges: [String: [GraphEdge]]
    
    /// Global metadata for the graph (e.g., warnings from parsing)
    public var metadata: [String: Any]
    
    
    public init() {
        self.nodes = [:]
        self.outgoingEdges = [:]
        self.incomingEdges = [:]
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
extension MultiDiGraph {
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
    
    public func addNode(_ id: String,
                        attributes: [String: Any] = [:]) {
        let node = GraphNode(id: id, attributes: attributes)
        nodes[id] = node
        
        // Initialize edge lists if not present
        if outgoingEdges[id] == nil {
            outgoingEdges[id] = []
        }
        if incomingEdges[id] == nil {
            incomingEdges[id] = []
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
extension MultiDiGraph {
    /// Add an edge to the graph
    /// Args:
    ///     from: Source node ID
    ///     to: Destination node ID
    ///     key: Optional unique key for this edge (for multi-edges)
    ///     attributes: Dictionary of edge attributes
    ///
    /// Example:
    ///     graph.addEdge(from: "Airport", to: "Flight", key: "e0", attributes: [
    ///         "type": "ASSOC",
    ///         "roleSrc": "origin",
    ///         "roleDst": "departingFlights"
    ///     ])
    public func addEdge(from source: String,
                        to destination: String,
                        key: String? = nil,
                        attributes: [String: Any] = [:]) {
        // Ensure both nodes exist
        if !hasNode(source) {
            addNode(source)
        }
        if !hasNode(destination) {
            addNode(destination)
        }
        
        // Create edge with unique key if not provided
        let edgeKey = key ?? UUID().uuidString
        let edge = GraphEdge(source: source, destination: destination, key: edgeKey, attributes: attributes)
        
        // Add to outgoing edges
        outgoingEdges[source, default: []].append(edge)
        
        // Add to incoming edges
        incomingEdges[destination, default: []].append(edge)
    }
    
    /// Get all edges from source to destination
    ///
    /// Args:
    ///     from: Source node ID
    ///     to: Destination node ID
    ///
    /// Returns:
    ///     Array of edges between the two nodes
    public func getEdges(from source: String, to destination: String) -> [GraphEdge] {
        guard let edges = outgoingEdges[source] else { return [] }
        return edges.filter { $0.destination == destination }
    }
    
    /// Get all outgoing edges from a node
    public func getOutgoingEdges(from source: String) -> [GraphEdge] {
        return outgoingEdges[source] ?? []
    }
    
    /// Get all incoming edges to a node
    public func getIncomingEdges(to destination: String) -> [GraphEdge] {
        return incomingEdges[destination] ?? []
    }
    
    /// Get all edges in the graph
    public func allEdges() -> [GraphEdge] {
        return outgoingEdges.values.flatMap { $0 }
    }
    
    /// Get the total number of edges in the graph
    public func numberOfEdges() -> Int {
        return outgoingEdges.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - JSON Export
extension MultiDiGraph {
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
                "key": edge.key
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


