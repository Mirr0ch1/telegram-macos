import Foundation

/// Translations that ship with the build for strings the downloaded translation packs don't have.
///
/// The app's non-English UI comes from the localization packs it downloads from Telegram's servers.
/// A string that was just added upstream is missing from those packs until the translation
/// platform picks it up, and until then the app falls back to the bundled English. These overrides
/// fill that gap for the languages this build ships.
public enum BundledTranslations {
    private static let overrides: [String: [String: String]] = [
        "zh-hans": [
            "GeneralSettings.OpenRichEditorOnPaste": "粘贴时打开富文本编辑器"
        ],
        "zh-hant": [
            "GeneralSettings.OpenRichEditorOnPaste": "貼上時開啟富文字編輯器"
        ]
    ]

    /// The bundled translations for a language, empty when there are none.
    ///
    /// The language code is matched leniently: the packs name Chinese in a few ways
    /// (`zh-Hans`, `zh-CN`, `zh`), and they all mean the same thing here.
    public static func strings(for languageCode: String) -> [String: String] {
        let code = languageCode.lowercased()
        if let direct = overrides[code] {
            return direct
        }
        if code.hasPrefix("zh") {
            // Anything else Chinese: Simplified unless it is one of the traditional variants.
            let traditional = code.contains("hant") || code.contains("tw") || code.contains("hk")
            return overrides[traditional ? "zh-hant" : "zh-hans"] ?? [:]
        }
        return [:]
    }
}
