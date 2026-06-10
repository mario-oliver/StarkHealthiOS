import Foundation

enum SpritePreset: Sendable {
    case careLogOpening
    case dailyPlanLoading
    case voiceListening
    case voiceProcessing
    case exerciseComplete
    case savingNote
    case recoveryScoring
    case emptyState
    case notificationSetup
    case dayComplete
    case errorRetry
    case caregiverSync
    case spriteGenerating

    struct Configuration: Sendable {
        let animation: SpriteAnimation
        let message: String?
        let subtext: String?
        let mode: SpriteOverlayMode
        let background: SpriteBackground
    }

    var configuration: Configuration {
        switch self {
        case .careLogOpening:
            Configuration(
                animation: .run,
                message: "Opening Stark's care log…",
                subtext: nil,
                mode: .blocking,
                background: .dimmed
            )
        case .dailyPlanLoading:
            Configuration(
                animation: .idle,
                message: "Fetching today's PT plan…",
                subtext: nil,
                mode: .blocking,
                background: .dimmed
            )
        case .voiceListening:
            Configuration(
                animation: .bark,
                message: "Listening…",
                subtext: "Tell Stark what happened.",
                mode: .inline,
                background: .transparent
            )
        case .voiceProcessing:
            Configuration(
                animation: .bark,
                message: "Understanding your note…",
                subtext: "Matching this to today's PT plan.",
                mode: .blocking,
                background: .dimmed
            )
        case .exerciseComplete:
            Configuration(
                animation: .sitA,
                message: "Nice work.",
                subtext: "Logged for today.",
                mode: .inline,
                background: .transparent
            )
        case .savingNote:
            Configuration(
                animation: .walk,
                message: "Saving Stark's update…",
                subtext: nil,
                mode: .blocking,
                background: .dimmed
            )
        case .recoveryScoring:
            Configuration(
                animation: .walk,
                message: "Reading the signs…",
                subtext: "Looking at movement, energy, soreness, and comfort.",
                mode: .blocking,
                background: .dimmed
            )
        case .emptyState:
            Configuration(
                animation: .idle,
                message: "Nothing logged yet.",
                subtext: "Start with a walk, mobility check, or voice note.",
                mode: .inline,
                background: .transparent
            )
        case .notificationSetup:
            Configuration(
                animation: .sitA,
                message: "Stark can remind you.",
                subtext: "Set gentle nudges for walks, meds, mobility, and recovery checks.",
                mode: .inline,
                background: .transparent
            )
        case .dayComplete:
            Configuration(
                animation: .playbow,
                message: "That's today's care done.",
                subtext: "Small reps add up for aging dogs.",
                mode: .inline,
                background: .transparent
            )
        case .errorRetry:
            Configuration(
                animation: .sitB,
                message: "Stark lost the scent.",
                subtext: "Try again in a moment.",
                mode: .inline,
                background: .transparent
            )
        case .caregiverSync:
            Configuration(
                animation: .walk,
                message: "New care note added.",
                subtext: "Stark's timeline is up to date.",
                mode: .inline,
                background: .transparent
            )
        case .spriteGenerating:
            Configuration(
                animation: .walk,
                message: "Creating your companion…",
                subtext: "Generating custom sprites from your dog photo.",
                mode: .blocking,
                background: .dimmed
            )
        }
    }
}
