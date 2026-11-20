<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">在菜单栏一键切换显示器的清晰 HiDPI 分辨率</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="最新版本"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="总下载量"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="最新版本下载量"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="许可证"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <b>简体中文</b> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <a href="README.es.md">Español</a>
</p>

> **KeenQuad** 是一个菜单栏小工具，用来在显示器的 HiDPI 分辨率之间切换，包括“系统设置”里看不到的清晰档位。
> 在很多外接显示器上，像 1600 × 1000 这样的分辨率在“系统设置”里只有 1 倍版本，看起来发虚。macOS 其实还有它的 HiDPI 版本，画面清晰，但只有读取完整显示模式表的应用才能切过去。KeenQuad 只做这一件事。

## 为什么同一个分辨率有的发虚、有的清晰

macOS 的显示模式表里，同一个尺寸通常有两条记录。以 2560 × 1600 面板上的 1600 × 1000 为例：

| 版本 | macOS 的绘制方式 | 观感 |
|---|---|---|
| 1 倍 | 按 1600 × 1000 像素绘制，再放大到面板 | 发虚 |
| HiDPI | 按 3200 × 2000 像素绘制，再缩小到面板 | 清晰 |

“系统设置 › 显示器”只列出公开接口给出的模式，而公开接口隐藏了很多 HiDPI 版本。在那里选 1600 × 1000，得到的是 1 倍版本。当前模式是 KeenQuad 切的 HiDPI 档位时，“系统设置”会因为名字相同而显示为选中，再点一次就会切到发虚的版本。

想确认当前用的是哪种，可以运行 `system_profiler SPDisplaysDataType`：HiDPI 下 **Resolution** 是 **UI Looks like** 的两倍。

## 功能

- 列出每块显示器的全部 HiDPI 分辨率，包括隐藏的档位，标出当前档位和面板的点对点尺寸
- 点一下就切换。新分辨率 15 秒内不确认会自动切回，万一黑屏也能自己恢复
- 当前是发虚的 1 倍分辨率时，菜单里会出现 **切换到清晰版**，桌面大小不变
- 保留的分辨率在退出、注销、重启后都保持；由 macOS 保存，没有任何后台进程
- 登录时启动，以及 **检查更新…**
- 支持 English、简体中文、繁體中文、日本語、Deutsch、한국어、Français、Español，默认跟随系统语言，也可以在菜单里指定

## 系统要求

- 搭载 Apple 芯片的 Mac
- macOS 14 或更新版本

## 安装

### 方式 1：一行命令安装（推荐，不会被 Gatekeeper 拦截）

打开“终端”，粘贴下面这行并按回车：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

脚本会从 GitHub 下载最新版本，校验 SHA-256，安装到“应用程序”并打开。用 curl 下载的文件不带隔离标记，所以 macOS 不会拦截首次打开。如果已经装过 KeenQuad，会原地更新，并保留“登录时启动”的设置。脚本很短，可以先[看一看](../install.sh)。

### 方式 2：ZIP

从 [Releases](https://github.com/33to9/KeenQuad/releases/latest) 下载最新的 `KeenQuad_vX.Y.Z_macOS.zip`，解压后把 KeenQuad 移到“应用程序”文件夹。

这个应用没有经过 Apple 公证，macOS 会拦截一次首次打开：
- **macOS 15 及更新版本**：双击（会出现警告），然后打开 **系统设置 → 隐私与安全**，向下滚动，点 **仍要打开**
- **macOS 14**：右键点按应用 → **打开**

### 更新

在 KeenQuad 的菜单里选 **检查更新…**。有新版本时会显示更新内容，并打开下载页面。想避开 Gatekeeper 提示，就再运行一次上面的一行命令。

## 使用方法

点菜单栏里的 KeenQuad 图标：

- 点一个分辨率即可切换。新分辨率会询问 **保留这个分辨率吗？**：按回车保留，按 Esc 还原，或者等 15 秒自动还原。以前保留过的分辨率会直接切换。
- 当前是有清晰版的 1 倍分辨率时，会出现 **切换到清晰版**。
- **其他比例** 里是形状和面板不一致的 HiDPI 尺寸。
- **语言** 和 **登录时启动** 在菜单底部。

## 权限

不需要任何权限。切换显示模式不需要屏幕录制、辅助功能等权限。如果 macOS 要求批准登录项，KeenQuad 会打开“系统设置”里对应的页面。

## 隐私

KeenQuad 不收集任何数据，没有统计功能。只有在你点 **检查更新…** 时才联网：向 GitHub API 发一次请求查询最新版本，请求里不带任何关于你的信息。设置保存在 `~/Library/Preferences/com.keenquad.app.plist`。

## 卸载

1. 在 KeenQuad 的菜单里关闭 **登录时启动**，然后选 **退出 KeenQuad**。
2. 删除 `/Applications/KeenQuad.app`。
3. 可选：运行 `defaults delete com.keenquad.app`。

当前使用的分辨率会保持不变，需要的话可以在“系统设置”里改。

## 工作原理

KeenQuad 通过 CoreGraphics 的私有函数（`CGSGetNumberOfDisplayModes`、`CGSGetDisplayModeDescriptionOfLength`、`CGSConfigureDisplayMode`）读取和切换显示模式表，开源工具 `displayplacer` 用的也是这一组函数。它不创建分辨率，不安装显示器覆盖文件，也不需要管理员密码，只切换到 macOS 已有的模式。新分辨率先只对本应用生效，所以 KeenQuad 被强制退出时 macOS 会自动还原；只有你点“保留”后才会永久保存。

由于用的是私有函数，以后的 macOS 更新可能会改变它们。如果哪天菜单是空的，请[提交 issue](https://github.com/33to9/KeenQuad/issues)。

## 从源码构建

需要：Xcode 命令行工具（不需要 Xcode）。

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # 构建并安装到 /Applications
./Tests/run-selftest.sh     # 只读规则自测，不会切换分辨率
```

`./build.sh --package` 会生成用于发布的 `dist/KeenQuad_vX.Y.Z_macOS.zip`。开发说明见 [`tray/README.md`](../tray/README.md)，需求说明见 `KeenQuad_Tray_v0_*.md`。

## 许可证

本项目采用 **GPL-3.0-only** 许可证（见 [LICENSE](../LICENSE)）。KeenQuad 名称和图标不在许可范围内，见 [TRADEMARK.md](../TRADEMARK.md)。

Copyright © 2026 [33to9](https://github.com/33to9)
