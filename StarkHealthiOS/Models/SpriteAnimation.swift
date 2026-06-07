import CoreGraphics
import Foundation

enum SpriteAnimation: String, CaseIterable, Sendable {
    case idle
    case run
    case walk
    case sitA
    case sitB
    case bark
    case playbow
}

enum SpriteSize: Sendable {
    case small
    case medium
    case large

    var points: CGFloat {
        switch self {
        case .small: 72
        case .medium: 120
        case .large: 168
        }
    }
}

enum SpriteOverlayMode: Sendable {
    case blocking
    case inline
}

enum SpriteBackground: Sendable {
    case dimmed
    case transparent
    case solid
}
