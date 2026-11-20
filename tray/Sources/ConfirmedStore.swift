import Foundation

/// 已确认模式签名的持久化（F7.1 / 6.5）。只使用一个键 `confirmedModes`。
enum ConfirmedStore {
    private static let key = "confirmedModes"
    private static var defaults: UserDefaults { .standard }

    static func contains(_ signature: String, uuid: String) -> Bool {
        all()[uuid]?.contains(signature) ?? false
    }

    static func add(_ signature: String, uuid: String) {
        var map = all()
        var list = map[uuid] ?? []
        guard !list.contains(signature) else { return }
        list.append(signature)
        map[uuid] = list
        defaults.set(map, forKey: key)
    }

    private static func all() -> [String: [String]] {
        defaults.dictionary(forKey: key) as? [String: [String]] ?? [:]
    }
}
