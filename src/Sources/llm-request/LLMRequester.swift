import Foundation

/// Global configuration for OpenAI access.
/// - Note: Set these from your application bootstrap before issuing any requests.
public var OPENAI_API_KEY: String = "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"
public var OPENAI_MODEL: String = "gpt-4"

/// Errors that can occur while requesting a completion from the LLM.
public enum LLMRequesterError: Error, LocalizedError {
    case missingAPIKey
    case missingModel
    case invalidResponse
    case httpError(statusCode: Int, body: String?)
    case emptyChoices
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OPENAI_API_KEY is empty. Please configure your API key."
        case .missingModel:
            return "OPENAI_MODEL is empty. Please configure your model identifier."
        case .invalidResponse:
            return "The server returned an invalid response."
        case let .httpError(statusCode, body):
            if let body {
                return "HTTP error \(statusCode): \(body)"
            } else {
                return "HTTP error \(statusCode) with no response body."
            }
        case .emptyChoices:
            return "The completion response did not contain any choices."
        }
    }
}

/// Requester responsible for calling the OpenAI Chat Completions API.
public struct LLMRequester {
    private let apiKey: String
    private let model: String
    private let endpointURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    /// Create a new requester using the global configuration values by default.
    public init(apiKey: String = OPENAI_API_KEY, model: String = OPENAI_MODEL) {
        self.apiKey = apiKey
        self.model = model
    }
    
    /// Perform a chat completion request using the provided `Prompt`.
    ///
    /// - Parameter prompt: The system and user messages to send to the model.
    /// - Returns: The content of the first completion choice as a plain `String`.
    @available(macOS 15.0, *)
    func request(prompt: Prompt) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMRequesterError.missingAPIKey
        }
        guard !model.isEmpty else {
            throw LLMRequesterError.missingModel
        }
        
        let body = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: prompt.system),
                ChatMessage(role: "user", content: prompt.user)
            ]
        )
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMRequesterError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8)
            throw LLMRequesterError.httpError(statusCode: httpResponse.statusCode, body: responseBody)
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw LLMRequesterError.emptyChoices
        }
        
        return content
    }
}


