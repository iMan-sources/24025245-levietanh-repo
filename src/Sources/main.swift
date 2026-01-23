import Foundation
import Embeddings
import MLTensorUtils
// Get the path to the Airport.puml file
let currentFile = #file
let currentDir = (currentFile as NSString).deletingLastPathComponent
let airportPath = (currentDir as NSString).appendingPathComponent("resources/dataset/InvoicingOrders.puml")
// Configuration
let spec = "The stock of a Product is always a natural number, i.e., it is a positive Integer. This also ensures the definedness of the stock.."
let k = 5  // Number of top results to return

@available(macOS 15.0, *)
func main() async {
    print("===== Airport PUML Example =====")
    let converter = PUMLToGraphConverter()
    let graphExtractor = GraphExtractor()
    let embedder = Embedder()
    
    do {
        // Step 1: Create converter and process the Airport.puml file
        
        let graph = try converter.convertFile(filepath: airportPath)
        print("Graph loaded with \(graph.numberOfNodes()) nodes")
        
//        let undirectedGraph = graph.toUndirectedWeightedGraph()
        let visualizerDir = (currentDir as NSString).appendingPathComponent("visualizer")
//        let jsonPath = (visualizerDir as NSString).appendingPathComponent("graph-data.json")
//        try undirectedGraph.exportToJSON(filepath: jsonPath)
//        let json = undirectedGraph.toJSON()
        let jsonPath = (visualizerDir as NSString).appendingPathComponent("graph-data.json")
        try graph.exportToJSON(filepath: jsonPath)
        
        // Step 2: Extract desc candidates from graph nodes
        let mapping = graphExtractor.extractDesc(from: graph)
        print("Extracted \(mapping.candidates.count) candidates from graph")
        
        guard !mapping.candidates.isEmpty else {
            print("No candidates found in graph")
            return
        }
        
        // Step 3: Embed candidates and compute distances
        let input: Embedder.EmbedderInput = (spec: spec, candidates: mapping.candidates)
        let distances = try await embedder.loadAndEmbed(input)
        
        // Step 4: Find top-k unique nodes with minimum distance
        let topK = embedder.findTopK(distances: distances, nodeIds: mapping.nodeIds, k: k)
        let undirectedGraph = graph.toUndirectedWeightedGraph()
        
        // Step 5: Print results
        print("\n--- Top \(k) nodes matching spec ---")
        print("Spec: \"\(spec)\"\n")
        
        for (rank, result) in topK.enumerated() {
            print("\(rank + 1). Node: \(result.nodeId)")
            print("   Distance: \(String(format: "%.4f", result.distance))")
            print("")
        }
        
//        // Step 6: Find Steiner tree covering top-k nodes
        print("\n--- Steiner Tree for Top \(k) Nodes ---")
        let terminalNodes = topK.map { $0.nodeId }
        let steinerFinder = SteinerTreeFinder(graph: undirectedGraph)
        let steinerResult = steinerFinder.findSteinerTree(terminals: terminalNodes)
        
        print("\nSteiner Tree Results:")
        print("Total Cost: \(String(format: "%.4f", steinerResult.totalCost))")
        print("Nodes in Steiner Tree: \(steinerResult.nodes.count)")
        print("\nNodes:")
        for node in steinerResult.nodes.sorted() {
            print("  - \(node)")
        }
        print("\nEdges:")
        for (node1, node2, weight) in steinerResult.edges.sorted(by: { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }) {
            print("  - \(node1) <-> \(node2) (weight: \(String(format: "%.4f", weight)))")
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

