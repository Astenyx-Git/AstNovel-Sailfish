# AstNovel for Sailfish OS

**English** | [繁體中文](#astnovel-sailfish-os-版)

A novel-writing application for Sailfish OS, ported from the original HarmonyOS ArkUI-X app AstNovel (AstNovel-astn). Package version `4.50.Ast.3`, aligned with the original app.

## Features

- **Book management** - shelf grid with covers (image or generated gradient), metadata editing, `.astn` import with same-title conflict dialog (create copy / overwrite / skip)
- **Chapters** - editor with a Markdown toolbar (bold / italic / H1-H3 / ordered / bullet lists), CJK-aware word count, auto-save every 30 s with crash recovery
- **Quick reference** - bottom sheet inside the editor listing outline, characters (all ten fields) and world entries; live GaussianBlur backdrop when the device GPU allows it, static snapshot fallback otherwise
- **Characters** - structured ten-field form (name, age, gender, height, weight, race, appearance, personality, background, notes), round avatar, image gallery
- **World settings** - five categories (geography / history / magic system / social structure / other), each with the original app's field template
- **Outline** - volume / chapter / section tree with links to chapters, characters and world entries
- **Home-screen cover** - shows a live thumbnail of the current page; falls back to a solid-colour card with the app icon when no frame is available
- **Export** - TXT (Markdown stripped), Markdown, or `.astn` v2.0, to a user-chosen folder
- **Fully offline** - no network permission, no network calls; all data stays on the device

`.astn` v2.0 (PBKDF2-HMAC-SHA256 + AES-256-GCM) files written by the original HarmonyOS app import directly, and files exported here import back into it — same container, same key derivation, same per-asset JSON schema, including covers, character avatars, galleries and outline nodes.

## Install

Packages are provided for three architectures:

| File | Device |
|---|---|
| `harbour-astnovel-4.50.Ast.3-1.armv7hl.rpm` | Jolla 1, Jolla C, Xperia X, Xperia XA2 |
| `harbour-astnovel-4.50.Ast.3-1.aarch64.rpm` | Xperia 10 series, Jolla C2 |
| `harbour-astnovel-4.50.Ast.3-1.i486.rpm` | SDK emulator |

On a device with developer mode enabled:

```bash
devel-su rpm -Uvh harbour-astnovel-4.50.Ast.3-1.<arch>.rpm
```

or, from the SDK: `sfdk -c device=<name> deploy`. User data lives in `~/.local/share/harbour-astnovel/` and survives uninstalling.

## Project structure

```
AstNovel-Sailfish/
├── sfdk/harbour-astnovel/      # the Sailfish package (source of truth)
│   ├── src/                    # C++: AstnStore (storage, crypto, Q_INVOKABLE API)
│   ├── qml/pages/              # Silica pages (shelf, detail, editor, characters, ...)
│   ├── qml/components/         # Apple-style widgets, cards, blur backdrop
│   ├── qml/styles/             # design tokens singleton (AstnStyle)
│   ├── rpm/                    # RPM spec
│   └── harbour-astnovel.pro
└── README.md
```

## Architecture

- **C++ (`AstnStore`)** - JSON-file storage under `QStandardPaths::AppDataLocation`, PBKDF2-HMAC-SHA256 key derivation, AES-256-GCM chunk encryption for `.astn`, exposed to QML through `Q_INVOKABLE` methods (books, chapters, characters, world entries, outlines, export/import, autosave, cover frame capture)
- **QML (Qt 5.6 / Silica)** - iOS-styled light theme on a fixed palette (`AstnStyle` singleton); no runtime gradients or shader effects except the probe-gated quick-reference blur; cover gradients are pre-baked PNG textures for smooth scrolling on software renderers
- **Cover thumbnail** - the page is captured with `grabToImage`, saved to a PNG in the cache directory by C++ and loaded by the cover window (which cannot use in-window grab URLs); the oldest frame persists while backgrounded

## Building

Requires the Sailfish SDK with the 5.1.0.11 targets installed.

```bash
cd sfdk/harbour-astnovel
sfdk -c target=SailfishOS-5.1.0.11-i486 build      # emulator
sfdk -c target=SailfishOS-5.1.0.11-armv7hl build   # 32-bit devices
sfdk -c target=SailfishOS-5.1.0.11-aarch64 build   # 64-bit devices
```

When switching targets, remove local build artefacts first (`Makefile*`, `*.o`, `moc_*.cpp`, the `harbour-astnovel` binary) — otherwise qmake may reuse objects compiled for the previous architecture.

## Support

- Bug reports and questions: [GitHub Issues](https://github.com/Astenyx-Git/AstNovel-Sailfish/issues)

## Credits

- Original HarmonyOS app: AstNovel-astn by Astenyx
- Sailfish OS port: Astenyx

Copyright (c) 2026 Astenyx. All rights reserved.

---

# AstNovel Sailfish OS 版

**繁體中文** | [English](#astnovel-for-sailfish-os)

一款 Sailfish OS 小說寫作應用程式，自原版 HarmonyOS ArkUI-X 應用 AstNovel（AstNovel-astn）移植。套件版本 `4.50.Ast.3`，與原版對齊。

## 功能

- **書籍管理** - 書架網格與封面（圖片或自動生成漸層）、資料編輯、`.astn` 匯入時的同名衝突詢問（建立副本 / 覆蓋 / 跳過）
- **章節** - 編輯器附 Markdown 工具列（粗體 / 斜體 / H1-H3 / 有序 / 無序清單）、CJK 字數統計、每 30 秒自動儲存與當機復原
- **速查** - 編輯器內底部抽屜，列出大綱、角色（全部十個欄位）與世界觀條目；裝置 GPU 允許時使用即時高斯模糊背景，否則退回靜態快照
- **角色** - 十欄位結構化表單（姓名、年齡、性別、身高、體重、種族、外貌、性格、背景、備註）、圓形頭像、圖片集
- **世界觀設定** - 五大分類（地理 / 歷史 / 力量體系 / 社會結構 / 其他），沿用原版的欄位範本
- **大綱** - 卷 / 章 / 節樹狀結構，可連結章節、角色與世界觀條目
- **桌面封面卡片** - 顯示目前頁面的即時縮圖；無可用畫面時退回整卡純色加應用程式圖示
- **匯出** - TXT（去除 Markdown 標記）、Markdown 或 `.astn` v2.0，可選擇資料夾
- **完全離線** - 無網路權限、無網路呼叫，所有資料僅存於裝置

原版 HarmonyOS 應用寫出的 `.astn` v2.0（PBKDF2-HMAC-SHA256 + AES-256-GCM）檔案可直接匯入，本版匯出的檔案亦可匯回原版——容器、金鑰衍生、各資產 JSON 結構完全一致，含封面、角色頭像、圖片集與大綱節點。

## 安裝

提供三種架構的套件：

| 檔案 | 裝置 |
|---|---|
| `harbour-astnovel-4.50.Ast.3-1.armv7hl.rpm` | Jolla 1、Jolla C、Xperia X、Xperia XA2 |
| `harbour-astnovel-4.50.Ast.3-1.aarch64.rpm` | Xperia 10 系列、Jolla C2 |
| `harbour-astnovel-4.50.Ast.3-1.i486.rpm` | SDK 模擬器 |

在已開啟開發者模式的裝置上：

```bash
devel-su rpm -Uvh harbour-astnovel-4.50.Ast.3-1.<架構>.rpm
```

或使用 SDK：`sfdk -c device=<名稱> deploy`。使用者資料位於 `~/.local/share/harbour-astnovel/`，解除安裝不會刪除。

## 專案結構

```
AstNovel-Sailfish/
├── sfdk/harbour-astnovel/      # Sailfish 套件（唯一事實來源）
│   ├── src/                    # C++：AstnStore（儲存、加密、Q_INVOKABLE 介面）
│   ├── qml/pages/              # Silica 頁面（書架、詳情、編輯器、角色……）
│   ├── qml/components/         # Apple 風格元件、卡片、模糊背景
│   ├── qml/styles/             # 設計令牌單例（AstnStyle）
│   ├── rpm/                    # RPM spec
│   └── harbour-astnovel.pro
└── README.md
```

## 架構說明

- **C++（`AstnStore`）** - JSON 檔案儲存於 `QStandardPaths::AppDataLocation`，PBKDF2-HMAC-SHA256 金鑰衍生，`.astn` 採 AES-256-GCM 分塊加密，透過 `Q_INVOKABLE` 方法供 QML 呼叫（書籍、章節、角色、世界觀、大綱、匯出匯入、自動儲存、封面畫面擷取）
- **QML（Qt 5.6 / Silica）** - iOS 風格淺色主題，固定色板（`AstnStyle` 單例）；除經探測閘控的速查模糊外，不使用執行期漸層與著色器；封面漸層為預先烘焙的 PNG 貼圖，確保軟體渲染下捲動流暢
- **封面縮圖** - 以 `grabToImage` 擷取頁面，由 C++ 存為快取目錄中的 PNG，再由封面視窗載入（封面視窗無法使用視窗內的抓取 URL）；退到背景時保留最後一幀

## 建置

需要安裝 Sailfish SDK 及 5.1.0.11 各目標。

```bash
cd sfdk/harbour-astnovel
sfdk -c target=SailfishOS-5.1.0.11-i486 build      # 模擬器
sfdk -c target=SailfishOS-5.1.0.11-armv7hl build   # 32 位元裝置
sfdk -c target=SailfishOS-5.1.0.11-aarch64 build   # 64 位元裝置
```

切換目標時請先清除本機建置產物（`Makefile*`、`*.o`、`moc_*.cpp`、`harbour-astnovel` 執行檔），否則 qmake 可能重用上一個架構編譯的目標檔。

## 支援

- 錯誤回報與問題：[GitHub Issues](https://github.com/Astenyx-Git/AstNovel-Sailfish/issues)

## 銘謝

- 原版 HarmonyOS 應用：AstNovel-astn，作者 Astenyx
- Sailfish OS 移植：Astenyx

Copyright (c) 2026 Astenyx. 保留一切權利。
