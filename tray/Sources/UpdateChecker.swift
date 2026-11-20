import Foundation

/// 检查更新的纯逻辑（F14 / v0.4 第 3 节），与网络和界面无关，便于自测。
enum UpdateLogic {
    enum Failure: Equatable {
        case notConfigured
        case network(String)
        case http(Int)
        case noReleases
        case badResponse
        case badVersion(String)
    }

    enum Outcome: Equatable {
        case newer(version: String, url: URL, notes: String)
        case upToDate
        case failed(Failure)
    }

    static let notesLimit = 600

    /// `v0.4.0` → [0, 4, 0]；有非数字段时为 nil。
    static func parse(_ text: String) -> [Int]? {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("v") || t.hasPrefix("V") { t.removeFirst() }
        let parts = t.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var result: [Int] = []
        for p in parts {
            guard !p.isEmpty, p.allSatisfy({ $0.isASCII && $0.isNumber }), let n = Int(p) else { return nil }
            result.append(n)
        }
        return result
    }

    /// 逐段比较，缺的段按 0 计。
    static func isNewer(_ a: [Int], than b: [Int]) -> Bool {
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    /// `owner/repo` 形式才有效。
    static func isValidRepository(_ s: String?) -> Bool {
        guard let s else { return false }
        return s.range(of: #"^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$"#, options: .regularExpression) != nil
    }

    static func truncate(_ s: String) -> String {
        let t = s.replacingOccurrences(of: "\r\n", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return t.count > notesLimit ? String(t.prefix(notesLimit)) + "…" : t
    }

    private struct Release: Decodable {
        let tag_name: String
        let html_url: String
        let body: String?
    }

    /// 根据一次请求的结果得出结论。
    static func evaluate(data: Data?, status: Int?, errorDescription: String?, current: String) -> Outcome {
        if let errorDescription { return .failed(.network(errorDescription)) }
        guard let status else { return .failed(.badResponse) }
        if status == 404 { return .failed(.noReleases) }
        guard status == 200 else { return .failed(.http(status)) }
        guard let data, let release = try? JSONDecoder().decode(Release.self, from: data),
              let url = URL(string: release.html_url), url.scheme == "https" else { return .failed(.badResponse) }
        guard let latest = parse(release.tag_name) else { return .failed(.badVersion(release.tag_name)) }
        guard let mine = parse(current) else { return .failed(.badVersion(current)) }
        guard isNewer(latest, than: mine) else { return .upToDate }
        var version = release.tag_name.trimmingCharacters(in: .whitespacesAndNewlines)
        if version.hasPrefix("v") || version.hasPrefix("V") { version.removeFirst() }
        return .newer(version: version, url: url, notes: truncate(release.body ?? ""))
    }
}

/// 一次手动检查（F14.2）：后台请求，结果回到主线程。不保存任何结果（F14.7）。
final class UpdateChecker {
    private(set) var isChecking = false

    static var bundleRepository: String? {
        Bundle.main.object(forInfoDictionaryKey: "KQUpdateRepository") as? String
    }
    static var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    func check(repository: String? = UpdateChecker.bundleRepository,
               current: String = UpdateChecker.bundleVersion,
               completion: @escaping (UpdateLogic.Outcome) -> Void) {
        guard !isChecking else { return }
        guard UpdateLogic.isValidRepository(repository), let repository,
              let url = URL(string: "https://api.github.com/repos/\(repository)/releases/latest") else {
            completion(.failed(.notConfigured))
            return
        }
        isChecking = true
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("KeenQuad/\(current)", forHTTPHeaderField: "User-Agent")   // N3：不带用户信息
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) { [weak self] data, response, error in
            let outcome = UpdateLogic.evaluate(data: data,
                                               status: (response as? HTTPURLResponse)?.statusCode,
                                               errorDescription: error?.localizedDescription,
                                               current: current)
            session.finishTasksAndInvalidate()
            DispatchQueue.main.async {
                self?.isChecking = false
                completion(outcome)
            }
        }.resume()
    }
}
