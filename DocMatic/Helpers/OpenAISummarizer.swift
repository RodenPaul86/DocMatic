//
//  OpenAISummarizer.swift
//  DocMatic
//
//  Created by Paul  on 8/21/25.
//

import Foundation

struct OpenAIResponse: Decodable {
    // The Responses API often includes this convenience field:
    let output_text: String?
    // Fallback structure if we need to stitch from content parts:
    struct Output: Decodable {
        struct ContentItem: Decodable {
            let type: String?
            let text: String?
        }
        let content: [ContentItem]?
    }
    let output: [Output]?
    let id: String?
}

enum OpenAIClientError: Error, LocalizedError {
    case missingAPIKey
    case emptyInput
    case badStatus(Int, String)
    case decodeFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing OpenAI API key."
        case .emptyInput:    return "No text to summarize."
        case .badStatus(let code, let body): return "OpenAI returned \(code): \(body)"
        case .decodeFailed:  return "Failed to decode OpenAI response."
        }
    }
}

final class OpenAISummarizer {
    private let apiKey: String
    private let session: URLSession
    private let model: String
    
    init(apiKey: String, model: String = "gpt-4o-mini", session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }
    
    /// Public entry: robust summarization with chunking + final pass
    func summarizeDocument(_ fullText: String,
                           targetWords: Int = 180) async throws -> String {
        guard !apiKey.isEmpty else { throw OpenAIClientError.missingAPIKey }
        let cleaned = fullText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw OpenAIClientError.emptyInput }
        
        // Very rough character-based chunking to stay within model context.
        // (Adjust ~12k as needed; gpt-4o-mini supports large contexts.)
        let chunks = chunk(cleaned, maxChars: 12_000)
        
        if chunks.count == 1 {
            return try await summarizeChunk(chunks[0], targetWords: targetWords)
        } else {
            // 1) Summarize each chunk
            let partials = try await withThrowingTaskGroup(of: String.self) { group -> [String] in
                for c in chunks {
                    group.addTask { try await self.summarizeChunk(c, targetWords: max(140, targetWords/2)) }
                }
                var results: [String] = []
                for try await r in group { results.append(r) }
                return results
            }
            // 2) Summarize the summaries
            let joined = partials.joined(separator: "\n\n")
            return try await summarizeChunk(joined, targetWords: targetWords,
                                            systemPreamble: "You are a careful editor making a single, cohesive summary from section summaries.")
        }
    }
    
    // MARK: - Internals
    
    private func summarizeChunk(_ text: String,
                                targetWords: Int,
                                systemPreamble: String? = nil) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prompt: concise, faithful, and structured.
        let prompt = """
        Summarize the following text into a clear, concise paragraph (3–5 sentences). 
        Avoid repetition, filler words, and keep it easy to read.
        
        Text:
        \(text)
        """
        
        // Minimal body for Responses API
        let body: [String: Any] = [
            "model": model,
            "input": systemPreamble.map { "\($0)\n\n\(prompt)" } ?? prompt,
            "temperature": 0.2,
            "max_output_tokens": 600
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse else {
            throw OpenAIClientError.decodeFailed
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIClientError.badStatus(http.statusCode, bodyText)
        }
        
        let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data)
        if let text = decoded?.output_text, !text.isEmpty {
            return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        if let contentArrays = decoded?.output?.compactMap(\.content) {
            let allItems = contentArrays.flatMap { $0 }
            let combined = allItems.compactMap { $0.text }.joined()
            if !combined.isEmpty { return combined.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        }
        // Fallback: raw body (useful for debugging schema changes)
        return (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    private func chunk(_ text: String, maxChars: Int) -> [String] {
        guard text.count > maxChars else { return [text] }
        var chunks: [String] = []
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: maxChars, limitedBy: text.endIndex) ?? text.endIndex
            var slice = String(text[start..<end])
            
            // try to cut at a paragraph boundary for nicer splits
            if end != text.endIndex, let lastNL = slice.lastIndex(of: "\n") {
                slice = String(slice[..<lastNL])
                start = text.index(after: lastNL)
            } else {
                start = end
            }
            chunks.append(slice)
        }
        return chunks
    }
}
