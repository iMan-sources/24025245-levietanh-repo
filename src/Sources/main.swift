import Foundation
import Rainbow

// Get the path to the Airport.puml file
let currentFile = #file
let currentDir = (currentFile as NSString).deletingLastPathComponent
let airportPath = (currentDir as NSString).appendingPathComponent("resources/dataset/InvoicingOrders.puml")
// Configuration
let spec = "The stock of a Product is always a natural number, i.e., it is a positive Integer. This also ensures the definedness of the stock.."
let k = 5  // Number of top results to return

@available(macOS 15.0, *)
func main() async {
    // IMPORTANT: Xcode's console does NOT support ANSI color codes
    // Colors will only appear when running from Terminal (not Xcode console)
    // To see colors: Run the program from Terminal using: swift run
    // Rainbow automatically detects terminal support and enables/disables colors accordingly
    
    print("===== Airport PUML Example =====")
    let converter = PUMLToGraphConverter()
    let graphExtractor = GraphExtractor()
    let embedder = Embedder()
    
    do {
        // MARK: Step 1: Create converter and process the Airport.puml file
        
        let graph = try converter.convertFile(filepath: airportPath)
        print("Graph loaded with \(graph.numberOfNodes()) nodes".applyingAll(color: .named(.green), styles: [.bold]))
        
//        let undirectedGraph = graph.toUndirectedWeightedGraph()
        let visualizerDir = (currentDir as NSString).appendingPathComponent("visualizer")
//        let jsonPath = (visualizerDir as NSString).appendingPathComponent("graph-data.json")
//        try undirectedGraph.exportToJSON(filepath: jsonPath)
//        let json = undirectedGraph.toJSON()
        let jsonPath = (visualizerDir as NSString).appendingPathComponent("graph-data.json")
        try graph.exportToJSON(filepath: jsonPath)
        
        // MARK: Step 2: Extract desc candidates from graph nodes
        let mapping = graphExtractor.extractDesc(from: graph)
        print("Extracted \(mapping.candidates.count) candidates from graph".applyingAll(color: .named(.green), styles: [.bold]))
        
        guard !mapping.candidates.isEmpty else {
            print("No candidates found in graph".applyingAll(color: .named(.red), styles: [.bold]))
            return
        }
        
        // MARK:  Step 3: Embed candidates and compute distances
        let input: Embedder.EmbedderInput = (spec: spec, candidates: mapping.candidates)
        let distances = try await embedder.loadAndEmbed(input)
        
        // MARK: Step 4: Find top-k unique nodes with minimum distance
        let topK = embedder.findTopK(distances: distances, nodeIds: mapping.nodeIds, k: k)
        let undirectedGraph = graph.toUndirectedWeightedGraph()
        
        // MARK: Step 5: Print results
        print("\n--- Top \(k) nodes matching spec ---".applyingAll(color: .named(.green), styles: [.bold]))
        print("Spec: \"\(spec)\"\n")
        
        for (rank, result) in topK.enumerated() {
            print("\(rank + 1). Node: \(result.nodeId)")
            print("   Distance: \(String(format: "%.4f", result.distance))")
            print("")
        }
        
        // MARK: Step 6: Find Steiner tree covering top-k nodes
        print("\n--- Steiner Tree for Top \(k) Nodes ---".applyingAll(color: .named(.green), styles: [.bold]))
        let terminalNodes = topK.map { $0.nodeId }
        let steinerFinder = SteinerTreeFinder(graph: undirectedGraph)
        let steinerResult = steinerFinder.findSteinerTree(terminals: terminalNodes)
        
         print("\nSteiner Tree Results:".applyingAll(color: .named(.green), styles: [.bold]))
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
        
        // MARK: Step 7: Extract class information from Steiner tree
        let classInfos = graphExtractor.extractClassInformation(from: graph,
                                                                steinerResult: steinerResult,
                                                                onlySteinerNodes: true)
        

        // MARK: Step 8: Generate prompt for LLM
        let promptGenerator = PromptGenerator()
        let userPrompt = promptGenerator.generatePrompt(from: classInfos)
        print("User prompt: \(userPrompt)".applyingAll(color: .named(.green), styles: [.bold]))

        // TODO: concate prompt with system prompt
        let systemPrompt = """
        As a system designer with expertise in UML modeling and OCL constraints, your role is to assist the user in writing OCL constraints. The user will provide you with the following information:
        (1) The specification in natural language.
        (2) The UML classes and their properties (attributes, operations, associations).
        Your objective is to generate a valid OCL constraint according to the provided UML classes. Please do not provide explanation. Put your solution in a <OCL> tag.
        """
        let fullPrompt = "\(systemPrompt)\n\n-- OCL specification\n \(spec) \n\n\(userPrompt)\n-- OCL constraint"

        print(fullPrompt.applyingAll(color: .named(.yellow), styles: [.bold]))
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

