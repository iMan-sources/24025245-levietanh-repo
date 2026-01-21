/// PlantUML to Graph Converter
///
/// Main module that converts PlantUML class diagrams to typed property graphs,
/// following the conversion rules specified in the documentation.
///
/// This implementation corresponds to the Python PUMLToGraphConverter class in puml_to_graph.py
///
/// Example usage:
///     let converter = PUMLToGraphConverter()
///     let graph = try converter.convertFile(filepath: "Airport.puml")
///     print("Graph has \(graph.numberOfNodes()) nodes")

import Foundation

/// Converts PlantUML class diagrams to typed property graphs
///
/// This class provides functionality to parse PlantUML files and convert them
/// into MultiDiGraph representations, following specific conversion rules.
///
/// Example:
///     let converter = PUMLToGraphConverter()
///     let graph = try converter.convertFile(filepath: "diagram.puml")
///     print("Graph has \(graph.numberOfNodes()) nodes")
public class PUMLToGraphConverter {
    /// Parser for PlantUML content
    private let parser: PUMLParser
    
    /// Builder for constructing graphs
    private let builder: GraphBuilder
    
    /// Initialize the converter with parser and builder instances
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let graph = try converter.convertFile(filepath: "my_diagram.puml")
    public init() {
        // Initialize parser and builder as instance attributes to allow reuse
        // across multiple file conversions without recreating them
        self.parser = PUMLParser()
        self.builder = GraphBuilder()
    }
    
    // MARK: - File Parsing
    
    /// Parse a PUML file into structured data
    ///
    /// Args:
    ///     filepath: Path to the .puml file to parse
    ///
    /// Returns:
    ///     ParsedData structure containing parsed PUML data
    ///
    /// Throws:
    ///     Error if the file cannot be read or parsed
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let data = try converter.parseFile(filepath: "diagram.puml")
    ///     print("Found \(data.classes.count) classes")
    public func parseFile(filepath: String) throws -> ParsedData {
        // Use UTF-8 encoding to properly handle special characters and international text
        // that may appear in class names, comments, or string literals
        let content = try String(contentsOfFile: filepath, encoding: .utf8)
        
        // Delegate to parser to handle PUML syntax parsing
        let parsedData = try parser.parserPUML(content: content)
        
        return parsedData
    }
    
    // MARK: - Graph Building
    
    /// Convert parsed PUML data to MultiDiGraph
    ///
    /// Args:
    ///     parsedData: ParsedData structure containing parsed PUML
    ///
    /// Returns:
    ///     MultiDiGraph representation of the UML diagram
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let data = try converter.parseFile(filepath: "diagram.puml")
    ///     let graph = converter.buildGraph(parsedData: data)
    public func buildGraph(parsedData: ParsedData) -> MultiDiGraph {
        // NOTE: Uses MultiDiGraph to support multiple edges between same node pair
        // (e.g., multiple associations between two classes with different roles)
        let graph = builder.buildGraph(parsedData: parsedData)
        
        return graph
    }
    
    // MARK: - Main Conversion Method
    
    /// Main entry point: parse PUML file and return MultiDiGraph
    ///
    /// This method combines parsing and graph building in one step.
    ///
    /// Args:
    ///     filepath: Path to the .puml file to convert
    ///
    /// Returns:
    ///     MultiDiGraph with warnings stored in graph.metadata["warnings"]
    ///
    /// Throws:
    ///     Error if the file cannot be read or parsed
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let graph = try converter.convertFile(filepath: "diagram.puml")
    ///     if let warnings = graph.metadata["warnings"] as? [String] {
    ///         print("Warnings: \(warnings)")
    ///     }
    public func convertFile(filepath: String) throws -> MultiDiGraph {
        // Step 1: Parse the PUML file into structured data
        let parsedData = try parseFile(filepath: filepath)
        
        // Step 2: Convert parsed data into MultiDiGraph structure
        let graph = buildGraph(parsedData: parsedData)
        
        // Step 3: Preserve warnings from parsing phase in the graph metadata
        // This allows downstream consumers to access parsing warnings without
        // losing them during the conversion process
        graph.metadata["warnings"] = parsedData.warnings
        
        return graph
    }
    
    /// Parse PUML content string and return MultiDiGraph
    ///
    /// This is a convenience method for parsing PUML content directly
    /// without reading from a file.
    ///
    /// Args:
    ///     content: PUML content as a string
    ///
    /// Returns:
    ///     MultiDiGraph with warnings stored in graph.metadata["warnings"]
    ///
    /// Throws:
    ///     Error if the content cannot be parsed
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let pumlContent = """
    ///         @startuml
    ///         class Airport {
    ///             name: String
    ///         }
    ///         @enduml
    ///         """
    ///     let graph = try converter.convertContent(content: pumlContent)
    public func convertContent(content: String) throws -> MultiDiGraph {
        // Step 1: Parse the PUML content into structured data
        let parsedData = try parser.parserPUML(content: content)
        
        // Step 2: Convert parsed data into MultiDiGraph structure
        let graph = buildGraph(parsedData: parsedData)
        
        // Step 3: Preserve warnings
        graph.metadata["warnings"] = parsedData.warnings
        
        return graph
    }
    
    // MARK: - Batch Processing
    
    /// Process all .puml files in directory and return dict mapping filename → graph
    ///
    /// Args:
    ///     datasetDir: Path to directory containing .puml files
    ///
    /// Returns:
    ///     Dictionary mapping filename to graph (nil if processing failed)
    ///
    /// Example:
    ///     let converter = PUMLToGraphConverter()
    ///     let graphs = converter.processDataset(datasetDir: "./diagrams")
    ///     let successful = graphs.filter { $0.value != nil }
    ///     print("Successfully processed \(successful.count) files")
    public func processDataset(datasetDir: String) -> [String: MultiDiGraph?] {
        var graphs: [String: MultiDiGraph?] = [:]
        
        // Get all .puml files in directory
        guard let enumerator = FileManager.default.enumerator(atPath: datasetDir) else {
            print("Error: Cannot access directory \(datasetDir)")
            return graphs
        }
        
        // Filter for .puml files
        let pumlFiles = enumerator.compactMap { $0 as? String }
            .filter { $0.hasSuffix(".puml") }
            .map { datasetDir + "/" + $0 }
        
        // Process each file independently to ensure one failure doesn't stop the batch
        for pumlFile in pumlFiles {
            let filename = (pumlFile as NSString).lastPathComponent
            
            do {
                let graph = try convertFile(filepath: pumlFile)
                graphs[filename] = graph
            } catch {
                // Print error but continue processing remaining files
                print("Error processing \(filename): \(error)")
                
                // Store nil to distinguish between "not processed" and "successfully processed"
                // This allows callers to identify which files failed
                graphs[filename] = nil
            }
        }
        
        return graphs
    }
    
    // MARK: - Statistics
    
    /// Get statistics about a converted graph
    ///
    /// Args:
    ///     graph: MultiDiGraph to analyze
    ///
    /// Returns:
    ///     Dictionary with statistics
    ///
    /// Example:
    ///     let stats = converter.getGraphStatistics(graph: graph)
    ///     print("Nodes: \(stats["totalNodes"])")
    public func getGraphStatistics(graph: MultiDiGraph) -> [String: Any] {
        let stats = graph.getStatistics()
        
        return [
            "totalNodes": stats.totalNodes,
            "totalEdges": stats.totalEdges,
            "nodeTypeCount": stats.nodeTypeCount,
            "edgeTypeCount": stats.edgeTypeCount
        ]
    }
}

// MARK: - Convenience Functions

/// Parse a PUML file into structured data (convenience function)
///
/// Args:
///     filepath: Path to the .puml file to parse
///
/// Returns:
///     ParsedData structure containing parsed PUML data
///
/// Throws:
///     Error if the file cannot be read or parsed
public func parsePUMLFile(filepath: String) throws -> ParsedData {
    // Create new instance for stateless operation - ensures no side effects
    let converter = PUMLToGraphConverter()
    return try converter.parseFile(filepath: filepath)
}

/// Convert parsed PUML data to MultiDiGraph (convenience function)
///
/// Args:
///     parsedData: ParsedData structure containing parsed PUML
///
/// Returns:
///     MultiDiGraph representation of the UML diagram
public func buildGraph(parsedData: ParsedData) -> MultiDiGraph {
    // Create new instance for stateless operation
    let converter = PUMLToGraphConverter()
    return converter.buildGraph(parsedData: parsedData)
}

/// Main entry point: parse PUML file and return MultiDiGraph (convenience function)
///
/// Args:
///     filepath: Path to the .puml file to convert
///
/// Returns:
///     MultiDiGraph with warnings stored in graph.metadata["warnings"]
///
/// Throws:
///     Error if the file cannot be read or parsed
public func pumlToGraph(filepath: String) throws -> MultiDiGraph {
    // Create new instance for stateless operation
    let converter = PUMLToGraphConverter()
    return try converter.convertFile(filepath: filepath)
}

/// Process all .puml files in directory (convenience function)
///
/// Args:
///     datasetDir: Path to directory containing .puml files
///
/// Returns:
///     Dictionary mapping filename to graph (nil if processing failed)
public func processDataset(datasetDir: String) -> [String: MultiDiGraph?] {
    // Create new instance for stateless operation
    let converter = PUMLToGraphConverter()
    return converter.processDataset(datasetDir: datasetDir)
}
