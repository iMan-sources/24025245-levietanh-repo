import Foundation

// Get the path to the Airport.puml file
let currentFile = #file
let currentDir = (currentFile as NSString).deletingLastPathComponent
let airportPath = (currentDir as NSString).appendingPathComponent("resources/dataset/Airport.puml")
// Configuration
let spec = "The maximum number of passengers on any flight may not exceed 1000"
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
