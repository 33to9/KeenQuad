// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC
// Read-only self-test: checks the rules against a reference mode table (an ARZOPA 2560 × 1600 panel),
// then reads the connected displays' real tables and prints their menus. Switches nothing.
// Run: ./Tests/run-selftest.sh
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
LanguageSetting.forced = .zhHans   // the menu-text checks below compare Simplified Chinese strings
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
check(got == expected, "menu text\n" + got.joined(separator: "\n"))
check(c.main.map(\.mode.number) == [5, 6, 11, 27, 29, 31, 32, 34], "main list mode numbers \(c.main.map(\.mode.number))")
check(c.others.map(\.mode.number) == [1, 3, 25, 10, 26, 28, 30], "other aspect ratios mode numbers \(c.others.map(\.mode.number))")
check(modes[29].signature == "1600x1000@2x@60", "signature format \(modes[29].signature)")

// Current mode #33 at 75 Hz: 2560 × 1600 picks #33 and is checked; other sizes append 60Hz
let c75 = CandidateRules.compute(table: modes, currentNumber: 33)
check(c75.main.last?.mode.number == 33 && c75.main.last?.isCurrent == true, "same refresh rate preferred")
check(MenuText.itemTitle(c75.main[0]).main == "960 × 600\(S)60Hz", "refresh rate suffix \(MenuText.itemTitle(c75.main[0]).main)")

// Current mode #17 is 1x: nothing checked, header says so
let c17 = CandidateRules.compute(table: modes, currentNumber: 17)
check(!(c17.main + c17.others).contains { $0.isCurrent }, "1x current mode: nothing checked")
check(MenuText.render(name: "ARZOPA", candidates: c17)[0] == "ARZOPA\(S)当前 1600 × 1000（非 HiDPI）", "1x header")

// No candidates
let none = CandidateRules.compute(table: modes.filter { $0.density == 1 }, currentNumber: 17)
check(MenuText.render(name: "X", candidates: none).last == "  没有可用的 HiDPI 档位", "no candidates")

// Locating for revert: with a duplicate signature (#1 and #50), same number first, then desktop-usable
check(CandidateRules.locate(signature: "800x600@2x@60", preferredNumber: 50, in: modes)?.number == 50, "locate prefers the same number")
check(CandidateRules.locate(signature: "800x600@2x@60", preferredNumber: 99, in: modes)?.number == 1, "locate prefers desktop-usable")

// Sharp version for each 1x mode
let sharpTable: [(Int32, Int32?)] = [(17, 29), (21, 31), (22, 32), (15, 27), (18, 30), (12, 11), (24, nil), (19, nil)]
for (cur, want) in sharpTable {
    let got = CandidateRules.compute(table: modes, currentNumber: cur).sharpVersion?.mode.number
    check(got == want, "sharp version of #\(cur): expected \(want.map(String.init) ?? "none"), got \(got.map(String.init) ?? "none")")
}
check(c.sharpVersion == nil, "no Switch to Sharp item when current mode is HiDPI")
let r17 = MenuText.render(name: "ARZOPA", candidates: c17)
check(r17.count > 1 && r17[1] == "  切换到清晰版 1600 × 1000", "Switch to Sharp item right below the header \(r17.prefix(3))")
check(L10n.confirmRender(w: 4096, h: 2560) == "按 4096 × 2560 像素渲染（HiDPI），画面清晰。", "panel render text")

// Mapping system language codes
let resolveCases: [([String], AppLanguage)] = [
    (["zh-Hans-CN"], .zhHans), (["zh-CN"], .zhHans), (["zh-SG"], .zhHans), (["zh"], .zhHans),
    (["zh-Hant-TW"], .zhHant), (["zh-TW"], .zhHant), (["zh-HK"], .zhHant), (["zh-MO"], .zhHant), (["zh-Hant"], .zhHant),
    (["zh-Hans-HK"], .zhHans), (["en-GB"], .en), (["es-419"], .es), (["fr-CA"], .fr), (["de-DE"], .de),
    (["ja-JP"], .ja), (["ko-KR"], .ko), (["pt_BR"], .en),
    (["it-IT", "ja-JP"], .ja), (["it", "ru"], .en), ([], .en),
]
for (pref, want) in resolveCases {
    let got = AppLanguage.resolve(preferred: pref)
    check(got == want, "language for \(pref): expected \(want.rawValue), got \(got.rawValue)")
}
check(AppLanguage.allCases.map(\.rawValue) == ["en", "zh-Hans", "zh-Hant", "ja", "de", "ko", "fr", "es"], "language order")
check(AppLanguage.allCases.map(\.nativeName) == ["English", "简体中文", "繁體中文", "日本語", "Deutsch", "한국어", "Français", "Español"], "language names")

// Every language has every string, and the menu renders
for lang in AppLanguage.allCases {
    let t = StringTable.table(for: lang)
    let texts: [String] = [
        t.gap, t.displayFallbackName(2), t.current("1600 × 1000"), t.notHiDPI, t.pointToPoint, t.otherAspects,
        t.noDisplays, t.noHiDPIModes, t.sharpVersion("1600 × 1000"), t.sharpVersionTip("1600 × 1000", "3200 × 2000"),
        t.launchAtLogin, t.language, t.followSystem, t.quit, t.confirmTitle, t.confirmRender("3200 × 2000"),
        t.confirmBody(15, "1600 × 1000"), t.keep, t.revert, t.switchFailedTitle, t.switchFailedBody(-1),
        t.loginItemFailedTitle, t.loginItemFailedBody("E"), t.loginItemNeedsApproval, t.ok,
    ]
    check(texts.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty || $0 == t.gap }, "\(lang.rawValue): empty string")
    check(t.sharpVersionTip("1600 × 1000", "3200 × 2000").contains("3200 × 2000") && t.confirmBody(15, "1600 × 1000").contains("15")
          && t.confirmBody(15, "1600 × 1000").contains("1600 × 1000") && t.switchFailedBody(-7).contains("-7"), "\(lang.rawValue): missing placeholder")
    LanguageSetting.forced = lang
    let r = MenuText.render(name: "ARZOPA", candidates: c17)
    print("[\(lang.rawValue)] " + r.prefix(5).joined(separator: " / "))
}
check(StringTable.en.loginItemNeedsApproval.contains("System Settings › General › Login Items"), "en System Settings path")
check(StringTable.fr.loginItemNeedsApproval.contains("Réglages Système › Général › Ouverture"), "fr System Settings path")
LanguageSetting.forced = .zhHans

// Update check: version comparison and release decoding
check(UpdateLogic.parse("v0.4.0") == [0, 4, 0] && UpdateLogic.parse("0.4") == [0, 4] && UpdateLogic.parse("V1") == [1], "parse")
check(UpdateLogic.parse("0.4.0-beta") == nil && UpdateLogic.parse("") == nil && UpdateLogic.parse("1..2") == nil && UpdateLogic.parse("v") == nil, "non-numeric parts")
check(!UpdateLogic.isNewer([0, 4], than: [0, 4, 0]) && !UpdateLogic.isNewer([0, 4, 0], than: [0, 4]), "different part counts compare equal")
check(UpdateLogic.isNewer([0, 4, 1], than: [0, 4]) && UpdateLogic.isNewer([0, 10], than: [0, 9, 9]) && !UpdateLogic.isNewer([0, 3, 9], than: [0, 4]), "compare")
check(UpdateLogic.isValidRepository("33to9/KeenQuad") && !UpdateLogic.isValidRepository("OWNER") && !UpdateLogic.isValidRepository("a/b/c") && !UpdateLogic.isValidRepository(nil), "repository format")
func json(_ tag: String, body: String? = "Notes") -> Data {
    var d: [String: Any] = ["tag_name": tag, "html_url": "https://github.com/33to9/KeenQuad/releases/tag/\(tag)"]
    if let body { d["body"] = body }
    return try! JSONSerialization.data(withJSONObject: d)
}
let rel = URL(string: "https://github.com/33to9/KeenQuad/releases/tag/v0.5.0")!
check(UpdateLogic.evaluate(data: json("v0.5.0"), status: 200, errorDescription: nil, current: "0.4.0") == .newer(version: "0.5.0", url: rel, notes: "Notes"), "newer version")
check(UpdateLogic.evaluate(data: json("v0.4.0"), status: 200, errorDescription: nil, current: "0.4.0") == .upToDate, "up to date")
check(UpdateLogic.evaluate(data: json("v0.3.0"), status: 200, errorDescription: nil, current: "0.4.0") == .upToDate, "older release counts as up to date")
check(UpdateLogic.evaluate(data: json("nightly"), status: 200, errorDescription: nil, current: "0.4.0") == .failed(.badVersion("nightly")), "unrecognized version")
check(UpdateLogic.evaluate(data: nil, status: 404, errorDescription: nil, current: "0.4.0") == .failed(.noReleases), "404")
check(UpdateLogic.evaluate(data: nil, status: 403, errorDescription: nil, current: "0.4.0") == .failed(.http(403)), "HTTP error")
check(UpdateLogic.evaluate(data: nil, status: nil, errorDescription: "offline", current: "0.4.0") == .failed(.network("offline")), "network error")
check(UpdateLogic.evaluate(data: Data("x".utf8), status: 200, errorDescription: nil, current: "0.4.0") == .failed(.badResponse), "unreadable response")
if case let .newer(_, _, notes) = UpdateLogic.evaluate(data: json("v1.0", body: String(repeating: "长", count: 700)), status: 200, errorDescription: nil, current: "0.4.0") {
    check(notes.count == 601 && notes.hasSuffix("…"), "notes truncated \(notes.count)")
} else { check(false, "notes truncated") }
if case let .newer(_, _, notes) = UpdateLogic.evaluate(data: json("v1.0", body: nil), status: 200, errorDescription: nil, current: "0.4.0") {
    check(notes.isEmpty, "no notes")
} else { check(false, "no notes") }
for lang in AppLanguage.allCases {
    let t = StringTable.table(for: lang)
    let texts = [t.checkForUpdates, t.checkingForUpdates, t.updateAvailableTitle("9.9"), t.currentVersion("0.4.0"), t.download, t.later,
                 t.upToDateTitle, t.updateFailedTitle, t.updateNotConfigured, t.noReleases, t.updateBadResponse, t.httpError(503), t.badVersion("x")]
    check(!texts.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }, "\(lang.rawValue): empty update string")
    check(t.updateAvailableTitle("9.9").contains("9.9") && t.currentVersion("0.4.0").contains("0.4.0") && t.httpError(503).contains("503") && t.badVersion("qq").contains("qq"), "\(lang.rawValue): update placeholders")
}

print(failures == 0 ? "Self-test: all passed" : "Self-test: \(failures) failed")

// Connected displays, read-only
print("\nConnected displays (read-only):")
for (i, d) in Displays.active().enumerated() {
    let t = PrivateDisplay.modeTable(of: d)
    let cur = PrivateDisplay.currentModeNumber(of: d)
    let name = NSScreen.screens.first {
        ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == d
    }?.localizedName ?? L10n.displayFallbackName(i + 1)
    print("display \(d) uuid=\(Displays.uuid(of: d)) modes=\(t.count) current=#\(cur)")
    let live = CandidateRules.compute(table: t, currentNumber: cur)
    MenuText.render(name: name, candidates: live).forEach { print("  " + $0) }
    let liveMatches71 = t.count == modes.count && zip(t, modes).allSatisfy { $0.number == $1.number && $0.width == $1.width && $0.height == $1.height && $0.hz == $1.hz && $0.density == $1.density && $0.flags == $1.flags }
    print("  matches the reference table: \(liveMatches71)")
}
exit(failures == 0 ? 0 : 1)
