---
name: github-macos-style
description: Apply the GitHub Dark style system to SwiftUI macOS apps. Use this skill when building or modifying UI in a macOS SwiftUI app to ensure consistent use of the GitHub-inspired dark color palette, native toolbar patterns, typography, components, spacing, and animations.
---

Apply the GitHub Dark style system to every piece of SwiftUI UI you write or modify. This is a production-tested style from a shipping macOS app. Follow every rule precisely.

The user provides a UI task: a new view, component, screen, or modification. Implement it using the patterns below without deviation unless explicitly told otherwise.

## Color Palette

Always declare as a `Color` extension and reference by token name — never use raw hex or RGB values inline.

```swift
extension Color {
    static let ghBase    = Color(red: 0.051, green: 0.067, blue: 0.090)  // #0D1117
    static let ghSurface = Color(red: 0.086, green: 0.106, blue: 0.133)  // #161B22
    static let ghBorder  = Color(red: 0.188, green: 0.212, blue: 0.239)  // #30363D
    static let ghText    = Color(red: 0.902, green: 0.929, blue: 0.953)  // #E6EDF3
    static let ghMuted   = Color(red: 0.545, green: 0.580, blue: 0.620)  // #8B949E
}
```

**Token rules — never mix these up:**
- `ghBase` → content/editor area background only
- `ghSurface` → all chrome: toolbars, sidebars, sheets, instruction bars, status bars, settings panels
- `ghBorder` → every line and stroke: dividers, input borders, hover backgrounds, circle backgrounds on icon buttons
- `ghText` → primary body text; use `.opacity(0.75)` at rest in lists, `1.0` on hover
- `ghMuted` → section headers, stats, timestamps, secondary labels — anything that should recede

## Window & Toolbar

```swift
// Scene configuration
.windowStyle(.titleBar)
.windowToolbarStyle(.unified(showsTitle: false))  // unified = toolbar merges with title bar (Finder/Xcode look)
.defaultSize(width: 900, height: 620)

// Root view
.background(Color.ghBase)
.preferredColorScheme(.dark)
```

**Toolbar layout rules:**
```swift
.toolbar {
    // App name — center, no interactive box
    ToolbarItem(placement: .principal) {
        Text("AppName")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .allowsHitTesting(false)  // REQUIRED: removes system capsule background
    }

    // Actions — right side, no explicit buttonStyle
    ToolbarItemGroup(placement: .primaryAction) {
        Button { } label: { Label("Action", systemImage: "icon") }
            .tooltip("Descriptive tooltip text")  // use .tooltip() not .help()

        // Vertical separator — NEVER use Divider() in toolbar, it renders horizontal
        Rectangle().fill(Color.ghBorder).frame(width: 1, height: 16)

        Button { } label: { Label("Action", systemImage: "icon") }
            .tooltip("Tooltip")
    }
}
```

**Critical:** Toolbar buttons must NOT have `.buttonStyle(.plain)` — let macOS apply native hover/press appearance.

## Tooltips

Use the AppKit-backed tooltip helper — SwiftUI's `.help()` is unreliable on macOS 26 toolbar buttons:

```swift
private struct TooltipNSView: NSViewRepresentable {
    let text: String
    func makeNSView(context: Context) -> NSView { let v = NSView(); v.toolTip = text; return v }
    func updateNSView(_ nsView: NSView, context: Context) { nsView.toolTip = text }
}

extension View {
    func tooltip(_ text: String) -> some View { self.background(TooltipNSView(text: text)) }
}
```

## Typography

| Role | Size | Weight | Design | Color |
|---|---|---|---|---|
| App title (toolbar) | 15pt | `.semibold` | `.rounded` | `.primary` |
| Sheet / modal title | 17pt | `.semibold` | `.rounded` | `.primary` |
| Sheet subtitle | 11pt | default | default | `.secondary` |
| Section header | 11pt | `.semibold` | default | `.secondary` + `.textCase(.uppercase)` |
| Section header (compact) | 10pt | `.semibold` | default | `.secondary` + `.textCase(.uppercase)` + `.tracking(0.5)` |
| Body / list item | 13pt | default | default | `.primary` |
| Field label | 11pt | `.medium` | default | `.secondary` |
| Stats / counts | 11–12pt | `.semibold` | `.monospaced` | `Color.ghMuted` |
| Editor content | 13pt | default | `.monospaced` | `.primary` |
| Error text | 12pt | default | default | `.red` |

```swift
// Section header with icon
Label("Section", systemImage: "icon").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).textCase(.uppercase)

// Compact section header
Text("Section").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).textCase(.uppercase).tracking(0.5)
```

## Buttons

| Type | Code |
|---|---|
| Primary (Save, Apply, Done) | `.buttonStyle(.borderedProminent)` |
| Icon / secondary | `.buttonStyle(.plain)` + explicit foreground |
| Destructive (Clear, Delete) | `.foregroundStyle(Color.red.opacity(0.8))` |
| Disabled | `.foregroundStyle(.tertiary)` |
| Toolbar | no explicit style |
| Cancel | plain, `.keyboardShortcut(.escape, modifiers: [])` |

## Input Fields

```swift
HStack(spacing: 6) {
    Image(systemName: "magnifyingglass").foregroundStyle(.tint)
    TextField("Placeholder…", text: $value).textFieldStyle(.plain)
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background(Color.ghBorder.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

// Field label
Text("Label").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)

// Error state
.overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red, lineWidth: 1.5))
```

## Dividers & Separators

```swift
Divider().overlay(Color.ghBorder)                              // horizontal — between sections
Rectangle().fill(Color.ghBorder).frame(width: 1, height: 16)  // vertical — toolbar / HStack
Color.ghBorder.frame(width: 1)                                 // full-height sidebar divider
```

## Sheets & Modals

```swift
// With scrollable content
VStack(spacing: 0) {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text("Title").font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Subtitle").font(.system(size: 11)).foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { dismiss() }.buttonStyle(.borderedProminent).keyboardShortcut(.escape, modifiers: [])
    }
    .padding(24)
    Divider()
    ScrollView(.vertical, showsIndicators: false) {
        VStack(alignment: .leading, spacing: 20) { /* sections */ }.padding(24)
    }
}
.frame(width: 440, height: 480)
.background(Color.ghSurface)
.preferredColorScheme(.dark)

// Fixed-height settings sheet
VStack(alignment: .leading, spacing: 20) { /* content */ }
    .padding(24).frame(width: 480, height: 520).background(Color.ghSurface).preferredColorScheme(.dark)
```

## Hover States

```swift
@State private var isHovering = false
// ...
.background(isHovering ? Color.ghBorder.opacity(0.35) : Color.clear)
.foregroundStyle(isHovering ? Color.ghText : Color.ghText.opacity(0.75))
.onHover { isHovering = $0 }
.animation(.easeInOut(duration: 0.08), value: isHovering)

// Reveal-on-hover element (e.g. delete button)
.opacity(isHovering ? 1 : 0).allowsHitTesting(isHovering)
```

## Loading Overlay

```swift
ZStack {
    contentView
    if isLoading {
        Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Loading…").font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 4)
    }
}
```

## Error Bar

```swift
HStack(spacing: 8) {
    Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor).font(.system(size: 12))
    Text(errorMessage).font(.system(size: 12)).foregroundStyle(.primary)
    Spacer()
    Button { errorMessage = "" } label: {
        Image(systemName: "xmark.circle.fill").symbolRenderingMode(.hierarchical).foregroundStyle(.secondary)
    }.buttonStyle(.plain)
}
.padding(.horizontal, 16).padding(.vertical, 8).background(Color.yellow.opacity(0.08))
```

## Badges

```swift
.overlay(alignment: .topTrailing) {
    if count > 0 {
        Text("\(count)")
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 4).padding(.vertical, 1)
            .background(.tint, in: Capsule())
            .offset(x: 6, y: -4)
    }
}
```

## Status Bar

```swift
Text(statsLabel)
    .font(.system(size: 12, weight: .semibold, design: .monospaced))
    .foregroundStyle(Color.ghMuted).monospacedDigit()
    .frame(maxWidth: .infinity, alignment: .center)
    .padding(.vertical, 5).background(Color.ghSurface)
```

## Animations

```swift
.animation(.easeInOut(duration: 0.08), value: isHovering)   // hover
.animation(.easeInOut(duration: 0.15), value: stateToggle)   // button state (e.g. copy → checkmark)
.animation(.easeInOut(duration: 0.20), value: panelVisible)  // panel open/close
```

## Spacing

| Context | Value |
|---|---|
| Sheet outer padding | 24pt |
| Bar horizontal padding | 14–16pt |
| Bar vertical padding | 10–12pt |
| Section spacing in sheets | 20pt |
| List item padding | 12pt h · 9pt v |
| Icon → text gap | 6–10pt |
| Status bar vertical | 4–5pt |

## Menu Bar

```swift
.commands {
    CommandGroup(replacing: .undoRedo) {}
    CommandGroup(replacing: .appSettings) {
        Button("Settings…") { openSettings?() }.keyboardShortcut(",", modifiers: .command)
    }
    CommandGroup(replacing: .help) {
        Button("App Help") { openHelp?() }.keyboardShortcut("?", modifiers: .command)
    }
}
```
