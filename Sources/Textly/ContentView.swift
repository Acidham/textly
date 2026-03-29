import SwiftUI
import AppKit

// MARK: - GitHub dark palette

extension Color {
    static let ghBase    = Color(red: 0.051, green: 0.067, blue: 0.090)  // #0D1117
    static let ghSurface = Color(red: 0.086, green: 0.106, blue: 0.133)  // #161B22
    static let ghBorder  = Color(red: 0.188, green: 0.212, blue: 0.239)  // #30363D
    static let ghText    = Color(red: 0.902, green: 0.929, blue: 0.953)  // #E6EDF3
    static let ghMuted   = Color(red: 0.545, green: 0.580, blue: 0.620)  // #8B949E
}

// MARK: - Content view

struct ContentView: View {
    @EnvironmentObject var settings: SettingsManager

    @State private var editorText: String = ""
    @State private var instruction: String = ""
    @State private var undoStack: [String] = []
    @State private var isTransforming: Bool = false
    @State private var errorMessage: String = ""
    @State private var showCopied: Bool = false
    @State private var showSettings: Bool = false
    @State private var showHelp: Bool = false
    @State private var showSidebar: Bool = false
    @State private var sidebarWidth: CGFloat = 240

    private let maxUndo = 50

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Main column
                VStack(spacing: 0) {
                    editorArea
                    if !errorMessage.isEmpty {
                        Divider().overlay(Color.ghBorder)
                        errorBar
                    }
                    Divider().overlay(Color.ghBorder)
                    instructionBar
                    Divider().overlay(Color.ghBorder)
                    statusBar
                }

                // Resizable sidebar
                if showSidebar {
                    sidebarDivider
                    recentSidebar
                        .frame(width: sidebarWidth)
                }
            }
        }
        .background(Color.ghBase)
        .preferredColorScheme(.dark)
        .font(.system(size: settings.uiFontSize))
        .frame(minWidth: 640, minHeight: 440)
        .focusedValue(\.openSettings) { showSettings = true }
        .focusedValue(\.openHelp) { showHelp = true }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(settings)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .onAppear {
            if !settings.hasAnyApiKey {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showSettings = true
                }
            }
        }
        .toolbar {
            // Center: app title
            ToolbarItem(placement: .principal) {
                Text("Textly")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .allowsHitTesting(false)
            }

            // Right: Undo, Copy, Clear, Recent toggle
            ToolbarItemGroup(placement: .primaryAction) {
                Button { undoTransformation() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(undoStack.isEmpty)
                .overlay(alignment: .topTrailing) {
                    if !undoStack.isEmpty {
                        Text("\(undoStack.count)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.tint, in: Capsule())
                            .offset(x: 6, y: -4)
                    }
                }
                .help("Undo last transformation (\(undoStack.count) available)")

                Button { copyToClipboard() } label: {
                    Label(showCopied ? "Copied" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                }
                .disabled(editorText.isEmpty)
                .help("Copy to clipboard")
                .animation(.easeInOut(duration: 0.15), value: showCopied)

                Button { clearAll() } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(editorText.isEmpty)
                .help("Clear all")

                Rectangle()
                    .fill(Color.ghBorder)
                    .frame(width: 1, height: 16)

                Button { withAnimation(.easeInOut(duration: 0.2)) { showSidebar.toggle() } } label: {
                    Label("Recent", systemImage: "clock")
                }
                .help(showSidebar ? "Hide recent" : "Show recent")

                Button { showHelp = true } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .help("Textly Help")
                .padding(.leading, 8)
            }
        }
    }

    private var statsLabel: String {
        let chars = editorText.count
        let lines = editorText.isEmpty ? 0 : editorText.components(separatedBy: "\n").count
        let chStr = chars >= 1_000 ? String(format: "%.1fk ch", Double(chars) / 1000) : "\(chars) ch"
        let lnStr = "\(lines) ln"
        return chars == 0 ? "0 ch · 0 ln" : "\(chStr) · \(lnStr)"
    }

    private var statusBar: some View {
        Text(statsLabel)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.ghMuted)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 5)
            .background(Color.ghSurface)
    }

    // MARK: - Editor

    private var editorArea: some View {
        ZStack {
            TextEditor(text: $editorText)
                .font(.system(size: settings.editorFontSize, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color.ghBase)
                .padding(8)

            if isTransforming {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    ProgressView().controlSize(.large)
                    Text("Transforming…")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 20, y: 4)
            }
        }
    }

    // MARK: - Error bar

    private var errorBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 12))
            Text(errorMessage)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                errorMessage = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.08))
    }

    // MARK: - Instruction bar

    private var instructionBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.sparkles")
                    .foregroundStyle(.tint)

                TextField("Describe a transformation…", text: $instruction)
                    .textFieldStyle(.plain)
                    .onSubmit { applyTransformation() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.ghBorder.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button("Apply") { applyTransformation() }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(instruction.trimmingCharacters(in: .whitespaces).isEmpty || isTransforming)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.ghSurface)
    }

    // MARK: - Sidebar divider (draggable)

    private var sidebarDivider: some View {
        Color.ghBorder
            .frame(width: 1)
            .overlay(
                Color.clear
                    .frame(width: 8)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newWidth = sidebarWidth - value.translation.width
                                sidebarWidth = max(160, min(480, newWidth))
                            }
                    )
                    .onHover { hovering in
                        if hovering { NSCursor.resizeLeftRight.push() }
                        else { NSCursor.pop() }
                    }
            )
    }

    // MARK: - Recent sidebar

    private var recentSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recent")
                    .font(.system(size: settings.uiFontSize - 2, weight: .semibold))
                    .foregroundStyle(Color.ghMuted)
                    .textCase(.uppercase)

                Spacer()

                if !settings.promptHistory.isEmpty {
                    Button {
                        settings.promptHistory.removeAll()
                    } label: {
                        Text("Clear All")
                            .font(.system(size: settings.uiFontSize - 2))
                            .foregroundStyle(Color.ghMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Delete all recent items")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.ghSurface)

            Divider().overlay(Color.ghBorder)

            if settings.promptHistory.isEmpty {
                Spacer()
                Text("No recent transformations")
                    .foregroundStyle(Color.ghMuted)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(settings.promptHistory, id: \.self) { prompt in
                            RecentItem(prompt: prompt) { selected in
                                instruction = selected
                                applyTransformation()
                            } onDelete: {
                                settings.removeFromHistory(prompt)
                            }
                            Divider().overlay(Color.ghBorder)
                        }
                    }
                }
            }
        }
        .background(Color.ghSurface)
    }

    // MARK: - Actions

    private func undoTransformation() {
        guard let previous = undoStack.last else { return }
        undoStack.removeLast()
        editorText = previous
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(editorText, forType: .string)
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
    }

    private func clearAll() {
        undoStack = []
        editorText = ""
        errorMessage = ""
    }

    private func applyTransformation() {
        let trimmed = instruction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = ""

        if undoStack.count >= maxUndo { undoStack.removeFirst() }
        undoStack.append(editorText)

        isTransforming = true

        Task { @MainActor in
            do {
                let result = try await APIService.shared.transform(
                    text: editorText,
                    instruction: trimmed,
                    settings: settings
                )
                editorText = result
                settings.addToHistory(trimmed)
                instruction = ""
                isTransforming = false
            } catch {
                _ = undoStack.popLast()
                errorMessage = error.localizedDescription
                isTransforming = false
            }
        }
    }
}

// MARK: - Recent sidebar item

struct RecentItem: View {
    let prompt: String
    let onSelect: (String) -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(prompt)
                .foregroundStyle(isHovering ? Color.ghText : Color.ghText.opacity(0.75))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Always reserve space so layout doesn't shift
            Button { onDelete() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.ghMuted)
                    .frame(width: 18, height: 18)
                    .background(Color.ghBorder, in: Circle())
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(isHovering ? Color.ghBorder.opacity(0.35) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { onSelect(prompt) }
        .animation(.easeInOut(duration: 0.08), value: isHovering)
    }
}

// MARK: - Help view

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Textly Help")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("AI-powered text transformation")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(24)

            Divider()

            // Scrollable sections
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    apiKeysSection

                    helpSection("Getting Started", items: [
                        ("wand.and.sparkles", "Type or paste text into the editor"),
                        ("text.cursor",        "Describe your transformation in the instruction bar"),
                        ("return",             "Press Return or click Apply"),
                    ])
                    helpSection("Toolbar", items: [
                        ("arrow.uturn.backward", "Undo — revert to previous version (up to 50 steps)"),
                        ("doc.on.doc",           "Copy — copy editor content to clipboard"),
                        ("trash",                "Clear — clear text and undo history"),
                        ("clock",                "Recent — toggle sidebar with last 50 prompts"),
                    ])
                    helpSection("Keyboard Shortcuts", items: [
                        ("command",  "⌘ Return — Apply transformation"),
                        ("command",  "⌘ , — Open Settings"),
                        ("command",  "⌘ ? — Open Help"),
                    ])
                    helpSection("Example Prompts", items: [
                        ("lightbulb", "Fix grammar and spelling"),
                        ("lightbulb", "Make this more formal"),
                        ("lightbulb", "Summarize in one sentence"),
                        ("lightbulb", "Convert to bullet points"),
                        ("lightbulb", "Translate to French"),
                    ])
                }
                .padding(24)
            }
        }
        .frame(width: 440, height: 480)
        .background(Color.ghSurface)
        .preferredColorScheme(.dark)
    }

    private var apiKeysSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Keys")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text("Textly requires an API key for cloud providers, or use On-Device for free with Apple Intelligence. Add your key in Settings (⌘,).")
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                apiKeyRow(
                    icon: "ant.fill",
                    provider: "Anthropic (Claude)",
                    description: "console.anthropic.com",
                    url: "https://console.anthropic.com/settings/keys"
                )
                apiKeyRow(
                    icon: "sparkles",
                    provider: "OpenAI",
                    description: "platform.openai.com",
                    url: "https://platform.openai.com/api-keys"
                )
                apiKeyRow(
                    icon: "g.circle.fill",
                    provider: "Google Gemini",
                    description: "aistudio.google.com",
                    url: "https://aistudio.google.com/app/apikey"
                )
                apiKeyRow(
                    icon: "cpu.fill",
                    provider: "On-Device",
                    description: "No key needed — requires Apple Intelligence (macOS 26+)",
                    url: nil
                )
            }
        }
    }

    private func apiKeyRow(icon: String, provider: String, description: String, url: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 14, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                Text(provider)
                    .font(.system(size: 12, weight: .medium))
                if let url, let dest = URL(string: url) {
                    Link(description, destination: dest)
                        .font(.system(size: 11))
                        .foregroundStyle(.tint)
                } else {
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func helpSection(_ title: String, items: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(items, id: \.1) { icon, text in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 14, alignment: .center)
                        Text(text)
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}
