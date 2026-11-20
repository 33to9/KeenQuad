// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC
import Foundation

/// One entry of the display mode table. Pure data with no system calls, so it can be tested on its own.
struct Mode: Equatable {
    let number: Int32
    let width: Int
    let height: Int
    let hz: Int
    let density: Double
    let flags: UInt32
    let depth: Int

    static let flagNative: UInt32 = 0x0200_0000
    static let flagNotForDesktop: UInt32 = 0x4000_0000

    var isNative: Bool { flags & Mode.flagNative != 0 }
    var isHiDPI: Bool { density == 2.0 }
    var aspect: Double { height == 0 ? 0 : Double(width) / Double(height) }

    /// Mode signature `WIDTHxHEIGHT@DENSITYx@HZ`, for example `1600x1000@2x@60`.
    var signature: String {
        let d = density.rounded() == density ? String(Int(density)) : String(format: "%.2g", density)
        return "\(width)x\(height)@\(d)x@\(hz)"
    }
}

/// A candidate mode and how it's shown in the menu.
struct Candidate: Equatable {
    let mode: Mode
    let isCurrent: Bool
    let isPointToPoint: Bool
    /// Refresh rate to append when it differs from the current one; nil when it's the same.
    let extraHz: Int?
}

struct DisplayCandidates: Equatable {
    let current: Mode?
    let main: [Candidate]
    let others: [Candidate]
    /// When the current mode is a blurry 1x one, the HiDPI candidate of the same size; otherwise nil.
    let sharpVersion: Candidate?
}

enum CandidateRules {
    /// All candidate rules: HiDPI and usable for the desktop, one per size, split by the panel's aspect ratio.
    static func compute(table: [Mode], currentNumber: Int32) -> DisplayCandidates {
        let current = table.first { $0.number == currentNumber }

        // F3.1
        let hidpi = table.filter { $0.density == 2.0 && $0.flags & Mode.flagNotForDesktop == 0 }

        // F3.2
        let curHz = current?.hz
        var groups: [String: [Mode]] = [:]
        var order: [String] = []
        for m in hidpi {
            let key = "\(m.width)x\(m.height)"
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(m)
        }
        let picked: [Mode] = order.compactMap { key in
            guard let group = groups[key], let bestDepth = group.map(\.depth).max() else { return nil }
            let deep = group.filter { $0.depth == bestDepth }
            if let hz = curHz, let same = deep.first(where: { $0.hz == hz }) { return same }
            return deep.max { $0.hz < $1.hz }
        }.sorted { ($0.width, $0.height) < ($1.width, $1.height) }

        // F3.3
        let panel = table.first { $0.isNative && $0.density == 1.0 }
            ?? table.first { $0.isNative }
            ?? current
        let panelAspect = panel?.aspect

        func candidate(_ m: Mode) -> Candidate {
            Candidate(mode: m,
                      isCurrent: m.number == currentNumber,
                      isPointToPoint: m.isNative,
                      extraHz: (curHz != nil && m.hz != curHz) ? m.hz : nil)
        }

        // F3.4
        var main: [Candidate] = []
        var others: [Candidate] = []
        for m in picked {
            if let pa = panelAspect, abs(m.aspect - pa) <= 0.01 {
                main.append(candidate(m))
            } else if panelAspect == nil {
                main.append(candidate(m))
            } else {
                others.append(candidate(m))
            }
        }
        // The current mode is 1x, not the panel's native mode, and a candidate has the same size
        var sharp: Candidate?
        if let cur = current, cur.density == 1.0, !cur.isNative {
            sharp = (main + others).first { $0.mode.width == cur.width && $0.mode.height == cur.height }
        }
        return DisplayCandidates(current: current, main: main, others: others, sharpVersion: sharp)
    }

    /// Finds a mode by signature among this enumeration's candidates.
    static func find(signature: String, in c: DisplayCandidates) -> Mode? {
        (c.main + c.others).first { $0.mode.signature == signature }?.mode
    }

    /// Locates the previous mode for a revert: same number and signature first, else a desktop-usable mode with that signature.
    static func locate(signature: String, preferredNumber: Int32, in table: [Mode]) -> Mode? {
        table.first { $0.number == preferredNumber && $0.signature == signature }
            ?? table.first { $0.signature == signature && $0.flags & Mode.flagNotForDesktop == 0 }
            ?? table.first { $0.signature == signature }
    }
}

/// The menu's text model, independent of AppKit so it can be tested.
enum MenuText {
    static func itemTitle(_ c: Candidate) -> (main: String, tag: String?) {
        var main = L10n.size(c.mode.width, c.mode.height)
        if let hz = c.extraHz { main += L10n.gap + L10n.refreshRate(hz) }
        return (main, c.isPointToPoint ? L10n.pointToPoint : nil)
    }

    static func header(name: String, current: Mode?, fallbackSize: (Int, Int)) -> String {
        if let cur = current {
            return L10n.header(name: name, w: cur.width, h: cur.height, hiDPI: cur.isHiDPI)
        }
        return L10n.header(name: name, w: fallbackSize.0, h: fallbackSize.1, hiDPI: false)
    }

    /// A display's menu section as plain text, for the self-test.
    static func render(name: String, candidates: DisplayCandidates, fallbackSize: (Int, Int) = (0, 0)) -> [String] {
        var lines = [header(name: name, current: candidates.current, fallbackSize: fallbackSize)]
        func line(_ c: Candidate, indent: String) -> String {
            let t = itemTitle(c)
            return indent + (c.isCurrent ? "✓ " : "  ") + t.main + (t.tag.map { L10n.gap + $0 } ?? "")
        }
        if candidates.main.isEmpty && candidates.others.isEmpty {
            lines.append("  " + L10n.noHiDPIModes)
            return lines
        }
        if let s = candidates.sharpVersion {   // F12.2
            lines.append("  " + L10n.sharpVersion(s.mode.width, s.mode.height))
        }
        for c in candidates.main { lines.append(line(c, indent: "")) }
        if !candidates.others.isEmpty {
            lines.append("  " + L10n.otherAspects + " ▸")
            for c in candidates.others { lines.append(line(c, indent: "      ")) }
        }
        return lines
    }
}
