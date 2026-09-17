# DevSpork

> **Beta status** — DevSpork is in active beta development (`v0.0.13`). Features, tools and UI may change without notice. Use in production at your own discretion.

All-in-one cross-platform developer toolbox — 80+ offline utilities for text, JSON, SQL, security, media, web and more. Built with Flutter for Android, iOS, Web, Windows, macOS and Linux.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tool List](#tool-list)
- [Supported Platforms](#supported-platforms)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Design Principles](#design-principles)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Bug Reports and Feature Requests](#bug-reports-and-feature-requests)
- [License](#license)
- [Links](#links)
- [Support the Project](#support-the-project)

---

## Overview

DevSpork bundles 80+ micro-tools into a single, fast, offline-first application. No sign-up, no ads, no tracking. Every tool runs locally on your device.

### Screenshots

Screenshots are not available yet. Run the app locally to see the current UI.

---

## Features

### Most popular tools

| Tool | Description |
|---|---|
| PDF Merge / Split / Compress | Combine, split and shrink PDF files locally |
| Image Compressor | Reduce image size without visible quality loss |
| Image Converter | Convert between PNG, JPG, WebP and more |
| QR Code Generator | Create custom QR codes for URLs, text, Wi-Fi and more |
| Color Palette Generator | Build and export color palettes |
| JSON Formatter | Format, validate and minify JSON |
| Markdown Preview & Converter | Live preview and Markdown to HTML conversion |
| SQL Formatter | Beautify and format SQL queries |
| Regex Tester | Test and debug regular expressions in real time |
| Password Generator | Generate strong, secure passwords |

---

## Tool List

### Text

Case Converter · Text Statistics · Text Utilities · Text Masker · Lorem Ipsum Generator · Slug Generator · Diff Checker · Markdown Preview · Markdown to HTML · Markdown Table Builder · Excel to Markdown Table · Code Formatter

### Data

JSON Formatter · JSON Suite · JSON Schema Generator · JSON Schema Validator · JSON to Code Generator · SQL Formatter · SQL Builder · Mock Data Generator · Locale Compare · Binary Viewer · Cron Parser · Cron Builder · Regex Tester · Regex Builder · Table Viewer

### Security

Hash Generator · Bcrypt Generator · Crypto Toolkit · JWT Decoder · JWT Generator · RSA Key Generator · UUID Generator · Password Generator · Password Strength Checker · Wordlist Generator · TOTP Generator · Base64 URL Encoder/Decoder · HTML Entity Encoder/Decoder

### Web

URL Parser · API Builder · Social Links Generator · SEO Tools · SEO Pack · User-Agent Parser · MIME Types List · CSS Tools · CSS Layout Generator · Network Tools

### Converters

Code File Converter · YAML and JSON · List Converter · Base Converter · Color Converter · Timestamp Converter · Dev Calculator · Env Manager

### Media

Base64 and Image · QR Code Generator · ASCII Art · Color Palette · SVG Path Viewer · Image Compressor · Image Converter · Image Cropper · Image to PDF · PDF Merge · PDF Split · PDF Compress · Audio Converter

### DevOps

Git Command Generator · DevOps Config Generator · Kubernetes Manifest Generator · Mock Server

### Other

Timezone Planner

---

## Supported Platforms

| Platform | Status |
|---|---|
| Android | Supported |
| iOS | Supported |
| Web | Supported |
| Windows | Supported |
| macOS | Supported |
| Linux | Supported |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` — see the [install guide](https://docs.flutter.dev/get-started/install)
- Dart SDK `>=3.0.0` (bundled with Flutter)
- Platform-specific toolchains (Android Studio, Xcode, Visual Studio, etc.)

### Installation

```bash
git clone https://github.com/mr-ruhid/devspork.git
cd devspork
flutter pub get
flutter run
```

### Building

```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS
flutter build web --release        # Web
flutter build windows --release    # Windows
flutter build macos --release      # macOS
flutter build linux --release      # Linux
```

---

## Project Structure

```text
devspork/
├── android/              # Android native shell
├── ios/                  # iOS native shell
├── web/                  # Web shell
├── windows/              # Windows native shell
├── macos/                # macOS native shell
├── linux/                # Linux native shell
├── assets/
│   └── lang/             # Localization files
├── lib/
│   ├── core/             # Core utilities
│   │   ├── localization/ # App localization
│   │   ├── platform/     # Platform detection & window controls
│   │   └── theme/        # App UI kit & theming
│   ├── scene/            # Screens (Home, etc.)
│   ├── tools/            # 80+ micro-tools
│   │   ├── apibuilder/
│   │   ├── b64img.dart
│   │   ├── ...
│   │   └── yamljson.dart
│   └── main.dart         # App entry point
└── pubspec.yaml          # Dependencies
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| Desktop window | window_manager |
| State management | StatefulWidget + ValueNotifier |
| Localization | Custom AppLocalization |
| UI kit | Custom glassmorphism theme (GlassCard, GlassAppBar, GlassBackground) |
| Icons | Material Icons |

---

## Design Principles

- **Offline-first** — all tools work without an internet connection
- **Privacy-focused** — no tracking, no telemetry, no ads
- **Cross-platform** — one codebase, six platforms
- **Universal UI** — responsive layout adapts to any screen size
- **Fast and lightweight** — optimized rendering, minimal rebuilds

---

## Roadmap

- [ ] Expand the tool set (target: 100+)
- [ ] Dark / Light / System theme switcher in Settings
- [ ] Multi-language support (currently AZ and EN)
- [ ] Favorites and recent tools
- [ ] Keyboard shortcuts (Ctrl+K, Esc, etc.)
- [ ] Optional cloud sync
- [ ] Plugin system for community tools
- [ ] Improved accessibility
- [ ] Unit and widget test coverage

---

## Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch — `git checkout -b feature/amazing-tool`
3. Commit your changes — `git commit -m "Add amazing tool"`
4. Push the branch — `git push origin feature/amazing-tool`
5. Open a pull request

### Guidelines

- Follow the existing code style
- Write meaningful commit messages
- Test on at least one platform before submitting
- Avoid external dependencies unless absolutely necessary
- No demo or placeholder code — every tool must be fully functional

---

## Bug Reports and Feature Requests

Open an issue on GitHub, or get in touch through [ruhidjavadov.site](https://www.ruhidjavadov.site).

You can also help by starring the repository, sharing it, or suggesting new tools.

---

## License

Released under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Links

- Repository — [github.com/mr-ruhid/devspork](https://github.com/mr-ruhid/devspork)
- Website — [ruhidjavadov.site](https://www.ruhidjavadov.site)
- Author — [@mr-ruhid](https://github.com/mr-ruhid)

---

## Support the Project

If this project has been useful to you, consider supporting its continued development and maintenance.

<div align="center">

<a href="https://kofe.al/@ruhidjavadoff">
  <img src="https://kofe.al/assets/images/kofeal-logo.svg" height="36" alt="Support on Kofe.al" style="background-color:#ffffff; padding:6px; border-radius:6px;">
</a>
&nbsp;&nbsp;
<a href="https://www.paypal.com/paypalme/ruhidjavadoff">
  <img src="https://img.shields.io/badge/Donate-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Donate via PayPal" height="36">
</a>

</div>

<br>

| Method | Details |
|---|---|
| Kofe.al | [@ruhidjavadoff](https://kofe.al/@ruhidjavadoff) |
| Çayvoy | [ruhid4715](https://cayvoy.com/donate/ruhid4715) |
| PayPal | `ruhidjavadoff@gmail.com` |
| Crypto (USDT — BNB Smart Chain) | `0x9a4AD41762D6B07B8C266b312Cf0dBe31FAd890c` |