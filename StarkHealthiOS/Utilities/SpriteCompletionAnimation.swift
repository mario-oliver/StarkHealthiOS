import Foundation

enum SpriteCompletionAnimation {
    private static let options: [SpriteAnimation] = [.sitA, .sitB, .playbow]

    static func pick(seed: String) -> SpriteAnimation {
        let hash = seed.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % options.count }
        return options[hash]
    }
}
