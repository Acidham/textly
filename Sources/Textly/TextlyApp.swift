import SwiftUI
import AppKit

// MARK: - Focused value for settings action

struct OpenSettingsKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct OpenHelpKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var openSettings: (() -> Void)? {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
    var openHelp: (() -> Void)? {
        get { self[OpenHelpKey.self] }
        set { self[OpenHelpKey.self] = newValue }
    }
}

@main
struct TextlyApp: App {
    @StateObject private var settings = SettingsManager.shared
    @FocusedValue(\.openSettings) private var openSettings
    @FocusedValue(\.openHelp) private var openHelp

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 900, height: 620)
        .commands {
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    openSettings?()
                }
                .keyboardShortcut(",", modifiers: .command)
                .disabled(openSettings == nil)
            }
            CommandGroup(replacing: .help) {
                Button("Textly Help") {
                    openHelp?()
                }
                .keyboardShortcut("?", modifiers: .command)
                .disabled(openHelp == nil)
            }
        }
    }
}
