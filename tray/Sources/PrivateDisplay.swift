// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 33to9
import CoreGraphics
import ColorSync
import Foundation

/// Every private API call lives here. If a macOS update breaks something, check this file and CGSPrivate.h first.
enum PrivateDisplay {
    /// Reads the full display mode table.
    static func modeTable(of display: CGDirectDisplayID) -> [Mode] {
        var count: Int32 = 0
        CGSGetNumberOfDisplayModes(display, &count)
        guard count > 0 else { return [] }
        let length = Int32(MemoryLayout<CGSDisplayMode>.size)
        return (0..<count).map { index in
            var raw = CGSDisplayMode()
            CGSGetDisplayModeDescriptionOfLength(display, index, &raw, length)
            return Mode(number: Int32(bitPattern: raw.modeNumber), width: Int(raw.width), height: Int(raw.height),
                        hz: Int(raw.freq), density: Double(raw.density), flags: raw.flags, depth: Int(raw.depth))
        }
    }

    /// The current mode number.
    static func currentModeNumber(of display: CGDirectDisplayID) -> Int32 {
        var number: Int32 = -1
        CGSGetCurrentDisplayMode(display, &number)
        return number
    }

    /// Switches to a mode number inside a display configuration transaction.
    static func apply(_ modeNumber: Int32, on display: CGDirectDisplayID, option: CGConfigureOption) -> CGError {
        var config: CGDisplayConfigRef?
        var err = CGBeginDisplayConfiguration(&config)
        guard err == .success, let config else { return err == .success ? .failure : err }
        err = CGSConfigureDisplayMode(config, display, modeNumber)
        guard err == .success else {
            CGCancelDisplayConfiguration(config)
            return err
        }
        return CGCompleteDisplayConfiguration(config, option)
    }
}

/// Display helpers built on public APIs.
enum Displays {
    /// Active displays, main display first.
    static func active() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        ids = Array(ids.prefix(Int(count)))
        let main = CGMainDisplayID()
        if let i = ids.firstIndex(of: main), i != 0 {
            ids.remove(at: i)
            ids.insert(main, at: 0)
        }
        return ids
    }

    /// The display's UUID string.
    static func uuid(of display: CGDirectDisplayID) -> String {
        guard let unmanaged = CGDisplayCreateUUIDFromDisplayID(display) else { return "display-\(display)" }
        let uuid = unmanaged.takeRetainedValue()
        return (CFUUIDCreateString(nil, uuid) as String?) ?? "display-\(display)"
    }
}
