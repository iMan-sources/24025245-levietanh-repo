//
//  ChatMessage.swift
//  ThesisCLI
//
//  Created by Le Anh on 28/1/26.
//


public struct ChatMessage: Codable {
    let role: String
    let content: String
}

public struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
}

public struct ChatResponse: Codable {
    let choices: [Choice]
    
    public struct Choice: Codable {
        let message: ChatMessage
    }
}
