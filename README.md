# Textly

A lightweight macOS app for AI-powered text transformation. Paste text, describe what you want done, and get the result instantly — no bloat, no subscriptions.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![Version](https://img.shields.io/badge/version-1.5-green)

## Features

- **Multiple AI providers** — Anthropic Claude, OpenAI, Google Gemini
- **On-Device model** — Uses Apple Intelligence via FoundationModels (macOS 26+, no API key required)
- **Undo history** — Up to 50 steps
- **Recent prompts** — Sidebar with your last 50 transformations, reusable with one click
- **Zero bloat** — No external dependencies, native SwiftUI

## Example prompts

- Fix grammar and spelling
- Make this more formal
- Summarize in one sentence
- Convert to bullet points
- Translate to French
- Remove all filler words

## Requirements

- macOS 13.0 or later (macOS 26+ for On-Device model)
- Apple Silicon or Intel Mac
- API key for cloud providers (Anthropic, OpenAI, or Gemini)

## Getting an API key

| Provider | Link |
|---|---|
| Anthropic (Claude) | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) |
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| Google Gemini | [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) |

## Installation

### Download
Grab the latest `.dmg` from [Releases](../../releases) and drag Textly to your Applications folder.

### Build from source

Requires macOS with Command Line Tools installed.

```bash
git clone https://github.com/Acidham/textly.git
cd textly
bash build.sh
open .build/manual/Textly.app
```

## Usage

1. Open Textly
2. Open Settings (⌘,) and add your API key
3. Paste or type text into the editor
4. Describe your transformation in the bar at the bottom
5. Press Return or click **Apply**

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘ Return | Apply transformation |
| ⌘ , | Open Settings |
| ⌘ ? | Open Help |
| ⌘ Z | Undo (via toolbar) |

## License

MIT
