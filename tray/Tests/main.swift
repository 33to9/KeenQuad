// 只读自测：用 7.1 的模式表校验 F3/F4 规则，再读取本机真实模式表打印菜单。不切换任何模式。
// 运行：./Tests/run-selftest.sh
import AppKit

let table71: [(Int32, Int, Int, Int, Double, UInt32)] = [
 (0,800,500,60,1,0x1),(1,800,600,60,2,0x1),(2,800,600,60,1,0x1),(3,960,540,60,2,0x1),(4,960,540,50,2,0x1),
 (5,960,600,60,2,0x1),(6,1024,640,60,2,0x1),(7,1024,640,60,1,0x1),(8,1024,768,60,1,0x1),(9,1152,864,75,1,0x1),
 (10,1280,720,60,2,0x1),(11,1280,800,60,2,0x02000007),(12,1280,800,60,1,0x1),(13,1280,960,60,1,0x1),
 (14,1280,1024,60,1,0x1),(15,1344,840,60,1,0x1),(16,1344,1008,60,1,0x1),(17,1600,1000,60,1,0x1),
 (18,1600,1200,60,1,0x1),(19,1920,1080,60,1,0x1),(20,1920,1080,50,1,0x1),(21,1920,1200,60,1,0x1),
 (22,2048,1280,60,1,0x1),(23,2560,1440,60,1,0x1),(24,2560,1600,60,1,0x02000001),(25,1024,768,60,2,0x00200001),
 (26,1280,960,60,2,0x00200001),(27,1344,840,60,2,0x00200001),(28,1344,1008,60,2,0x00200001),
 (29,1600,1000,60,2,0x00200001),(30,1600,1200,60,2,0x00200001),(31,1920,1200,60,2,0x00200001),
 (32,2048,1280,60,2,0x00200001),(33,2560,1600,75,2,0x00200001),(34,2560,1600,60,2,0x00200001),
 (35,2560,1600,50,2,0x00200001),(36,400,300,60,2,0x40000000),(37,400,300,60,2,0x40000000),(38,512,320,60,2,0x40000000),
 (39,512,384,60,2,0x40000000),(40,512,384,60,2,0x40000000),(41,576,432,75,2,0x40000000),(42,640,400,60,2,0x40000000),
 (43,640,480,60,2,0x40000000),(44,640,480,60,1,0x40000000),(45,640,480,60,1,0x40000000),(46,640,512,60,2,0x40000000),
 (47,672,420,60,2,0x40000000),(48,672,504,60,2,0x40000000),(49,800,500,60,2,0x40000000),(50,800,600,60,2,0x40000000),
 (51,800,600,60,1,0x40000000),(52,1024,768,60,1,0x40000000),(53,1600,1200,60,1,0x40000000),
]
LanguageSetting.forced = .zhHans   // 原有自测按简体中文文案比对
let modes = table71.map { Mode(number: $0.0, width: $0.1, height: $0.2, hz: $0.3, density: $0.4, flags: $0.5, depth: 8) }

let S = "\u{3000}"
let expected = [
 "ARZOPA\(S)当前 1600 × 1000",
 "  960 × 600", "  1024 × 640", "  1280 × 800\(S)点对点", "  1344 × 840", "✓ 1600 × 1000",
 "  1920 × 1200", "  2048 × 1280", "  2560 × 1600",
 "  其他比例 ▸",
 "        800 × 600", "        960 × 540", "        1024 × 768", "        1280 × 720",
 "        1280 × 960", "        1344 × 1008", "        1600 × 1200",
]
var failures = 0
func check(_ cond: Bool, _ msg: String) { if !cond { failures += 1; print("FAIL: \(msg)") } }

let c = CandidateRules.compute(table: modes, currentNumber: 29)
let got = MenuText.render(name: "ARZOPA", candidates: c)
check(got == expected, "F4.1 菜单文本\n" + got.joined(separator: "\n"))
check(c.main.map(\.mode.number) == [5, 6, 11, 27, 29, 31, 32, 34], "7.2 主列表模式号 \(c.main.map(\.mode.number))")
check(c.others.map(\.mode.number) == [1, 3, 25, 10, 26, 28, 30], "7.2 其他比例模式号 \(c.others.map(\.mode.number))")
check(modes[29].signature == "1600x1000@2x@60", "签名格式 \(modes[29].signature)")

// 当前为 75Hz 的 33 号：2560 × 1600 应选 33 并打勾，其他档位追加 60Hz
let c75 = CandidateRules.compute(table: modes, currentNumber: 33)
check(c75.main.last?.mode.number == 33 && c75.main.last?.isCurrent == true, "F3.2 同刷新率优先")
check(MenuText.itemTitle(c75.main[0]).main == "960 × 600\(S)60Hz", "F4.5 刷新率后缀 \(MenuText.itemTitle(c75.main[0]).main)")

// 当前为非 HiDPI 的 17 号：无勾，标题注明
let c17 = CandidateRules.compute(table: modes, currentNumber: 17)
check(!(c17.main + c17.others).contains { $0.isCurrent }, "F3.6 非 HiDPI 不打勾")
check(MenuText.render(name: "ARZOPA", candidates: c17)[0] == "ARZOPA\(S)当前 1600 × 1000（非 HiDPI）", "F4.2 非 HiDPI 标题")

// 没有候选
let none = CandidateRules.compute(table: modes.filter { $0.density == 1 }, currentNumber: 17)
check(MenuText.render(name: "X", candidates: none).last == "  没有可用的 HiDPI 档位", "F4.8 无候选")

// 还原定位：签名重复时（1 号与 50 号）优先号码一致、其次可用于桌面
check(CandidateRules.locate(signature: "800x600@2x@60", preferredNumber: 50, in: modes)?.number == 50, "locate 号码优先")
check(CandidateRules.locate(signature: "800x600@2x@60", preferredNumber: 99, in: modes)?.number == 1, "locate 桌面可用优先")

// F12.1：各个 1 倍模式的清晰版（v0.2 第 3 节表格）
let sharpTable: [(Int32, Int32?)] = [(17, 29), (21, 31), (22, 32), (15, 27), (18, 30), (12, 11), (24, nil), (19, nil)]
for (cur, want) in sharpTable {
    let got = CandidateRules.compute(table: modes, currentNumber: cur).sharpVersion?.mode.number
    check(got == want, "F12.1 当前 #\(cur) 清晰版应为 \(want.map(String.init) ?? "无")，实际 \(got.map(String.init) ?? "无")")
}
check(c.sharpVersion == nil, "F12.6 当前 HiDPI 时无修复项")
let r17 = MenuText.render(name: "ARZOPA", candidates: c17)
check(r17.count > 1 && r17[1] == "  切换到清晰版 1600 × 1000", "F12.2 修复项位于标题下 \(r17.prefix(3))")
check(L10n.confirmRender(w: 4096, h: 2560) == "按 4096 × 2560 像素渲染（HiDPI），画面清晰。", "F6.2 修订文案")

// F13：系统语言归并（v0.3 第 3 节）
let resolveCases: [([String], AppLanguage)] = [
    (["zh-Hans-CN"], .zhHans), (["zh-CN"], .zhHans), (["zh-SG"], .zhHans), (["zh"], .zhHans),
    (["zh-Hant-TW"], .zhHant), (["zh-TW"], .zhHant), (["zh-HK"], .zhHant), (["zh-MO"], .zhHant), (["zh-Hant"], .zhHant),
    (["zh-Hans-HK"], .zhHans), (["en-GB"], .en), (["es-419"], .es), (["fr-CA"], .fr), (["de-DE"], .de),
    (["ja-JP"], .ja), (["ko-KR"], .ko), (["pt_BR"], .en),
    (["it-IT", "ja-JP"], .ja), (["it", "ru"], .en), ([], .en),
]
for (pref, want) in resolveCases {
    let got = AppLanguage.resolve(preferred: pref)
    check(got == want, "F13 归并 \(pref) 应为 \(want.rawValue)，实际 \(got.rawValue)")
}
check(AppLanguage.allCases.map(\.rawValue) == ["en", "zh-Hans", "zh-Hant", "ja", "de", "ko", "fr", "es"], "F13.1 语言顺序")
check(AppLanguage.allCases.map(\.nativeName) == ["English", "简体中文", "繁體中文", "日本語", "Deutsch", "한국어", "Français", "Español"], "F13.1 语言名称")

// F4.9 修订：每种语言的全部文案非空，菜单可完整渲染
for lang in AppLanguage.allCases {
    let t = StringTable.table(for: lang)
    let texts: [String] = [
        t.gap, t.displayFallbackName(2), t.current("1600 × 1000"), t.notHiDPI, t.pointToPoint, t.otherAspects,
        t.noDisplays, t.noHiDPIModes, t.sharpVersion("1600 × 1000"), t.sharpVersionTip("1600 × 1000", "3200 × 2000"),
        t.launchAtLogin, t.language, t.followSystem, t.quit, t.confirmTitle, t.confirmRender("3200 × 2000"),
        t.confirmBody(15, "1600 × 1000"), t.keep, t.revert, t.switchFailedTitle, t.switchFailedBody(-1),
        t.loginItemFailedTitle, t.loginItemFailedBody("E"), t.loginItemNeedsApproval, t.ok,
    ]
    check(texts.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty || $0 == t.gap }, "F4.9 \(lang.rawValue) 有空文案")
    check(t.sharpVersionTip("1600 × 1000", "3200 × 2000").contains("3200 × 2000") && t.confirmBody(15, "1600 × 1000").contains("15")
          && t.confirmBody(15, "1600 × 1000").contains("1600 × 1000") && t.switchFailedBody(-7).contains("-7"), "F4.9 \(lang.rawValue) 占位符缺失")
    LanguageSetting.forced = lang
    let r = MenuText.render(name: "ARZOPA", candidates: c17)
    print("[\(lang.rawValue)] " + r.prefix(5).joined(separator: " / "))
}
check(StringTable.en.loginItemNeedsApproval.contains("System Settings › General › Login Items"), "F4.9 en 路径")
check(StringTable.fr.loginItemNeedsApproval.contains("Réglages Système › Général › Ouverture"), "F4.9 fr 路径")
LanguageSetting.forced = .zhHans

// F14：版本比较与 Release 解码（v0.4 第 3 节）
check(UpdateLogic.parse("v0.4.0") == [0, 4, 0] && UpdateLogic.parse("0.4") == [0, 4] && UpdateLogic.parse("V1") == [1], "F14 解析")
check(UpdateLogic.parse("0.4.0-beta") == nil && UpdateLogic.parse("") == nil && UpdateLogic.parse("1..2") == nil && UpdateLogic.parse("v") == nil, "F14 非数字段")
check(!UpdateLogic.isNewer([0, 4], than: [0, 4, 0]) && !UpdateLogic.isNewer([0, 4, 0], than: [0, 4]), "F14 段数不同视为相等")
check(UpdateLogic.isNewer([0, 4, 1], than: [0, 4]) && UpdateLogic.isNewer([0, 10], than: [0, 9, 9]) && !UpdateLogic.isNewer([0, 3, 9], than: [0, 4]), "F14 比较")
check(UpdateLogic.isValidRepository("33to9/KeenQuad") && !UpdateLogic.isValidRepository("OWNER") && !UpdateLogic.isValidRepository("a/b/c") && !UpdateLogic.isValidRepository(nil), "F14 仓库地址")
func json(_ tag: String, body: String? = "Notes") -> Data {
    var d: [String: Any] = ["tag_name": tag, "html_url": "https://github.com/33to9/KeenQuad/releases/tag/\(tag)"]
    if let body { d["body"] = body }
    return try! JSONSerialization.data(withJSONObject: d)
}
let rel = URL(string: "https://github.com/33to9/KeenQuad/releases/tag/v0.5.0")!
check(UpdateLogic.evaluate(data: json("v0.5.0"), status: 200, errorDescription: nil, current: "0.4.0") == .newer(version: "0.5.0", url: rel, notes: "Notes"), "F14 有新版本")
check(UpdateLogic.evaluate(data: json("v0.4.0"), status: 200, errorDescription: nil, current: "0.4.0") == .upToDate, "F14 已是最新")
check(UpdateLogic.evaluate(data: json("v0.3.0"), status: 200, errorDescription: nil, current: "0.4.0") == .upToDate, "F14 更旧视为最新")
check(UpdateLogic.evaluate(data: json("nightly"), status: 200, errorDescription: nil, current: "0.4.0") == .failed(.badVersion("nightly")), "F14 版本号无法识别")
check(UpdateLogic.evaluate(data: nil, status: 404, errorDescription: nil, current: "0.4.0") == .failed(.noReleases), "F14 404")
check(UpdateLogic.evaluate(data: nil, status: 403, errorDescription: nil, current: "0.4.0") == .failed(.http(403)), "F14 HTTP 错误")
check(UpdateLogic.evaluate(data: nil, status: nil, errorDescription: "offline", current: "0.4.0") == .failed(.network("offline")), "F14 网络错误")
check(UpdateLogic.evaluate(data: Data("x".utf8), status: 200, errorDescription: nil, current: "0.4.0") == .failed(.badResponse), "F14 内容无法解析")
if case let .newer(_, _, notes) = UpdateLogic.evaluate(data: json("v1.0", body: String(repeating: "长", count: 700)), status: 200, errorDescription: nil, current: "0.4.0") {
    check(notes.count == 601 && notes.hasSuffix("…"), "F14.3 说明截断 \(notes.count)")
} else { check(false, "F14.3 说明截断") }
if case let .newer(_, _, notes) = UpdateLogic.evaluate(data: json("v1.0", body: nil), status: 200, errorDescription: nil, current: "0.4.0") {
    check(notes.isEmpty, "F14 无说明")
} else { check(false, "F14 无说明") }
for lang in AppLanguage.allCases {
    let t = StringTable.table(for: lang)
    let texts = [t.checkForUpdates, t.checkingForUpdates, t.updateAvailableTitle("9.9"), t.currentVersion("0.4.0"), t.download, t.later,
                 t.upToDateTitle, t.updateFailedTitle, t.updateNotConfigured, t.noReleases, t.updateBadResponse, t.httpError(503), t.badVersion("x")]
    check(!texts.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }, "F14.6 \(lang.rawValue) 有空文案")
    check(t.updateAvailableTitle("9.9").contains("9.9") && t.currentVersion("0.4.0").contains("0.4.0") && t.httpError(503).contains("503") && t.badVersion("qq").contains("qq"), "F14.6 \(lang.rawValue) 占位符")
}

print(failures == 0 ? "规则自测：全部通过" : "规则自测：\(failures) 项失败")

// 本机只读
print("\n本机实测（只读）：")
for (i, d) in Displays.active().enumerated() {
    let t = PrivateDisplay.modeTable(of: d)
    let cur = PrivateDisplay.currentModeNumber(of: d)
    let name = NSScreen.screens.first {
        ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == d
    }?.localizedName ?? L10n.displayFallbackName(i + 1)
    print("display \(d) uuid=\(Displays.uuid(of: d)) 模式表 \(t.count) 条 当前 #\(cur)")
    let live = CandidateRules.compute(table: t, currentNumber: cur)
    MenuText.render(name: name, candidates: live).forEach { print("  " + $0) }
    let liveMatches71 = t.count == modes.count && zip(t, modes).allSatisfy { $0.number == $1.number && $0.width == $1.width && $0.height == $1.height && $0.hz == $1.hz && $0.density == $1.density && $0.flags == $1.flags }
    print("  与 7.1 表逐条一致：\(liveMatches71)")
}
exit(failures == 0 ? 0 : 1)
