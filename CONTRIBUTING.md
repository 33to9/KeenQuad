# Contributing to KeenQuad

Thanks for your interest in KeenQuad. Bug reports, display reports and ideas are very welcome. Code pull requests are not being merged for now; the reason is explained below.

## Reporting a bug

Please [open an issue](https://github.com/33to9/KeenQuad/issues) and include:

- the KeenQuad version (shown in the menu) and the macOS version;
- the Mac model, the display model, and how it's connected (HDMI, USB-C, DisplayPort, a dock or an adapter);
- what you did, what you expected, and what happened instead;
- the output of this command, which lists your displays and their current modes:

  ```bash
  system_profiler SPDisplaysDataType
  ```

If switching failed or the menu came up empty, KeenQuad's own log helps too. Run this right after the problem happens:

```bash
log show --last 10m --info --predicate 'subsystem == "com.pivotfrag.keenquad"'
```

The log contains display UUIDs and resolutions, and nothing else about you or your Mac. Remove anything you'd rather not share before posting.

If your screen went black: wait 15 seconds, or press Esc. A resolution you haven't kept reverts by itself.

## Reporting how a display behaves

KeenQuad has been tested on very few displays. If it works well on yours, or lists resolutions that look wrong, an issue with the display model, the connection and the `system_profiler` output above is useful even when nothing is broken.

## Suggesting a feature

Open an issue and describe the problem you're trying to solve, not only the feature. KeenQuad is deliberately small: it switches between display modes macOS already has. Brightness, volume and other hardware controls are out of scope.

## Translations

If a string in the app or a README reads badly in your language, open an issue with the current text and your suggested wording. Please say which language and where the text appears.

## Code pull requests

Pull requests with code or translations are **not merged at the moment**. Please don't spend time on one before asking in an issue.

The reason is licensing. KeenQuad is published under GPL-3.0-only, and Pivotfrag LLC also intends to distribute builds under other terms. That is only possible while Pivotfrag LLC holds the copyright to all of the code. Merging a contribution without a signed agreement would end that.

A contributor license agreement is planned. Until it exists:

- describe the fix or the idea in an issue, and it will be implemented by the maintainer if it fits;
- you're free to fork KeenQuad and change it under the GPL. If you distribute your version, see [TRADEMARK.md](TRADEMARK.md) for the name and icons.

## Security

If you find a security problem, please don't post the details publicly. Email [support@keenquad.com](mailto:support@keenquad.com) instead.

---

## 参与 KeenQuad（简体中文摘要）

欢迎提交 bug 报告、显示器兼容情况和功能建议；**目前暂不合并代码或翻译的 Pull Request**。

**报告问题时请附上：** KeenQuad 版本（菜单里可见）和 macOS 版本；Mac 型号、显示器型号和连接方式（HDMI、USB-C、DisplayPort、扩展坞或转接头）；操作步骤、预期结果和实际结果；`system_profiler SPDisplaysDataType` 的输出。切换失败或菜单为空时，请在问题出现后立即运行上面的 `log show` 命令并附上结果。

**屏幕黑了：** 等 15 秒或按 Esc，未保留的分辨率会自动还原。

**为什么暂不合并 PR：** KeenQuad 以 GPL-3.0-only 发布，同时 Pivotfrag LLC 打算以其他条款分发构建版本。这要求 Pivotfrag LLC 持有全部代码的版权，未签协议就合并外部贡献会破坏这一前提。贡献者协议（CLA）准备好之前，请在 issue 里描述修复思路或建议，合适的会由维护者实现。你可以在 GPL 下 fork 并修改；分发修改版时，名称和图标的规定见 [TRADEMARK.md](TRADEMARK.md)。

**安全问题：** 请不要公开细节，发邮件到 [support@keenquad.com](mailto:support@keenquad.com)。
