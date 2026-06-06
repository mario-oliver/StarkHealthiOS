import Foundation

enum ShareCode {
    static func normalize(_ input: String) -> String {
        input.uppercased().replacingOccurrences(of: "[\\s-]", with: "", options: .regularExpression)
    }

    static func format(_ code: String) -> String {
        let normalized = normalize(code)
        guard normalized.count > 4 else { return normalized }
        let prefix = normalized.prefix(4)
        let suffix = normalized.dropFirst(4)
        return "\(prefix)-\(suffix)"
    }
}
