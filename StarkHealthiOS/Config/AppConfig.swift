import Foundation

enum AppConfig {
    static var clerkPublishableKey: String {
        string(for: "CLERK_PUBLISHABLE_KEY")
    }

    static var apiBaseURL: URL {
        let raw = string(for: "API_BASE_URL")
        guard let url = URL(string: raw) else {
            fatalError("Invalid API_BASE_URL: \(raw)")
        }
        return url
    }

    static var appleProductPro: String {
        optionalString(for: "APPLE_PRODUCT_PRO") ?? ""
    }

    static var appleProductBasic: String {
        optionalString(for: "APPLE_PRODUCT_BASIC") ?? ""
    }

    private static func optionalString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.contains("$(") else {
            return nil
        }
        return value
    }

    private static func string(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.contains("$(") else {
            fatalError("Missing or unresolved Info.plist value for \(key)")
        }
        return value
    }
}
