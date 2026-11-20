<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">ディスプレイのくっきりした HiDPI 解像度を、メニューバーからワンクリックで</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="最新リリース"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="総ダウンロード数"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="最新リリースのダウンロード数"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="ライセンス"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <b>日本語</b> · <a href="README.de.md">Deutsch</a> · <a href="README.ko.md">한국어</a> · <a href="README.fr.md">Français</a> · <a href="README.es.md">Español</a>
</p>

> **KeenQuad** は、ディスプレイの HiDPI 解像度を切り替える小さなメニューバーアプリです。「システム設定」に表示されない、くっきりした解像度にも切り替えられます。
> 多くの外部ディスプレイでは、1600 × 1000 のような解像度は「システム設定」に 1 倍版しか表示されず、ぼやけて見えます。macOS にはくっきり表示される HiDPI 版もありますが、ディスプレイモードの一覧をすべて読み取れるアプリでなければ切り替えられません。KeenQuad はそれだけを行います。

## 同じ解像度がぼやけたり、くっきりしたりする理由

macOS のディスプレイモード一覧には、同じサイズが通常 2 つあります。2560 × 1600 のパネルで 1600 × 1000 を使う場合：

| 種類 | macOS の描画方法 | 見え方 |
|---|---|---|
| 1 倍 | 1600 × 1000 ピクセルで描画し、パネルに引き伸ばす | ぼやける |
| HiDPI | 3200 × 2000 ピクセルで描画し、パネルに縮小する | くっきり |

「システム設定 › ディスプレイ」は公開 API のモードしか表示せず、公開 API は多くの HiDPI 版を隠しています。そこで 1600 × 1000 を選ぶと 1 倍版になります。KeenQuad で設定した HiDPI 解像度を使っているとき、「システム設定」は同じ名前のものを選択中と表示しますが、それをもう一度クリックするとぼやけた版に切り替わります。

いまどちらを使っているかは `system_profiler SPDisplaysDataType` で確認できます。HiDPI では **Resolution** が **UI Looks like** の 2 倍です。

## 機能

- 各ディスプレイのすべての HiDPI 解像度を、隠れたものも含めて一覧表示。現在の解像度とパネルのドットバイドットのサイズを示します
- クリックで切り替え。新しい解像度を 15 秒以内に確定しないと自動で元に戻るので、画面が真っ暗になっても自然に復帰します
- ぼやけた 1 倍解像度を使っていると、同じサイズの **高精細版に切り替え** がメニューに表示されます。デスクトップの広さは変わりません
- 確定した解像度は、終了・ログアウト・再起動後もそのまま。macOS が保存するので、バックグラウンドで動くものはありません
- ログイン時に起動、**アップデートを確認…**
- English、简体中文、繁體中文、日本語、Deutsch、한국어、Français、Español に対応。システムの言語に従うほか、メニューで選ぶこともできます

## システム要件

- Apple シリコン搭載の Mac
- macOS 14 以降

## インストール

### 方法 1：1 行でインストール（おすすめ、Gatekeeper の警告なし）

「ターミナル」を開き、次の行を貼り付けて Return キーを押します：

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

スクリプトは GitHub から最新リリースをダウンロードし、SHA-256 を確認してから「アプリケーション」にインストールして起動します。curl でダウンロードしたファイルには隔離フラグが付かないため、初回起動がブロックされません。KeenQuad がすでにインストールされている場合はその場で更新され、「ログイン時に起動」の設定も保たれます。スクリプトは短いので、先に[中身を確認](../install.sh)してもかまいません。

### 方法 2：ZIP

[Releases](https://github.com/33to9/KeenQuad/releases/latest) から最新の `KeenQuad_vX.Y.Z_macOS.zip` をダウンロードして展開し、KeenQuad を「アプリケーション」フォルダに移動します。

このアプリは Apple の公証を受けていないため、初回起動が一度ブロックされます：
- **macOS 15 以降**：ダブルクリック（警告が表示されます）してから **システム設定 → プライバシーとセキュリティ** を開き、下にスクロールして **このまま開く** をクリック
- **macOS 14**：アプリを右クリック → **開く**

### アップデート

KeenQuad のメニューで **アップデートを確認…** を選びます。新しいバージョンがあれば変更内容を表示し、ダウンロードページを開きます。Gatekeeper の警告なしで更新するには、上の 1 行インストールをもう一度実行してください。

## 使い方

メニューバーの KeenQuad アイコンをクリックします：

- 解像度をクリックすると切り替わります。新しい解像度では **この解像度のままにしますか？** と表示されます。Return で維持、Esc で元に戻す、15 秒待つと自動で元に戻ります。以前に維持した解像度にはすぐに切り替わります。
- 現在の解像度が高精細版のある 1 倍解像度のときは **高精細版に切り替え** が表示されます。
- **その他の縦横比** には、パネルと縦横比が異なる HiDPI 解像度があります。
- **言語** と **ログイン時に起動** はメニューの下部にあります。

## アクセス権

必要ありません。ディスプレイモードの切り替えに、画面収録やアクセシビリティなどのアクセス権は不要です。macOS がログイン項目の許可を求めた場合は、KeenQuad が「システム設定」の該当ページを開きます。

## プライバシー

KeenQuad は何も収集せず、利用統計もありません。インターネットに接続するのは **アップデートを確認…** をクリックしたときだけで、最新リリースを調べるために GitHub API へ 1 回リクエストを送ります。あなたに関する情報は含みません。設定は `~/Library/Preferences/com.keenquad.app.plist` に保存されます。

## アンインストール

1. KeenQuad のメニューで **ログイン時に起動** をオフにし、**KeenQuad を終了** を選びます。
2. `/Applications/KeenQuad.app` を削除します。
3. 必要なら `defaults delete com.keenquad.app` を実行します。

使用中の解像度はそのまま残ります。変更したい場合は「システム設定」で変更してください。

## 仕組み

KeenQuad は CoreGraphics の非公開関数（`CGSGetNumberOfDisplayModes`、`CGSGetDisplayModeDescriptionOfLength`、`CGSConfigureDisplayMode`）でディスプレイモードの一覧を読み取り、切り替えます。オープンソースの `displayplacer` と同じ関数です。解像度を新たに作ったり、ディスプレイのオーバーライドをインストールしたり、管理者パスワードを求めたりはしません。macOS にすでにあるモードに切り替えるだけです。新しい解像度はまずこのアプリの間だけ有効になるため、KeenQuad が強制終了されると macOS が元に戻します。維持したときにだけ恒久的に保存されます。

非公開関数を使っているため、今後の macOS のアップデートで動かなくなる可能性があります。メニューが空になった場合は [issue を作成](https://github.com/33to9/KeenQuad/issues)してください。

## ソースからビルド

必要なもの：Xcode コマンドラインツール（Xcode は不要）。

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # ビルドして /Applications にインストール
./Tests/run-selftest.sh     # 読み取り専用のルールテスト。解像度は切り替えません
```

`./build.sh --package` でリリース用の `dist/KeenQuad_vX.Y.Z_macOS.zip` を作成します。開発メモ（中国語）は [`tray/README.md`](../tray/README.md)、仕様書は `KeenQuad_Tray_v0_*.md` にあります。

## ライセンス

このプロジェクトは **GPL-3.0-only** でライセンスされています（[LICENSE](../LICENSE) を参照）。KeenQuad の名称とアイコンはライセンスの対象外です。[TRADEMARK.md](../TRADEMARK.md) を参照してください。

Copyright © 2026 [33to9](https://github.com/33to9)
