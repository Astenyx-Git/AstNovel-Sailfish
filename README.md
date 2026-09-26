# AstNovel for Sailfish OS

A novel-writing application for Sailfish OS, ported from the original HarmonyOS ArkUI-X app AstNovel (AstNovel-astn).

## Features

- **Book management** - shelf grid with covers (image or generated gradient), metadata editing, `.astn` import with same-title conflict dialog (create copy / overwrite / skip)
- **Chapters** - editor with a Markdown toolbar (bold / italic / H1-H3 / ordered / bullet lists), CJK-aware word count, auto-save every 30 s with crash recovery
- **Quick reference** - bottom sheet inside the editor listing outline, characters (all ten fields) and world entries; live GaussianBlur backdrop when the device GPU allows it, static snapshot fallback otherwise
- **Characters** - structured ten-field form (name, age, gender, height, weight, race, appearance, personality, background, notes), round avatar, image gallery
- **World settings** - five categories (geography / history / magic system / social structure / other), each with the original app's field template
- **Outline** - volume / chapter / section tree with links to chapters, characters and world entries
- **Export** - TXT (Markdown stripped), Markdown, or `.astn` v2.0, to a user-chosen folder
- **Import / export interoperability** - `.astn` v2.0 (PBKDF2-HMAC-SHA256 + AES-256-GCM), compatible with the original app's writer/reader, including covers, character avatars and galleries, and outline nodes

## Project structure

```
AstNovel-Sailfish/
├── sfdk/harbour-astnovel/      # the Sailfish package (source of truth)
│   ├── src/                    # C++: AstnStore (storage, crypto, Q_INVOKABLE API)
│   ├── qml/pages/              # Silica pages (shelf, detail, editor, characters, ...)
│   ├── qml/components/         # Apple-style widgets, cards, blur backdrop
│   ├── qml/styles/             # design tokens singleton (AstnStyle)
│   ├── rpm/                    # RPM spec
│   └── harbour-astn.pro
├── app/, harbour/              # early scaffolding, kept for reference only
├── BUILD_INSTRUCTIONS.md, QUICKSTART.md, ...   # porting notes
└── README.md
```

## Architecture

- **C++ (`AstnStore`)** - JSON-file storage under `QStandardPaths::AppDataLocation`, PBKDF2-HMAC-SHA256 key derivation, AES-256-GCM chunk encryption for `.astn`, exposed to QML through `Q_INVOKABLE` methods (books, chapters, characters, world entries, outlines, export/import, autosave)
- **QML (Qt 5.6 / Silica)** - iOS-styled light theme on a fixed palette (`AstnStyle` singleton); no runtime gradients or shader effects except the probe-gated quick-reference blur; cover gradients are pre-baked PNG textures for smooth scrolling on software renderers
- **Target** - Sailfish OS 5.1.0.486 / SDK target `SailfishOS-5.1.0.11-i486`

## Building

Requires the Sailfish SDK (with the Sailfish OS 5.1.0.11 i486 build target installed).

```bash
cd sfdk/harbour-astnovel
sfdk -c target=SailfishOS-5.1.0.11-i486 build
```

The RPM is written to `RPMS/harbour-astnovel-4.50.Ast.3-1.i486.rpm`; deploy it to a device or emulator (`devel-su rpm -Uvh harbour-astnovel-4.50.Ast.3-1.i486.rpm`) and launch `harbour-astnovel`.

## Data interoperability

`.astn` v2.0 files written by the original HarmonyOS app import directly, and files exported here import back into it: same container layout, same key derivation, same per-asset JSON schema (including character avatars and galleries as separate image assets).

## Support

- Bug reports and questions: [GitHub Issues](https://github.com/Astenyx-Git/AstNovel-Sailfish/issues)

## Credits

- Original HarmonyOS app: AstNovel-astn by Astenyx
- Sailfish OS port: Astenyx

Copyright (c) 2026 Astenyx. All rights reserved.
