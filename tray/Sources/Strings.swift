// SPDX-License-Identifier: GPL-3.0-only
// Copyright © 2026 Pivotfrag LLC
import Foundation

// MARK: - Languages

/// Supported UI languages. The raw value is the language code; the order is the Language submenu's order.
enum AppLanguage: String, CaseIterable {
    case en, zhHans = "zh-Hans", zhHant = "zh-Hant", ja, de, ko, fr, es

    /// The name shown in the Language submenu, always in the language's own script.
    var nativeName: String {
        switch self {
        case .en: return "English"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .ja: return "日本語"
        case .de: return "Deutsch"
        case .ko: return "한국어"
        case .fr: return "Français"
        case .es: return "Español"
        }
    }

    /// Maps a system language code (such as `zh-Hant-TW`, `en-GB`, `es-419`) to a supported language; nil if unsupported.
    static func from(systemCode code: String) -> AppLanguage? {
        let parts = code.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").map(String.init)
        guard let lang = parts.first else { return nil }
        if lang == "zh" {
            let rest = parts.dropFirst()
            if rest.contains("hans") { return .zhHans }
            if rest.contains("hant") { return .zhHant }
            if rest.contains(where: { ["tw", "hk", "mo"].contains($0) }) { return .zhHant }
            return .zhHans
        }
        return AppLanguage(rawValue: lang)
    }

    /// The first supported entry of the preferred languages, or English.
    static func resolve(preferred: [String]) -> AppLanguage {
        preferred.lazy.compactMap { from(systemCode: $0) }.first ?? .en
    }
}

/// The current language: the user's choice, else the system's. Computed on every read, never cached.
enum LanguageSetting {
    static let defaultsKey = "language"
    /// Forces a language; for the self-test only.
    static var forced: AppLanguage?

    /// The language chosen in the menu; nil means follow the system.
    static var choice: AppLanguage? {
        get { UserDefaults.standard.string(forKey: defaultsKey).flatMap(AppLanguage.init(rawValue:)) }
        set {
            if let newValue { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
            else { UserDefaults.standard.removeObject(forKey: defaultsKey) }
        }
    }

    static var current: AppLanguage {
        forced ?? choice ?? AppLanguage.resolve(preferred: Locale.preferredLanguages)
    }
}

// MARK: - String tables

/// All UI text for one language. Every string is a required property, so a missing one doesn't compile.
struct StringTable {
    /// Separator before the header's "Current" part and labels such as pixel-perfect
    let gap: String
    let displayFallbackName: (Int) -> String
    /// The "Current <size>" part of the header; the argument is the formatted size
    let current: (String) -> String
    let notHiDPI: String
    let pointToPoint: String
    let otherAspects: String
    let noDisplays: String
    let noHiDPIModes: String
    /// The Switch to Sharp item; the argument is the formatted size
    let sharpVersion: (String) -> String
    /// Its tooltip: the current size and the sharp version's rendered size
    let sharpVersionTip: (String, String) -> String
    let launchAtLogin: String
    let language: String
    let followSystem: String
    let quit: String
    let confirmTitle: String
    /// Rendered size
    let confirmRender: (String) -> String
    /// Seconds left, previous size
    let confirmBody: (Int, String) -> String
    let keep: String
    let revert: String
    let switchFailedTitle: String
    let switchFailedBody: (Int32) -> String
    let loginItemFailedTitle: String
    let loginItemFailedBody: (String) -> String
    let loginItemNeedsApproval: String
    let ok: String
    // Check for Updates
    let checkForUpdates: String
    let checkingForUpdates: String
    /// The new version
    let updateAvailableTitle: (String) -> String
    /// The installed version
    let currentVersion: (String) -> String
    let download: String
    let later: String
    let upToDateTitle: String
    let updateFailedTitle: String
    let updateNotConfigured: String
    let noReleases: String
    let updateBadResponse: String
    let httpError: (Int) -> String
    let badVersion: (String) -> String
}

extension StringTable {
    static func table(for language: AppLanguage) -> StringTable {
        switch language {
        case .en: return en
        case .zhHans: return zhHans
        case .zhHant: return zhHant
        case .ja: return ja
        case .de: return de
        case .ko: return ko
        case .fr: return fr
        case .es: return es
        }
    }

    static let en = StringTable(
        gap: "  ",
        displayFallbackName: { "Display \($0)" },
        current: { "Current \($0)" },
        notHiDPI: " (not HiDPI)",
        pointToPoint: "Pixel-perfect",
        otherAspects: "Other Aspect Ratios",
        noDisplays: "No Displays Detected",
        noHiDPIModes: "No HiDPI Modes Available",
        sharpVersion: { "Switch to Sharp \($0)" },
        sharpVersionTip: { "Currently rendered at \($0) pixels and stretched to the screen, so it looks blurry. The sharp version renders at \($1) pixels with the same desktop size. The same-named resolution in System Settings is the blurry one." },
        launchAtLogin: "Launch at Login",
        language: "Language",
        followSystem: "Follow System",
        quit: "Quit KeenQuad",
        confirmTitle: "Keep this resolution?",
        confirmRender: { "Rendered at \($0) pixels (HiDPI) for a sharp picture." },
        confirmBody: { "Reverting to \($1) in \($0) seconds." },
        keep: "Keep",
        revert: "Revert",
        switchFailedTitle: "Couldn’t Change Resolution",
        switchFailedBody: { "CGError \($0). The display was left unchanged." },
        loginItemFailedTitle: "Couldn’t Change “Launch at Login”",
        loginItemFailedBody: { "\($0)\n\nYou can add KeenQuad manually in System Settings › General › Login Items." },
        loginItemNeedsApproval: "Allow KeenQuad in System Settings › General › Login Items, or add it there manually.",
        ok: "OK",
        checkForUpdates: "Check for Updates…",
        checkingForUpdates: "Checking for Updates…",
        updateAvailableTitle: { "KeenQuad \($0) Is Available" },
        currentVersion: { "You have \($0)." },
        download: "Download",
        later: "Later",
        upToDateTitle: "KeenQuad Is Up to Date",
        updateFailedTitle: "Couldn’t Check for Updates",
        updateNotConfigured: "No update address is configured.",
        noReleases: "No versions have been released yet.",
        updateBadResponse: "The server’s response couldn’t be read.",
        httpError: { "The server returned HTTP \($0)." },
        badVersion: { "Unrecognized version “\($0)”." })

    static let zhHans = StringTable(
        gap: "\u{3000}",
        displayFallbackName: { "显示器 \($0)" },
        current: { "当前 \($0)" },
        notHiDPI: "（非 HiDPI）",
        pointToPoint: "点对点",
        otherAspects: "其他比例",
        noDisplays: "未检测到显示器",
        noHiDPIModes: "没有可用的 HiDPI 档位",
        sharpVersion: { "切换到清晰版 \($0)" },
        sharpVersionTip: { "当前按 \($0) 像素渲染，再拉伸到屏幕上，所以发虚。清晰版按 \($1) 像素渲染，桌面大小不变。“系统设置”里同名的分辨率是前一种。" },
        launchAtLogin: "登录时启动",
        language: "语言",
        followSystem: "跟随系统",
        quit: "退出 KeenQuad",
        confirmTitle: "保留这个分辨率吗？",
        confirmRender: { "按 \($0) 像素渲染（HiDPI），画面清晰。" },
        confirmBody: { "\($0) 秒后自动还原为 \($1)。" },
        keep: "保留",
        revert: "还原",
        switchFailedTitle: "切换分辨率失败",
        switchFailedBody: { "CGError \($0)，显示状态保持不变。" },
        loginItemFailedTitle: "无法更改“登录时启动”",
        loginItemFailedBody: { "\($0)\n\n可以在“系统设置 › 通用 › 登录项”里手动添加 KeenQuad。" },
        loginItemNeedsApproval: "需要在“系统设置 › 通用 › 登录项”里允许 KeenQuad，也可以在那里手动添加。",
        ok: "好",
        checkForUpdates: "检查更新…",
        checkingForUpdates: "正在检查更新…",
        updateAvailableTitle: { "有新版本 KeenQuad \($0)" },
        currentVersion: { "当前版本 \($0)。" },
        download: "前往下载",
        later: "以后再说",
        upToDateTitle: "KeenQuad 已是最新版本",
        updateFailedTitle: "无法检查更新",
        updateNotConfigured: "未配置更新地址。",
        noReleases: "还没有发布任何版本。",
        updateBadResponse: "无法识别服务器返回的内容。",
        httpError: { "服务器返回 HTTP \($0)。" },
        badVersion: { "无法识别版本号“\($0)”。" })

    static let zhHant = StringTable(
        gap: "\u{3000}",
        displayFallbackName: { "顯示器 \($0)" },
        current: { "目前 \($0)" },
        notHiDPI: "（非 HiDPI）",
        pointToPoint: "點對點",
        otherAspects: "其他比例",
        noDisplays: "未偵測到顯示器",
        noHiDPIModes: "沒有可用的 HiDPI 檔位",
        sharpVersion: { "切換到清晰版 \($0)" },
        sharpVersionTip: { "目前以 \($0) 像素渲染，再拉伸到螢幕上，所以會模糊。清晰版以 \($1) 像素渲染，桌面大小不變。「系統設定」裡同名的解析度是前一種。" },
        launchAtLogin: "登入時啟動",
        language: "語言",
        followSystem: "跟隨系統",
        quit: "結束 KeenQuad",
        confirmTitle: "要保留這個解析度嗎？",
        confirmRender: { "以 \($0) 像素渲染（HiDPI），畫面清晰。" },
        confirmBody: { "\($0) 秒後自動還原為 \($1)。" },
        keep: "保留",
        revert: "還原",
        switchFailedTitle: "無法切換解析度",
        switchFailedBody: { "CGError \($0)，顯示狀態維持不變。" },
        loginItemFailedTitle: "無法更改「登入時啟動」",
        loginItemFailedBody: { "\($0)\n\n可以在「系統設定 › 一般 › 登入項目」裡手動加入 KeenQuad。" },
        loginItemNeedsApproval: "需要在「系統設定 › 一般 › 登入項目」裡允許 KeenQuad，也可以在那裡手動加入。",
        ok: "好",
        checkForUpdates: "檢查更新…",
        checkingForUpdates: "正在檢查更新…",
        updateAvailableTitle: { "有新版本 KeenQuad \($0)" },
        currentVersion: { "目前版本 \($0)。" },
        download: "前往下載",
        later: "以後再說",
        upToDateTitle: "KeenQuad 已是最新版本",
        updateFailedTitle: "無法檢查更新",
        updateNotConfigured: "未設定更新位址。",
        noReleases: "尚未發佈任何版本。",
        updateBadResponse: "無法辨識伺服器回傳的內容。",
        httpError: { "伺服器回傳 HTTP \($0)。" },
        badVersion: { "無法辨識版本號「\($0)」。" })

    static let ja = StringTable(
        gap: "\u{3000}",
        displayFallbackName: { "ディスプレイ \($0)" },
        current: { "現在 \($0)" },
        notHiDPI: "（HiDPI ではありません）",
        pointToPoint: "ドットバイドット",
        otherAspects: "その他の縦横比",
        noDisplays: "ディスプレイが見つかりません",
        noHiDPIModes: "利用できる HiDPI 解像度がありません",
        sharpVersion: { "高精細版 \($0) に切り替え" },
        sharpVersionTip: { "現在は \($0) ピクセルで描画して画面に引き伸ばしているため、ぼやけて見えます。高精細版は \($1) ピクセルで描画し、デスクトップの広さは変わりません。「システム設定」にある同じ名前の解像度は前者です。" },
        launchAtLogin: "ログイン時に起動",
        language: "言語",
        followSystem: "システムに従う",
        quit: "KeenQuad を終了",
        confirmTitle: "この解像度のままにしますか？",
        confirmRender: { "\($0) ピクセルで描画（HiDPI）、くっきり表示されます。" },
        confirmBody: { "\($0) 秒後に \($1) に戻ります。" },
        keep: "このままにする",
        revert: "元に戻す",
        switchFailedTitle: "解像度を変更できませんでした",
        switchFailedBody: { "CGError \($0)。表示は変更されていません。" },
        loginItemFailedTitle: "「ログイン時に起動」を変更できません",
        loginItemFailedBody: { "\($0)\n\n「システム設定 › 一般 › ログイン項目」で KeenQuad を手動で追加できます。" },
        loginItemNeedsApproval: "「システム設定 › 一般 › ログイン項目」で KeenQuad を許可するか、そこで手動で追加してください。",
        ok: "OK",
        checkForUpdates: "アップデートを確認…",
        checkingForUpdates: "アップデートを確認中…",
        updateAvailableTitle: { "KeenQuad \($0) が利用可能です" },
        currentVersion: { "現在のバージョンは \($0) です。" },
        download: "ダウンロード",
        later: "あとで",
        upToDateTitle: "KeenQuad は最新です",
        updateFailedTitle: "アップデートを確認できませんでした",
        updateNotConfigured: "アップデートの確認先が設定されていません。",
        noReleases: "まだリリースされたバージョンがありません。",
        updateBadResponse: "サーバの応答を読み取れませんでした。",
        httpError: { "サーバが HTTP \($0) を返しました。" },
        badVersion: { "バージョン「\($0)」を認識できません。" })

    static let de = StringTable(
        gap: "  ",
        displayFallbackName: { "Monitor \($0)" },
        current: { "Aktuell \($0)" },
        notHiDPI: " (kein HiDPI)",
        pointToPoint: "Pixelgenau",
        otherAspects: "Andere Seitenverhältnisse",
        noDisplays: "Kein Monitor erkannt",
        noHiDPIModes: "Keine HiDPI-Auflösungen verfügbar",
        sharpVersion: { "Zur scharfen Version \($0) wechseln" },
        sharpVersionTip: { "Derzeit wird mit \($0) Pixeln gerendert und auf den Bildschirm gestreckt, daher wirkt das Bild unscharf. Die scharfe Version rendert mit \($1) Pixeln bei gleicher Arbeitsfläche. Die gleichnamige Auflösung in den Systemeinstellungen ist die unscharfe." },
        launchAtLogin: "Beim Anmelden starten",
        language: "Sprache",
        followSystem: "Wie System",
        quit: "KeenQuad beenden",
        confirmTitle: "Diese Auflösung beibehalten?",
        confirmRender: { "Gerendert mit \($0) Pixeln (HiDPI) für ein scharfes Bild." },
        confirmBody: { "Zurück zu \($1) in \($0) Sekunden." },
        keep: "Beibehalten",
        revert: "Zurücksetzen",
        switchFailedTitle: "Auflösung konnte nicht geändert werden",
        switchFailedBody: { "CGError \($0). Die Anzeige bleibt unverändert." },
        loginItemFailedTitle: "„Beim Anmelden starten“ kann nicht geändert werden",
        loginItemFailedBody: { "\($0)\n\nDu kannst KeenQuad unter „Systemeinstellungen › Allgemein › Anmeldeobjekte“ manuell hinzufügen." },
        loginItemNeedsApproval: "Erlaube KeenQuad unter „Systemeinstellungen › Allgemein › Anmeldeobjekte“ oder füge es dort manuell hinzu.",
        ok: "OK",
        checkForUpdates: "Nach Updates suchen …",
        checkingForUpdates: "Suche nach Updates …",
        updateAvailableTitle: { "KeenQuad \($0) ist verfügbar" },
        currentVersion: { "Installiert ist \($0)." },
        download: "Laden",
        later: "Später",
        upToDateTitle: "KeenQuad ist aktuell",
        updateFailedTitle: "Suche nach Updates fehlgeschlagen",
        updateNotConfigured: "Es ist keine Update-Adresse eingerichtet.",
        noReleases: "Es wurde noch keine Version veröffentlicht.",
        updateBadResponse: "Die Antwort des Servers konnte nicht gelesen werden.",
        httpError: { "Der Server hat HTTP \($0) zurückgegeben." },
        badVersion: { "Unbekannte Version „\($0)“." })

    static let ko = StringTable(
        gap: "  ",
        displayFallbackName: { "디스플레이 \($0)" },
        current: { "현재 \($0)" },
        notHiDPI: " (HiDPI 아님)",
        pointToPoint: "픽셀 일치",
        otherAspects: "기타 화면비",
        noDisplays: "디스플레이를 찾을 수 없음",
        noHiDPIModes: "사용 가능한 HiDPI 해상도 없음",
        sharpVersion: { "선명한 버전 \($0)(으)로 전환" },
        sharpVersionTip: { "현재 \($0) 픽셀로 렌더링한 뒤 화면에 맞춰 늘리기 때문에 흐릿하게 보입니다. 선명한 버전은 \($1) 픽셀로 렌더링하며 데스크탑 크기는 같습니다. ‘시스템 설정’에 있는 같은 이름의 해상도는 흐릿한 쪽입니다." },
        launchAtLogin: "로그인 시 실행",
        language: "언어",
        followSystem: "시스템 설정 따르기",
        quit: "KeenQuad 종료",
        confirmTitle: "이 해상도를 유지하겠습니까?",
        confirmRender: { "\($0) 픽셀(HiDPI)로 렌더링되어 선명합니다." },
        confirmBody: { "\($0)초 후 \($1)(으)로 되돌립니다." },
        keep: "유지",
        revert: "되돌리기",
        switchFailedTitle: "해상도를 변경할 수 없음",
        switchFailedBody: { "CGError \($0). 디스플레이는 변경되지 않았습니다." },
        loginItemFailedTitle: "‘로그인 시 실행’을 변경할 수 없음",
        loginItemFailedBody: { "\($0)\n\n‘시스템 설정 › 일반 › 로그인 항목’에서 KeenQuad를 직접 추가할 수 있습니다." },
        loginItemNeedsApproval: "‘시스템 설정 › 일반 › 로그인 항목’에서 KeenQuad를 허용하거나 직접 추가하십시오.",
        ok: "확인",
        checkForUpdates: "업데이트 확인…",
        checkingForUpdates: "업데이트 확인 중…",
        updateAvailableTitle: { "KeenQuad \($0) 사용 가능" },
        currentVersion: { "현재 버전은 \($0)입니다." },
        download: "다운로드",
        later: "나중에",
        upToDateTitle: "KeenQuad가 최신 버전입니다",
        updateFailedTitle: "업데이트를 확인할 수 없음",
        updateNotConfigured: "업데이트 주소가 설정되지 않았습니다.",
        noReleases: "아직 출시된 버전이 없습니다.",
        updateBadResponse: "서버 응답을 읽을 수 없습니다.",
        httpError: { "서버가 HTTP \($0)을(를) 반환했습니다." },
        badVersion: { "인식할 수 없는 버전 ‘\($0)’." })

    static let fr = StringTable(
        gap: "  ",
        displayFallbackName: { "Moniteur \($0)" },
        current: { "Actuel \($0)" },
        notHiDPI: " (non HiDPI)",
        pointToPoint: "Pixel pour pixel",
        otherAspects: "Autres formats",
        noDisplays: "Aucun moniteur détecté",
        noHiDPIModes: "Aucune définition HiDPI disponible",
        sharpVersion: { "Passer à la version nette \($0)" },
        sharpVersionTip: { "Rendu actuel à \($0) pixels, étiré à l’écran, d’où le flou. La version nette est rendue à \($1) pixels, avec la même taille de bureau. La définition du même nom dans Réglages Système est la version floue." },
        launchAtLogin: "Ouvrir à la connexion",
        language: "Langue",
        followSystem: "Selon le système",
        quit: "Quitter KeenQuad",
        confirmTitle: "Conserver cette définition ?",
        confirmRender: { "Rendu à \($0) pixels (HiDPI) pour une image nette." },
        confirmBody: { "Retour à \($1) dans \($0) secondes." },
        keep: "Conserver",
        revert: "Rétablir",
        switchFailedTitle: "Impossible de changer la définition",
        switchFailedBody: { "CGError \($0). L’affichage n’a pas été modifié." },
        loginItemFailedTitle: "Impossible de modifier « Ouvrir à la connexion »",
        loginItemFailedBody: { "\($0)\n\nVous pouvez ajouter KeenQuad manuellement dans Réglages Système › Général › Ouverture." },
        loginItemNeedsApproval: "Autorisez KeenQuad dans Réglages Système › Général › Ouverture, ou ajoutez-le manuellement.",
        ok: "OK",
        checkForUpdates: "Rechercher les mises à jour…",
        checkingForUpdates: "Recherche de mises à jour…",
        updateAvailableTitle: { "KeenQuad \($0) est disponible" },
        currentVersion: { "Vous avez la version \($0)." },
        download: "Télécharger",
        later: "Plus tard",
        upToDateTitle: "KeenQuad est à jour",
        updateFailedTitle: "Impossible de rechercher les mises à jour",
        updateNotConfigured: "Aucune adresse de mise à jour n’est configurée.",
        noReleases: "Aucune version n’a encore été publiée.",
        updateBadResponse: "La réponse du serveur est illisible.",
        httpError: { "Le serveur a renvoyé HTTP \($0)." },
        badVersion: { "Version « \($0) » non reconnue." })

    static let es = StringTable(
        gap: "  ",
        displayFallbackName: { "Pantalla \($0)" },
        current: { "Actual \($0)" },
        notHiDPI: " (no HiDPI)",
        pointToPoint: "Píxel a píxel",
        otherAspects: "Otras proporciones",
        noDisplays: "No se detectan pantallas",
        noHiDPIModes: "No hay resoluciones HiDPI disponibles",
        sharpVersion: { "Cambiar a la versión nítida \($0)" },
        sharpVersionTip: { "Ahora se renderiza a \($0) píxeles y se estira a la pantalla, por eso se ve borroso. La versión nítida se renderiza a \($1) píxeles con el mismo tamaño de escritorio. La resolución del mismo nombre en Ajustes del Sistema es la borrosa." },
        launchAtLogin: "Abrir al iniciar sesión",
        language: "Idioma",
        followSystem: "Según el sistema",
        quit: "Salir de KeenQuad",
        confirmTitle: "¿Mantener esta resolución?",
        confirmRender: { "Renderizado a \($0) píxeles (HiDPI) para una imagen nítida." },
        confirmBody: { "Se restaurará \($1) en \($0) segundos." },
        keep: "Mantener",
        revert: "Restaurar",
        switchFailedTitle: "No se pudo cambiar la resolución",
        switchFailedBody: { "CGError \($0). La pantalla no ha cambiado." },
        loginItemFailedTitle: "No se puede cambiar “Abrir al iniciar sesión”",
        loginItemFailedBody: { "\($0)\n\nPuedes añadir KeenQuad manualmente en Ajustes del Sistema › General › Ítems de inicio." },
        loginItemNeedsApproval: "Permite KeenQuad en Ajustes del Sistema › General › Ítems de inicio, o añádelo allí manualmente.",
        ok: "OK",
        checkForUpdates: "Buscar actualizaciones…",
        checkingForUpdates: "Buscando actualizaciones…",
        updateAvailableTitle: { "KeenQuad \($0) está disponible" },
        currentVersion: { "Tienes la versión \($0)." },
        download: "Descargar",
        later: "Más tarde",
        upToDateTitle: "KeenQuad está actualizado",
        updateFailedTitle: "No se pudieron buscar actualizaciones",
        updateNotConfigured: "No hay una dirección de actualización configurada.",
        noReleases: "Aún no se ha publicado ninguna versión.",
        updateBadResponse: "No se pudo leer la respuesta del servidor.",
        httpError: { "El servidor devolvió HTTP \($0)." },
        badVersion: { "Versión “\($0)” no reconocida." })
}

// MARK: - Accessors (look up the current language's table)

enum L10n {
    private static var t: StringTable { StringTable.table(for: LanguageSetting.current) }

    static var gap: String { t.gap }
    static func displayFallbackName(_ ordinal: Int) -> String { t.displayFallbackName(ordinal) }
    static func size(_ w: Int, _ h: Int) -> String { "\(w) × \(h)" }
    static func header(name: String, w: Int, h: Int, hiDPI: Bool) -> String {
        name + t.gap + t.current(size(w, h)) + (hiDPI ? "" : t.notHiDPI)
    }
    static var pointToPoint: String { t.pointToPoint }
    static func refreshRate(_ hz: Int) -> String { "\(hz)Hz" }
    static var otherAspects: String { t.otherAspects }
    static var noDisplays: String { t.noDisplays }
    static var noHiDPIModes: String { t.noHiDPIModes }

    // Switch to Sharp
    static func sharpVersion(_ w: Int, _ h: Int) -> String { t.sharpVersion(size(w, h)) }
    static func sharpVersionTip(_ w: Int, _ h: Int) -> String { t.sharpVersionTip(size(w, h), size(w * 2, h * 2)) }

    static var launchAtLogin: String { t.launchAtLogin }
    static var language: String { t.language }
    static var followSystem: String { t.followSystem }
    static func version(_ v: String) -> String { "KeenQuad \(v)" }
    static var quit: String { t.quit }

    // Confirmation panel
    static var confirmTitle: String { t.confirmTitle }
    static func confirmRender(w: Int, h: Int) -> String { t.confirmRender(size(w, h)) }
    static func confirmBody(seconds: Int, w: Int, h: Int) -> String { t.confirmBody(seconds, size(w, h)) }
    static var keep: String { t.keep }
    static var revert: String { t.revert }

    // Errors
    static var switchFailedTitle: String { t.switchFailedTitle }
    static func switchFailedBody(_ code: Int32) -> String { t.switchFailedBody(code) }
    static var loginItemFailedTitle: String { t.loginItemFailedTitle }
    static func loginItemFailedBody(_ error: String) -> String { t.loginItemFailedBody(error) }
    static var loginItemNeedsApproval: String { t.loginItemNeedsApproval }
    static var ok: String { t.ok }

    // Check for Updates
    static var checkForUpdates: String { t.checkForUpdates }
    static var checkingForUpdates: String { t.checkingForUpdates }
    static func updateAvailableTitle(_ v: String) -> String { t.updateAvailableTitle(v) }
    static func currentVersion(_ v: String) -> String { t.currentVersion(v) }
    static var download: String { t.download }
    static var later: String { t.later }
    static var upToDateTitle: String { t.upToDateTitle }
    static var updateFailedTitle: String { t.updateFailedTitle }
    static func updateFailure(_ f: UpdateLogic.Failure) -> String {
        switch f {
        case .notConfigured: return t.updateNotConfigured
        case .network(let message): return message
        case .http(let code): return t.httpError(code)
        case .noReleases: return t.noReleases
        case .badResponse: return t.updateBadResponse
        case .badVersion(let tag): return t.badVersion(tag)
        }
    }
}
