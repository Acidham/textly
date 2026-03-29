import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss

    @State private var provider: APIProvider = .gemini
    @State private var anthropicKey: String = ""
    @State private var anthropicModel: String = "claude-haiku-4-5-20251001"
    @State private var openaiKey: String = ""
    @State private var openaiModel: String = "gpt-4o-mini"
    @State private var geminiKey: String = ""
    @State private var geminiModel: String = "gemini-2.5-flash"
    @State private var editorFontSize: Double = 13
    @State private var uiFontSize: Double = 13
    @State private var showKeyError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Configure your AI provider and preferences")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Provider picker
            VStack(alignment: .leading, spacing: 8) {
                Label("Provider", systemImage: "cpu.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Picker("", selection: $provider) {
                    ForEach(APIProvider.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            // Per-provider fields
            switch provider {
            case .anthropic:
                ProviderFields(
                    keyLabel: "Anthropic API Key",
                    keyPlaceholder: "sk-ant-...",
                    apiKey: $anthropicKey,
                    model: $anthropicModel,
                    models: settings.anthropicModels,
                    keyError: showKeyError
                )
            case .openai:
                ProviderFields(
                    keyLabel: "OpenAI API Key",
                    keyPlaceholder: "sk-...",
                    apiKey: $openaiKey,
                    model: $openaiModel,
                    models: settings.openaiModels,
                    keyError: showKeyError
                )
            case .gemini:
                ProviderFields(
                    keyLabel: "Gemini API Key",
                    keyPlaceholder: "AIza...",
                    apiKey: $geminiKey,
                    model: $geminiModel,
                    models: settings.geminiModels,
                    keyError: showKeyError
                )
            case .local:
                LocalProviderPanel()
            }

            if showKeyError {
                Label("An API key is required for the selected provider.", systemImage: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }

            Divider()

            // Appearance
            VStack(alignment: .leading, spacing: 12) {
                Label("Appearance", systemImage: "textformat.size")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                FontSizeStepper(label: "Editor font", value: $editorFontSize, range: 10...24)
                FontSizeStepper(label: "UI font",     value: $uiFontSize,     range: 10...18)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(24)
        .frame(width: 480, height: 520)
        .background(Color.ghSurface)
        .preferredColorScheme(.dark)
        .onAppear { loadFromSettings() }
        .onChange(of: provider) { _ in showKeyError = false }
    }

    private func loadFromSettings() {
        provider       = settings.selectedProvider
        anthropicKey   = settings.anthropicApiKey
        anthropicModel = settings.anthropicModel
        openaiKey      = settings.openaiApiKey
        openaiModel    = settings.openaiModel
        geminiKey      = settings.geminiApiKey
        geminiModel    = settings.geminiModel
        editorFontSize = settings.editorFontSize
        uiFontSize     = settings.uiFontSize
    }

    private func save() {
        if provider != .local {
            let currentKey: String = {
                switch provider {
                case .anthropic: return anthropicKey.trimmingCharacters(in: .whitespaces)
                case .openai:    return openaiKey.trimmingCharacters(in: .whitespaces)
                case .gemini:    return geminiKey.trimmingCharacters(in: .whitespaces)
                case .local:     return ""
                }
            }()

            guard !currentKey.isEmpty else {
                showKeyError = true
                return
            }
        }

        settings.selectedProvider = provider
        settings.anthropicApiKey  = anthropicKey.trimmingCharacters(in: .whitespaces)
        settings.anthropicModel   = anthropicModel
        settings.openaiApiKey     = openaiKey.trimmingCharacters(in: .whitespaces)
        settings.openaiModel      = openaiModel
        settings.geminiApiKey     = geminiKey.trimmingCharacters(in: .whitespaces)
        settings.geminiModel      = geminiModel
        settings.editorFontSize   = editorFontSize
        settings.uiFontSize       = uiFontSize

        dismiss()
    }
}

// MARK: - Provider fields

private struct ProviderFields: View {
    let keyLabel: String
    let keyPlaceholder: String
    @Binding var apiKey: String
    @Binding var model: String
    let models: [(id: String, name: String)]
    let keyError: Bool

    @State private var showKey: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(keyLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    ZStack {
                        TextField(keyPlaceholder, text: $apiKey)
                            .opacity(showKey ? 1 : 0)
                        SecureField(keyPlaceholder, text: $apiKey)
                            .opacity(showKey ? 0 : 1)
                    }
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(keyError && apiKey.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.red : Color.clear, lineWidth: 1.5)
                    )

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)
                    .help(showKey ? "Hide key" : "Show key")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Model")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker("", selection: $model) {
                    ForEach(models, id: \.id) { m in
                        Text(m.name).tag(m.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Local provider panel

private struct LocalProviderPanel: View {
    @State private var availability: String = "Checking…"
    @State private var isAvailable: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple On-Device Model")
                        .font(.system(size: 13, weight: .medium))
                    Text("No API key required · Fully private · No network calls")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(isAvailable ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(availability)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { checkAvailability() }
    }

    private func checkAvailability() {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                isAvailable = true
                availability = "Available on this Mac"
            case .unavailable(let reason):
                isAvailable = false
                switch reason {
                case .deviceNotEligible:
                    availability = "Not available — device not eligible for Apple Intelligence"
                case .appleIntelligenceNotEnabled:
                    availability = "Apple Intelligence not enabled — enable in System Settings"
                default:
                    availability = "Not available on this Mac"
                }
            @unknown default:
                isAvailable = false
                availability = "Status unknown"
            }
        } else {
            isAvailable = false
            availability = "Requires macOS 26 or later"
        }
        #else
        isAvailable = false
        availability = "Requires macOS 26 or later"
        #endif
    }
}

// MARK: - Font size stepper

private struct FontSizeStepper: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
            Spacer()
            Stepper(value: $value, in: range, step: 1) {
                Text("\(Int(value)) pt")
                    .monospacedDigit()
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
        .font(.system(size: 13))
    }
}
