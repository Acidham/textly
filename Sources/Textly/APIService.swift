import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum APIError: Error, LocalizedError {
    case noAPIKey(APIProvider)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider):
            return "No API key set for \(provider.displayName). Open Settings to add your key."
        case .apiError(let msg):
            return msg
        }
    }
}

final class APIService: Sendable {
    static let shared = APIService()
    private init() {}

    private let systemPrompt = """
    You are a precise text transformation engine. Apply the following instruction to the text below.

    CRITICAL RULES:
    - Return ONLY the transformed text. No explanations, no commentary, no markdown formatting.
    - Preserve all newlines and whitespace unless the instruction specifically asks to change them.
    - If the text is empty and the instruction doesn't ask you to generate text, return an empty string.
    - Do not add any preamble like "Here is the transformed text:" — output the result directly.
    """

    @MainActor
    func transform(text: String, instruction: String, settings: SettingsManager) async throws -> String {
        let provider = settings.selectedProvider
        let apiKey: String
        let model: String

        switch provider {
        case .anthropic:
            apiKey = settings.anthropicApiKey
            model  = settings.anthropicModel
        case .openai:
            apiKey = settings.openaiApiKey
            model  = settings.openaiModel
        case .gemini:
            apiKey = settings.geminiApiKey
            model  = settings.geminiModel
        case .local:
            if #available(macOS 26.0, *) {
                return try await callLocal(instruction: instruction, text: text)
            } else {
                throw APIError.apiError("On-device model requires macOS 26 or later.")
            }
        }

        return try await callProvider(provider: provider, text: text, instruction: instruction, apiKey: apiKey, model: model)
    }

    private func userMessage(instruction: String, text: String) -> String {
        "INSTRUCTION: \(instruction)\n\nTEXT TO TRANSFORM:\n\(text)"
    }

    private func callProvider(provider: APIProvider, text: String, instruction: String, apiKey: String, model: String) async throws -> String {
        switch provider {
        case .anthropic: return try await callAnthropic(text: text, instruction: instruction, apiKey: apiKey, model: model)
        case .openai:    return try await callOpenAI(text: text, instruction: instruction, apiKey: apiKey, model: model)
        case .gemini:    return try await callGemini(text: text, instruction: instruction, apiKey: apiKey, model: model)
        case .local:     throw APIError.apiError("Internal error: local provider not routed correctly")
        }
    }

    // MARK: - On-Device (FoundationModels)

    @available(macOS 26.0, *)
    private func callLocal(instruction: String, text: String) async throws -> String {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw APIError.apiError("On-device model is not available. Ensure Apple Intelligence is enabled in System Settings.")
        }
        let session = LanguageModelSession(instructions: systemPrompt)
        let response = try await session.respond(to: userMessage(instruction: instruction, text: text))
        return response.content
        #else
        throw APIError.apiError("On-device model requires macOS 26 or later.")
        #endif
    }

    // MARK: - Anthropic

    private func callAnthropic(text: String, instruction: String, apiKey: String, model: String) async throws -> String {
        guard !apiKey.isEmpty else { throw APIError.noAPIKey(.anthropic) }

        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "messages": [
                ["role": "user", "content": "\(systemPrompt)\n\n\(userMessage(instruction: instruction, text: text))"]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if (response as? HTTPURLResponse)?.statusCode != 200 {
            let msg = (json?["error"] as? [String: Any])?["message"] as? String
                ?? "Anthropic API error (\((response as? HTTPURLResponse)?.statusCode ?? 0))"
            throw APIError.apiError(msg)
        }

        let content = json?["content"] as? [[String: Any]]
        return content?.first?["text"] as? String ?? ""
    }

    // MARK: - OpenAI

    private func callOpenAI(text: String, instruction: String, apiKey: String, model: String) async throws -> String {
        guard !apiKey.isEmpty else { throw APIError.noAPIKey(.openai) }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 8192,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userMessage(instruction: instruction, text: text)]
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if (response as? HTTPURLResponse)?.statusCode != 200 {
            let msg = (json?["error"] as? [String: Any])?["message"] as? String
                ?? "OpenAI API error (\((response as? HTTPURLResponse)?.statusCode ?? 0))"
            throw APIError.apiError(msg)
        }

        let choices = json?["choices"] as? [[String: Any]]
        return (choices?.first?["message"] as? [String: Any])?["content"] as? String ?? ""
    }

    // MARK: - Gemini

    private func callGemini(text: String, instruction: String, apiKey: String, model: String) async throws -> String {
        guard !apiKey.isEmpty else { throw APIError.noAPIKey(.gemini) }

        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        var req = URLRequest(url: URL(string: urlStr)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["parts": [["text": userMessage(instruction: instruction, text: text)]]]],
            "generationConfig": ["maxOutputTokens": 8192]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if (response as? HTTPURLResponse)?.statusCode != 200 {
            let msg = (json?["error"] as? [String: Any])?["message"] as? String
                ?? "Gemini API error (\((response as? HTTPURLResponse)?.statusCode ?? 0))"
            throw APIError.apiError(msg)
        }

        let candidates = json?["candidates"] as? [[String: Any]]
        let parts = (candidates?.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]]
        return parts?.first?["text"] as? String ?? ""
    }
}
