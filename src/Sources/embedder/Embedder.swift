//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 22/1/26.
//

import Foundation
import Embeddings
import MLTensorUtils


@available(macOS 15.0, *)
class Embedder {
    var modelBundle: Bert.ModelBundle?
    typealias EmbedderInput = (spec: String, candidates: [String])
    let texts = [
        "The cat is black",
        "The dog is black",
        "The cat sleeps well"
    ]
    
    func loadAndEmbed(_ input: EmbedderInput) async throws -> [Float]{
        // load model and tokenizer from Hugging Face
        let modelBundle = try await Bert.loadModelBundle(
            from: "sentence-transformers/all-MiniLM-L6-v2"
        )
        let encodedCandidates = try modelBundle.batchEncode(input.candidates)
        let encodedSpec = try modelBundle.encode(input.spec)
        let distance = cosineDistance(encodedSpec, encodedCandidates)
        let result = await distance.cast(to: Float.self).shapedArray(of: Float.self).scalars
        return result
    }
    
    /// Find top-k unique nodeIds with minimum cosine distance
    /// - Parameters:
    ///   - distances: Array of cosine distances
    ///   - nodeIds: Array of node IDs corresponding to each distance
    ///   - k: Number of top results to return
    /// - Returns: Array of (nodeId, distance) tuples sorted by ascending distance, deduplicated by nodeId
    func findTopK(distances: [Float], nodeIds: [String], k: Int) -> [(nodeId: String, distance: Float)] {
        // Group by nodeId and keep minimum distance for each
        var minDistanceByNode: [String: Float] = [:]
        
        for (index, distance) in distances.enumerated() {
            let nodeId = nodeIds[index]
            if let existingDistance = minDistanceByNode[nodeId] {
                // Keep the minimum distance
                minDistanceByNode[nodeId] = min(existingDistance, distance)
            } else {
                minDistanceByNode[nodeId] = distance
            }
        }
        
        // Convert to array and sort by distance (ascending - smaller distance = more similar)
        let sorted = minDistanceByNode
            .map { (nodeId: $0.key, distance: $0.value) }
            .sorted { $0.distance < $1.distance }
        
        // Take top k
        let topK = Array(sorted.prefix(k))
        
        return topK
    }
}
