<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">在選單列一鍵切換顯示器的清晰 HiDPI 解析度</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="最新版本"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="總下載量"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="最新版本下載量"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="授權"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <b>繁體中文</b> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <a href="README.es.md">Español</a>
</p>

> **KeenQuad** 是一個選單列小工具，用來在顯示器的 HiDPI 解析度之間切換，包括「系統設定」裡看不到的清晰檔位。
> 在許多外接顯示器上，像 1600 × 1000 這樣的解析度在「系統設定」裡只有 1 倍版本，看起來會模糊。macOS 其實還有它的 HiDPI 版本，畫面清晰，但只有讀取完整顯示模式表的 App 才能切過去。KeenQuad 只做這一件事。

## 為什麼同一個解析度有的模糊、有的清晰

macOS 的顯示模式表裡，同一個尺寸通常有兩筆記錄。以 2560 × 1600 面板上的 1600 × 1000 為例：

| 版本 | macOS 的繪製方式 | 觀感 |
|---|---|---|
| 1 倍 | 以 1600 × 1000 像素繪製，再放大到面板 | 模糊 |
| HiDPI | 以 3200 × 2000 像素繪製，再縮小到面板 | 清晰 |

「系統設定 › 顯示器」只列出公開介面提供的模式，而公開介面隱藏了許多 HiDPI 版本。在那裡選 1600 × 1000，得到的是 1 倍版本。目前模式是 KeenQuad 切換的 HiDPI 檔位時，「系統設定」會因為名稱相同而顯示為已選取，再點一次就會切到模糊的版本。

想確認目前用的是哪一種，可以執行 `system_profiler SPDisplaysDataType`：HiDPI 下 **Resolution** 是 **UI Looks like** 的兩倍。

## 功能

- 列出每台顯示器的全部 HiDPI 解析度，包括隱藏的檔位，標出目前檔位和面板的點對點尺寸
- 點一下就切換。新解析度 15 秒內不確認會自動切回，萬一黑畫面也能自己恢復
- 目前是模糊的 1 倍解析度時，選單裡會出現 **切換到清晰版**，桌面大小不變
- 保留的解析度在結束、登出、重新開機後都會維持；由 macOS 儲存，沒有任何背景程序
- 登入時啟動，以及 **檢查更新…**
- 支援 English、简体中文、繁體中文、日本語、Deutsch、한국어、Français、Español，預設跟隨系統語言，也可以在選單裡指定

## 系統需求

- 搭載 Apple 晶片的 Mac
- macOS 14 或以上版本

## 安裝

### 方式 1：一行指令安裝（建議，不會被 Gatekeeper 阻擋）

打開「終端機」，貼上下面這行並按 Return：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

腳本會從 GitHub 下載最新版本、驗證 SHA-256、安裝到「應用程式」並打開。用 curl 下載的檔案不帶隔離標記，所以 macOS 不會阻擋第一次打開。如果已經安裝過 KeenQuad，會就地更新，並保留「登入時啟動」的設定。腳本很短，可以先[看一看](../install.sh)。

### 方式 2：ZIP

從 [Releases](https://github.com/33to9/KeenQuad/releases/latest) 下載最新的 `KeenQuad_vX.Y.Z_macOS.zip`，解壓縮後把 KeenQuad 移到「應用程式」檔案夾。

這個 App 沒有經過 Apple 公證，macOS 會阻擋一次第一次打開：
- **macOS 15 及以上版本**：按兩下（會出現警告），然後打開 **系統設定 → 隱私權與安全性**，向下捲動，點 **強制打開**
- **macOS 14**：按右鍵點 App → **打開**

### 更新

在 KeenQuad 的選單裡選 **檢查更新…**。有新版本時會顯示更新內容，並打開下載頁面。想避開 Gatekeeper 提示，就再執行一次上面的一行指令。

## 使用方式

點選單列裡的 KeenQuad 圖像：

- 點一個解析度即可切換。新解析度會詢問 **要保留這個解析度嗎？**：按 Return 保留，按 Esc 還原，或等 15 秒自動還原。以前保留過的解析度會直接切換。
- 目前是有清晰版的 1 倍解析度時，會出現 **切換到清晰版**。
- **其他比例** 裡是形狀和面板不一致的 HiDPI 尺寸。
- **語言** 和 **登入時啟動** 在選單底部。

## 權限

不需要任何權限。切換顯示模式不需要螢幕錄製、輔助使用等權限。如果 macOS 要求批准登入項目，KeenQuad 會打開「系統設定」裡對應的頁面。

## 隱私權

KeenQuad 不收集任何資料，沒有統計功能。只有在你點 **檢查更新…** 時才連網：向 GitHub API 發一次請求查詢最新版本，請求裡不帶任何關於你的資訊。設定儲存在 `~/Library/Preferences/com.keenquad.app.plist`。

## 解除安裝

1. 在 KeenQuad 的選單裡關閉 **登入時啟動**，然後選 **結束 KeenQuad**。
2. 刪除 `/Applications/KeenQuad.app`。
3. 可選：執行 `defaults delete com.keenquad.app`。

目前使用的解析度會維持不變，需要的話可以在「系統設定」裡更改。

## 運作原理

KeenQuad 透過 CoreGraphics 的私有函式（`CGSGetNumberOfDisplayModes`、`CGSGetDisplayModeDescriptionOfLength`、`CGSConfigureDisplayMode`）讀取和切換顯示模式表，開源工具 `displayplacer` 用的也是這一組函式。它不建立解析度、不安裝顯示器覆寫檔，也不需要管理員密碼，只切換到 macOS 已有的模式。新解析度先只對本 App 生效，所以 KeenQuad 被強制結束時 macOS 會自動還原；只有你點「保留」後才會永久儲存。

由於用的是私有函式，日後的 macOS 更新可能會改變它們。如果哪天選單是空的，請[提交 issue](https://github.com/33to9/KeenQuad/issues)。

## 從原始碼建置

需要：Xcode 命令列工具（不需要 Xcode）。

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # 建置並安裝到 /Applications
./Tests/run-selftest.sh     # 唯讀規則自我測試，不會切換解析度
```

`./build.sh --package` 會產生用於發佈的 `dist/KeenQuad_vX.Y.Z_macOS.zip`。開發說明（簡體中文）見 [`tray/README.md`](../tray/README.md)。

## 授權

本專案採用 **GPL-3.0-only** 授權（見 [LICENSE](../LICENSE)）。KeenQuad 名稱和圖像不在授權範圍內，見 [TRADEMARK.md](../TRADEMARK.md)。

Copyright © 2026 [33to9](https://github.com/33to9)
