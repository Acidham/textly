import Foundation

enum APIProvider: String, CaseIterable, Identifiable {
    case gemini = "gemini"
    case anthropic = "anthropic"
    case openai = "openai"
    case local = "local"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini:    return "Google Gemini"
        case .anthropic: return "Anthropic (Claude)"
        case .openai:    return "OpenAI"
        case .local:     return "On-Device"
        }
    }
}

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - UserDefaults-backed settings

    @Published var selectedProvider: APIProvider {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedProvider") }
    }

    @Published var anthropicModel: String {
        didSet { UserDefaults.standard.set(anthropicModel, forKey: "anthropicModel") }
    }

    @Published var openaiModel: String {
        didSet { UserDefaults.standard.set(openaiModel, forKey: "openaiModel") }
    }

    @Published var geminiModel: String {
        didSet { UserDefaults.standard.set(geminiModel, forKey: "geminiModel") }
    }

    @Published var editorFontSize: Double {
        didSet { UserDefaults.standard.set(editorFontSize, forKey: "editorFontSize") }
    }

    @Published var uiFontSize: Double {
        didSet { UserDefaults.standard.set(uiFontSize, forKey: "uiFontSize") }
    }

    @Published var promptHistory: [String] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(promptHistory) {
                UserDefaults.standard.set(data, forKey: "promptHistory")
            }
        }
    }

    // MARK: - Keychain-backed API keys

    var anthropicApiKey: String {
        get { KeychainManager.shared.get(key: "anthropicApiKey") ?? "" }
        set { KeychainManager.shared.set(key: "anthropicApiKey", value: newValue) }
    }

    var openaiApiKey: String {
        get { KeychainManager.shared.get(key: "openaiApiKey") ?? "" }
        set { KeychainManager.shared.set(key: "openaiApiKey", value: newValue) }
    }

    var geminiApiKey: String {
        get { KeychainManager.shared.get(key: "geminiApiKey") ?? "" }
        set { KeychainManager.shared.set(key: "geminiApiKey", value: newValue) }
    }

    var hasAnyApiKey: Bool {
        if selectedProvider == .local { return true }
        return !anthropicApiKey.isEmpty || !openaiApiKey.isEmpty || !geminiApiKey.isEmpty
    }

    // MARK: - Model lists

    let anthropicModels: [(id: String, name: String)] = [
        ("claude-haiku-4-5-20251001", "Claude Haiku 4.5 (Recommended)"),
        ("claude-3-5-haiku-20241022", "Claude 3.5 Haiku"),
        ("claude-3-5-sonnet-20241022", "Claude 3.5 Sonnet"),
        ("claude-opus-4-6", "Claude Opus 4.6"),
    ]

    let openaiModels: [(id: String, name: String)] = [
        ("gpt-4o-mini", "GPT-4o Mini (Recommended)"),
        ("gpt-4o", "GPT-4o"),
        ("gpt-3.5-turbo", "GPT-3.5 Turbo"),
    ]

    let geminiModels: [(id: String, name: String)] = [
        ("gemini-2.5-flash", "Gemini 2.5 Flash (Recommended)"),
        ("gemini-2.5-flash-lite", "Gemini 2.5 Flash Lite"),
        ("gemini-2.0-flash", "Gemini 2.0 Flash"),
    ]

    // MARK: - Init

    private init() {
        let providerRaw = UserDefaults.standard.string(forKey: "selectedProvider") ?? APIProvider.gemini.rawValue
        selectedProvider = APIProvider(rawValue: providerRaw) ?? .gemini

        anthropicModel = UserDefaults.standard.string(forKey: "anthropicModel") ?? "claude-haiku-4-5-20251001"
        openaiModel    = UserDefaults.standard.string(forKey: "openaiModel")    ?? "gpt-4o-mini"
        geminiModel    = UserDefaults.standard.string(forKey: "geminiModel")    ?? "gemini-2.5-flash"
        editorFontSize = UserDefaults.standard.object(forKey: "editorFontSize") as? Double ?? 13
        uiFontSize     = UserDefaults.standard.object(forKey: "uiFontSize")     as? Double ?? 13

        if let data = UserDefaults.standard.data(forKey: "promptHistory"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            promptHistory = history
        }
    }

    // MARK: - History

    func addToHistory(_ prompt: String) {
        var history = promptHistory
        history.removeAll { $0 == prompt }
        history.insert(prompt, at: 0)
        promptHistory = Array(history.prefix(50))
    }

    func removeFromHistory(_ prompt: String) {
        promptHistory.removeAll { $0 == prompt }
    }
}
