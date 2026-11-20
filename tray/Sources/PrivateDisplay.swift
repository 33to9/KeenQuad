import CoreGraphics
import ColorSync
import Foundation

/// 私有接口的全部调用都在这里（N5）。系统升级后出问题时先查这个文件和 CGSPrivate.h。
enum PrivateDisplay {
    /// F2.4：读取完整模式表。
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

    /// F2.4：当前模式号。
    static func currentModeNumber(of display: CGDirectDisplayID) -> Int32 {
        var number: Int32 = -1
        CGSGetCurrentDisplayMode(display, &number)
        return number
    }

    /// F5.2 / 6.2：在显示配置事务中按模式号切换。
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

/// 公开的显示器辅助函数。
enum Displays {
    /// F2.2：活动显示器，主显示器在前。
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

    /// F7.1：显示器 UUID 字符串。
    static func uuid(of display: CGDirectDisplayID) -> String {
        guard let unmanaged = CGDisplayCreateUUIDFromDisplayID(display) else { return "display-\(display)" }
        let uuid = unmanaged.takeRetainedValue()
        return (CFUUIDCreateString(nil, uuid) as String?) ?? "display-\(display)"
    }
}
