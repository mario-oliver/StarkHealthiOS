import SwiftUI

struct SpriteOverlayView: View {
    var animation: SpriteAnimation
    var message: String?
    var subtext: String?
    var mode: SpriteOverlayMode = .blocking
    var background: SpriteBackground?
    var size: SpriteSize = .medium
    var loop: Bool?
    var animated: Bool?
    var onComplete: (() -> Void)?

    @State private var appeared = false

    init(
        preset: SpritePreset,
        message: String? = nil,
        subtext: String? = nil,
        mode: SpriteOverlayMode? = nil,
        background: SpriteBackground? = nil,
        size: SpriteSize = .medium,
        loop: Bool? = nil,
        animated: Bool? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        let config = preset.configuration
        self.animation = config.animation
        self.message = message ?? config.message
        self.subtext = subtext ?? config.subtext
        self.mode = mode ?? config.mode
        self.background = background ?? config.background
        self.size = size
        self.loop = loop
        self.animated = animated
        self.onComplete = onComplete
    }

    init(
        animation: SpriteAnimation,
        message: String? = nil,
        subtext: String? = nil,
        mode: SpriteOverlayMode = .blocking,
        background: SpriteBackground? = nil,
        size: SpriteSize = .medium,
        loop: Bool? = nil,
        animated: Bool? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.animation = animation
        self.message = message
        self.subtext = subtext
        self.mode = mode
        self.background = background
        self.size = size
        self.loop = loop
        self.animated = animated
        self.onComplete = onComplete
    }

    private var resolvedBackground: SpriteBackground {
        if let background { return background }
        return mode == .blocking ? .dimmed : .transparent
    }

    var body: some View {
        Group {
            if mode == .blocking {
                ZStack {
                    backgroundView
                    content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            } else {
                content
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.97)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch resolvedBackground {
        case .dimmed:
            Color.black.opacity(0.25)
                .ignoresSafeArea()
        case .solid:
            StarkTheme.background
                .ignoresSafeArea()
        case .transparent:
            Color.clear
        }
    }

    private var content: some View {
        VStack(spacing: 16) {
            StarkSpriteView(
                animation: animation,
                size: size,
                loop: loop,
                animated: animated,
                onComplete: onComplete
            )

            if message != nil || subtext != nil {
                VStack(spacing: 6) {
                    if let message {
                        Text(message)
                            .font(.headline)
                            .foregroundStyle(StarkTheme.foreground)
                            .multilineTextAlignment(.center)
                    }
                    if let subtext {
                        Text(subtext)
                            .font(.subheadline)
                            .foregroundStyle(StarkTheme.mutedForeground)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: 280)
            }
        }
        .padding(24)
    }
}
