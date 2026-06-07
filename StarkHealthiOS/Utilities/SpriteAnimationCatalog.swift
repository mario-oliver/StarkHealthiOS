import Foundation

struct SpriteAnimationDefinition: Sendable {
    let frameCount: Int
    let fps: Double
    let loops: Bool
}

enum SpriteAnimationCatalog {
    static let definitions: [SpriteAnimation: SpriteAnimationDefinition] = [
        .idle: SpriteAnimationDefinition(frameCount: 5, fps: 4, loops: true),
        .run: SpriteAnimationDefinition(frameCount: 3, fps: 6, loops: true),
        .walk: SpriteAnimationDefinition(frameCount: 4, fps: 5, loops: true),
        .sitA: SpriteAnimationDefinition(frameCount: 2, fps: 3, loops: false),
        .sitB: SpriteAnimationDefinition(frameCount: 2, fps: 3, loops: false),
        .bark: SpriteAnimationDefinition(frameCount: 2, fps: 4, loops: true),
        .playbow: SpriteAnimationDefinition(frameCount: 2, fps: 3, loops: false),
    ]

    static func definition(for animation: SpriteAnimation) -> SpriteAnimationDefinition {
        definitions[animation]!
    }

    /// Asset catalog image name, e.g. `idle_001`.
    static func frameAssetName(animation: SpriteAnimation, frameIndex: Int) -> String {
        let padded = String(format: "%03d", frameIndex + 1)
        return "\(animation.rawValue)_\(padded)"
    }

    static func frameAssetNames(for animation: SpriteAnimation) -> [String] {
        let count = definition(for: animation).frameCount
        return (0 ..< count).map { frameAssetName(animation: animation, frameIndex: $0) }
    }
}
