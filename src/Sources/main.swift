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
        print(graph.allNodes().map({$0}))
    } catch {
        print("Error: \(error.localizedDescription)")
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
