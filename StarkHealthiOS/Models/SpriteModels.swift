import Foundation

// MARK: - Sprite Generation payloads

enum SpriteGenerationStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case running = "RUNNING"
    case awaitingInput = "AWAITING_INPUT"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case canceled = "CANCELED"
}

struct SpriteGenerationSessionPayload: Codable, Sendable {
    let id: String
    let dogId: String
    let userId: String
    let status: SpriteGenerationStatus
    let currentStep: String?
    let progress: Double
    let breedInput: String
    let normalizedBreed: String?
    let spriteSetId: String?
    let error: String?
    let createdAt: String
    let updatedAt: String
}

struct SpriteManifestAnimationEntry: Codable, Sendable {
    let frames: Int
    let fps: Double
    let loop: Bool
    let keys: [String]
}

struct SpriteManifest: Codable, Sendable {
    let styleVersion: String
    let breed: String
    let generatedAt: String
    let animations: [String: SpriteManifestAnimationEntry]
}

struct SpriteSetPayload: Codable, Sendable {
    let id: String
    let dogId: String
    let isActive: Bool
    let styleVersion: String
    let storagePrefix: String
    let manifest: SpriteManifest
    /// Base URL for frame image requests, e.g. https://api/.../dogs/{id}/sprites
    let frameBaseUrl: String
    let createdAt: String
}
