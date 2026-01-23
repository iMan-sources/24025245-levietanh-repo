//
//  steiner-algo.swift
//  ThesisCLI
//
//  Created by Le Anh on 23/1/26.
//
// ref: https://medium.com/@rkarthik3cse/steiner-tree-in-graph-explained-8eb363786599
import Foundation

// MARK: - Result Structure

/// Result of Steiner tree computation
public struct SteinerTreeResult {
    /// Nodes in the Steiner tree
    public let nodes: Set<String>
    
    /// Edges in the Steiner tree as (node1, node2, weight) tuples
    public let edges: [(String, String, Double)]
    
    /// Total cost/weight of the Steiner tree
    public let totalCost: Double
    
    public init(nodes: Set<String>, edges: [(String, String, Double)], totalCost: Double) {
        self.nodes = nodes
        self.edges = edges
        self.totalCost = totalCost
    }
}

// MARK: - Steiner Tree Finder

/// Finds Steiner tree covering terminal vertices in an undirected weighted graph
public class SteinerTreeFinder {
    private let graph: UndirectedWeightedGraph
    
    public init(graph: UndirectedWeightedGraph) {
        self.graph = graph
    }
    
    /// Find Steiner tree covering all terminal vertices
    ///
    /// Args:
    ///     terminals: Array of terminal node IDs that must be included in the tree
    ///
    /// Returns:
    ///     SteinerTreeResult containing nodes, edges, and total cost
    public func findSteinerTree(terminals: [String]) -> SteinerTreeResult {
        guard !terminals.isEmpty else {
            return SteinerTreeResult(nodes: [], edges: [], totalCost: 0.0)
        }
        
        // Validate all terminals exist in graph
        let validTerminals = terminals.filter { graph.hasNode($0) }
        guard !validTerminals.isEmpty else {
            return SteinerTreeResult(nodes: [], edges: [], totalCost: 0.0)
        }
        
        // Set of vertices in the Steiner tree
        var T: Set<String> = []
        // Set of processed vertices
        var isProcessed: Set<String> = []
        // Set of included edges (normalized: node1 < node2)
        var isIncluded: Set<String> = []
        // Total cost
        var totalCost: Double = 0.0
        
        // Step 1: Add first terminal vertex to T
        let firstTerminal = validTerminals[0]
        print("Terminal Vertex \"\(firstTerminal)\" is added to T")
        let (dist, _) = dijkstra(source: firstTerminal)
        isProcessed.insert(firstTerminal)
        T.insert(firstTerminal)
        
        // Step 2: While T does not span all terminals
        var count = 1
        while count < validTerminals.count {
            // Step 2a: Select a terminal x not in T that is closest to a vertex in T
            var x: String? = nil
            var minDist = Double.infinity
            
            for i in 1..<validTerminals.count {
                let terminal = validTerminals[i]
                if !isProcessed.contains(terminal) {
                    if let distance = dist[terminal], distance > 0 && distance < minDist {
                        minDist = distance
                        x = terminal
                    }
                }
            }
            
            guard let nextTerminal = x else {
                break
            }
            
            print("Next Terminal Vertex to be added to T is: \"\(nextTerminal)\"")
            
            // Step 2b: Find vertex in T which is closest to next terminal vertex
            var minCost = Double.infinity
            var sourceVertex: String = ""
            
            for vertexInT in T {
                let (tempDist, tempParent) = dijkstra(source: vertexInT)
                
                guard let distanceToNext = tempDist[nextTerminal], distanceToNext < Double.infinity else {
                    continue
                }
                
                // Calculate cost of path from vertexInT to nextTerminal
                let path = findParentPath(parent: tempParent, from: vertexInT, to: nextTerminal)
                var cost: Double = 0.0
                
                for j in 0..<path.count {
                    if j == 0 {
                        let edgeKey = normalizeEdge(vertexInT, path[0])
                        if !isIncluded.contains(edgeKey) {
                            if let weight = graph.getWeight(node1: vertexInT, node2: path[0]) {
                                cost += weight
                            }
                        }
                    } else {
                        let edgeKey = normalizeEdge(path[j-1], path[j])
                        if !isIncluded.contains(edgeKey) {
                            if let weight = graph.getWeight(node1: path[j-1], node2: path[j]) {
                                cost += weight
                            }
                        }
                    }
                }
                
                if cost < minCost {
                    minCost = cost
                    sourceVertex = vertexInT
                }
            }
            
            // Connect nextTerminal with sourceVertex in T
            let (_, finalParent) = dijkstra(source: sourceVertex)
            let path = findParentPath(parent: finalParent, from: sourceVertex, to: nextTerminal)
            
            for j in 0..<path.count {
                if j == 0 {
                    let edgeKey = normalizeEdge(sourceVertex, path[0])
                    if !isIncluded.contains(edgeKey) {
                        isIncluded.insert(edgeKey)
                        if let weight = graph.getWeight(node1: sourceVertex, node2: path[0]) {
                            totalCost += weight
                        }
                        
                        if !isProcessed.contains(path[0]) {
                            isProcessed.insert(path[0])
                            T.insert(path[0])
                        }
                    }
                } else {
                    let edgeKey = normalizeEdge(path[j-1], path[j])
                    if !isIncluded.contains(edgeKey) {
                        isIncluded.insert(edgeKey)
                        if let weight = graph.getWeight(node1: path[j-1], node2: path[j]) {
                            totalCost += weight
                        }
                        
                        if !isProcessed.contains(path[j-1]) {
                            isProcessed.insert(path[j-1])
                            T.insert(path[j-1])
                        }
                        if !isProcessed.contains(path[j]) {
                            isProcessed.insert(path[j])
                            T.insert(path[j])
                        }
                    }
                }
            }
            
            count += 1
        }
        
        // Build edges list from isIncluded set
        var edges: [(String, String, Double)] = []
        for edgeKey in isIncluded {
            let components = edgeKey.split(separator: "-")
            let node1 = String(components[0])
            let node2 = String(components[1])
            if let weight = graph.getWeight(node1: node1, node2: node2) {
                edges.append((node1, node2, weight))
            }
        }
        
        return SteinerTreeResult(nodes: T, edges: edges, totalCost: totalCost)
    }
    
    // MARK: - Helper Methods
    
    /// Dijkstra's single source shortest path algorithm
    ///
    /// Args:
    ///     source: Source node ID
    ///
    /// Returns:
    ///     Tuple of (distance dictionary, parent dictionary)
    private func dijkstra(source: String) -> ([String: Double], [String: String?]) {
        var dist: [String: Double] = [:]
        var parent: [String: String?] = [:]
        var sptSet: Set<String> = []
        
        // Initialize all distances as infinite
        for node in graph.allNodes() {
            dist[node.id] = Double.infinity
            parent[node.id] = nil
        }
        
        // Distance of source vertex from itself is always 0
        dist[source] = 0.0
        parent[source] = nil
        
        // Find shortest path for all vertices
        let allNodeIds = Set(graph.allNodes().map { $0.id })
        
        while sptSet.count < allNodeIds.count {
            // Pick the minimum distance vertex not yet processed
            var minDist = Double.infinity
            var u: String? = nil
            
            for nodeId in allNodeIds {
                if !sptSet.contains(nodeId), let distance = dist[nodeId], distance < minDist {
                    minDist = distance
                    u = nodeId
                }
            }
            
            guard let current = u else {
                break
            }
            
            // Mark the picked vertex as processed
            sptSet.insert(current)
            
            // Update dist value of the adjacent vertices
            let neighbors = graph.getNeighbors(of: current)
            for neighbor in neighbors {
                if !sptSet.contains(neighbor),
                   let currentDist = dist[current],
                   currentDist < Double.infinity,
                   let edgeWeight = graph.getWeight(node1: current, node2: neighbor) {
                    let newDist = currentDist + edgeWeight
                    if let neighborDist = dist[neighbor], newDist < neighborDist {
                        parent[neighbor] = current
                        dist[neighbor] = newDist
                    }
                }
            }
        }
        
        return (dist, parent)
    }
    
    /// Find path from source to target using parent dictionary
    ///
    /// Args:
    ///     parent: Parent dictionary from Dijkstra
    ///     from: Source node ID
    ///     to: Target node ID
    ///
    /// Returns:
    ///     Array of node IDs representing the path (excluding source, including target)
    private func findParentPath(parent: [String: String?], from: String, to: String) -> [String] {
        var path: [String] = []
        var current: String? = to
        
        // Build path backwards from target to source
        while let node = current, node != from {
            path.insert(node, at: 0)
            current = parent[node] ?? nil
        }
        
        return path
    }
    
    /// Normalize edge key (node1 < node2 lexicographically)
    ///
    /// Args:
    ///     node1: First node ID
    ///     node2: Second node ID
    ///
    /// Returns:
    ///     Normalized edge key string
    private func normalizeEdge(_ node1: String, _ node2: String) -> String {
        return node1 < node2 ? "\(node1)-\(node2)" : "\(node2)-\(node1)"
    }
}
