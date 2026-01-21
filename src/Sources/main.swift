import Foundation

func main() {
    print("=== PUML to Graph Converter Demo ===")
    print("Swift version: \(getSwiftVersion())")
    print()
    
    // Get the path to the Airport.puml file
    let currentFile = #file
    let currentDir = (currentFile as NSString).deletingLastPathComponent
    let airportPath = (currentDir as NSString).appendingPathComponent("resources/dataset/Airport.puml")
    
    print("Converting: \(airportPath)")
    print()
    
    do {
        // Create converter and process the Airport.puml file
        let converter = PUMLToGraphConverter()
        let graph = try converter.convertFile(filepath: airportPath)
        
        // Display results
        print("✓ Conversion successful!")
        print()
        
        // Show warnings if any
        if let warnings = graph.metadata["warnings"] as? [String], !warnings.isEmpty {
            print("⚠️  Warnings (\(warnings.count)):")
            for warning in warnings {
                print("  - \(warning)")
            }
            print()
        }
        
        // Display graph statistics
        print("📊 Graph Statistics:")
        let stats = converter.getGraphStatistics(graph: graph)
        print("  Total Nodes: \(stats["totalNodes"] ?? 0)")
        print("  Total Edges: \(stats["totalEdges"] ?? 0)")
        print()
        
        if let nodeTypeCounts = stats["nodeTypeCount"] as? [String: Int] {
            print("  Node Types:")
            for (type, count) in nodeTypeCounts.sorted(by: { $0.key < $1.key }) {
                print("    - \(type): \(count)")
            }
            print()
        }
        
        if let edgeTypeCounts = stats["edgeTypeCount"] as? [String: Int] {
            print("  Edge Types:")
            for (type, count) in edgeTypeCounts.sorted(by: { $0.key < $1.key }) {
                print("    - \(type): \(count)")
            }
            print()
        }
        
        // Display detailed graph information
        print("🔍 Detailed Graph Information:")
        print("  Nodes (\(graph.numberOfNodes())):")
        let allNodes = graph.allNodes().sorted(by: { $0.id < $1.id })
        for node in allNodes {
            let nodeType = node.attributes["type"] as? String ?? "Unknown"
            let nodeName = node.attributes["name"] as? String ?? node.id
            print("    - [\(node.id)] \(nodeName) (type: \(nodeType))")
        }
        print()
        
        print("  Edges (\(graph.numberOfEdges())):")
        for edge in graph.allEdges() {
            let edgeType = edge.attributes["type"] as? String ?? "Unknown"
            let label = edge.attributes["label"] as? String ?? edgeType
            print("    - [\(edge.source)] --[\(label)]-> [\(edge.destination)]")
        }
        
    } catch {
        print("❌ Error: \(error)")
        print()
        printUsage()
    }
}

func getSwiftVersion() -> String {
    #if swift(>=5.9)
    return "5.9+"
    #elseif swift(>=5.8)
    return "5.8+"
    #else
    return "Unknown"
    #endif
}

func printUsage() {
    print("""
    Usage:
        This demo converts the Airport.puml file to a typed property graph.
        
    To run:
        swift run
    """)
}

// Entry point
main()
