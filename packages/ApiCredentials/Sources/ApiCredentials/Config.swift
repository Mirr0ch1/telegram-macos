import Cocoa

public final class ApiEnvironment {
    public static var apiId:Int32 {
        return 9
    }
    public static var apiHash:String {
        return "3975f648bb682ee889f35483bc618d1c"
    }
    
    public static var bundleId: String {
        return "ru.keepcoder.Telegram"
    }
    public static var teamId: String {
        return "6N38VWS5BX"
    }
    
    
    
    public static var containerURL: URL? {
        // The app group container is only usable by a signature the group authorizes — an ad-hoc
        // signature (what a CI build can produce) is not. The URL may still be handed out, but the
        // directory is then not writable, and the account database has nowhere to go. So the
        // candidates are probed for write access and the first usable one wins.
        var candidates: [URL] = []
        if let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ApiEnvironment.group) {
            candidates.append(groupUrl.appendingPathComponent(prefix))
        }
        if let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            candidates.append(base.appendingPathComponent(bundleId + "/" + prefix))
        }
        if let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            candidates.append(base.appendingPathComponent(bundleId + "/" + prefix))
        }
        for candidate in candidates {
            if Self.isWritable(candidate) {
                NSLog("[Telegram] account container: %@", candidate.path)
                return candidate
            }
            NSLog("[Telegram] account container not usable: %@", candidate.path)
        }
        NSLog("[Telegram] no usable account container")
        return nil
    }

    /// Whether a directory can be created and written to.
    private static func isWritable(_ url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            let probe = url.appendingPathComponent(".write-probe")
            try Data("probe".utf8).write(to: probe)
            try? FileManager.default.removeItem(at: probe)
            return true
        } catch {
            NSLog("[Telegram] account container not writable: %@ (%@)", url.path, String(describing: error))
            return false
        }
    }
    
    public static func migrate() {
        if let containerURL = containerURL, let legacy = legacyContainerURL, let sequence = FileManager.default.enumerator(atPath: legacy.path) {
            let contents = try? FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil, options: [])
            if let contents = contents, !contents.isEmpty {
                return
            }
            for value in sequence {
                if let value = value as? String {
                    if !prefixList.contains(value) {
                        try? FileManager.default.moveItem(at: legacy.appendingPathComponent(value), to: containerURL.appendingPathComponent(value))
                    }
                }
            }
        }
    }
    
    public static var legacyContainerURL: URL? {
        let appGroupName = ApiEnvironment.group
        let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupName)
        return containerUrl
    }
    
    public static var group: String {
        return teamId + "." + bundleId
    }
    
    public static var appData: Data {
        let apiData = evaluateApiData() ?? ""
        let dict:[String: String] = ["bundleId": bundleId, "data": apiData]
        return try! JSONSerialization.data(withJSONObject: dict, options: [])
    }
    public static var language: String {
        return "macos"
    }
    
    public static var prefixList:[String] {
        return ["debug", "stable", "appstore", "beta"]
    }
    
    public static var prefix: String {
        var prefix: String = ""
        switch Configuration.value(for: .source) {
        case "DEBUG":
            prefix = "debug"
        case "STABLE":
            prefix = "stable"
        case "APP_STORE":
            prefix = "appstore"
        default:
            prefix = "beta"
        }
        return prefix
    }
    
    public static var version: String {
        var suffix: String = ""
        
        suffix = Configuration.value(for: .source) ?? "DEBUG"
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        return "\(shortVersion) \(suffix)"
    }
    
}



