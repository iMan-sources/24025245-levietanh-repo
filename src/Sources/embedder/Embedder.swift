//
//  File.swift
//  ThesisCLI
//
//  Created by Le Anh on 22/1/26.
//

import Foundation

@available(macOS 15.0, *)
class Embedder {
    typealias EmbedderInput = (spec: String, candidates: [String])
    
    func loadAndEmbed(_ input: EmbedderInput) async throws -> [Float] {
        // Create URL for the calculate-distances endpoint
        guard let url = URL(string: "http://localhost:6868/calculate-distances") else {
            throw URLError(.badURL)
        }
        
        // Create URLRequest with POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request payload
        let requestBody: [String: Any] = [
            "spec": input.spec,
            "candidates": input.candidates
        ]
        
        // Encode request body to JSON
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw NSError(domain: "EmbedderError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body to JSON: \(error.localizedDescription)"])
        }
        request.httpBody = jsonData
        
        // Perform network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "EmbedderError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "EmbedderError", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "HTTP request failed with status code \(httpResponse.statusCode)"
            ])
        }
        
        // Decode JSON response
        let jsonObject: [String: Any]
        do {
            guard let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(domain: "EmbedderError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Response is not a valid JSON object"])
            }
            jsonObject = decoded
        } catch {
            throw NSError(domain: "EmbedderError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(error.localizedDescription)"])
        }
        
        guard let distancesArray = jsonObject["distances"] as? [NSNumber] else {
            throw NSError(domain: "EmbedderError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid 'distances' field in response"])
        }
        
        // Convert NSNumber array to Float array
        let distances = distancesArray.map { $0.floatValue }
        
        return distances
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
