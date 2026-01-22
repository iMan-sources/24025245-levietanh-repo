import Foundation

// MARK: - Candidate Mapping for Embedding Search

/// Maps embedding candidates back to their source node IDs
struct CandidateMapping {
    /// Text candidates to embed
    let candidates: [String]
    /// Node ID for each candidate (nodeIds[i] corresponds to candidates[i])
    let nodeIds: [String]
}

/// Extract text candidates from graph nodes for embedding
/// - For Class/Enumeration nodes: uses normalized_text array (each component becomes a candidate)
/// - For other nodes: uses semantic_desc string
/// - Parameter graph: The MultiDiGraph containing all nodes
/// - Returns: CandidateMapping with candidates and their corresponding node IDs
func extractCandidates(from graph: MultiDiGraph) -> CandidateMapping {
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

@available(macOS 15.0, *)
func main() async {
    print("=========")
    // Get the path to the Airport.puml file
    let currentFile = #file
    let currentDir = (currentFile as NSString).deletingLastPathComponent
    let airportPath = (currentDir as NSString).appendingPathComponent("resources/dataset/Airport.puml")
    
    // Configuration
    let spec = "The maximum number of passengers on any flight may not exceed 1000"
    let k = 5  // Number of top results to return
    
    do {
        // Step 1: Create converter and process the Airport.puml file
        let converter = PUMLToGraphConverter()
        let graph = try converter.convertFile(filepath: airportPath)
        print("Graph loaded with \(graph.numberOfNodes()) nodes")
        
        // Step 2: Extract candidates from graph nodes
        let mapping = extractCandidates(from: graph)
        print("Extracted \(mapping.candidates.count) candidates from graph")
        
        guard !mapping.candidates.isEmpty else {
            print("No candidates found in graph")
            return
        }
        
        // Step 3: Embed candidates and compute distances
        let embedder = Embedder()
        let input: Embedder.EmbedderInput = (spec: spec, candidates: mapping.candidates)
        let distances = try await embedder.loadAndEmbed(input)
        
        // Step 4: Find top-k unique nodes with minimum distance
        let topK = embedder.findTopK(distances: distances, nodeIds: mapping.nodeIds, k: k)
        
        // Step 5: Print results
        print("\n--- Top \(k) nodes matching spec ---")
        print("Spec: \"\(spec)\"\n")
        
        for (rank, result) in topK.enumerated() {
            print("\(rank + 1). Node: \(result.nodeId)")
            print("   Distance: \(String(format: "%.4f", result.distance))")
            print("")
        }
        
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}


// Entry point
if #available(macOS 15.0, *) {
    Task {
        await main()
        exit(0)
    }
    RunLoop.main.run()
    
}
