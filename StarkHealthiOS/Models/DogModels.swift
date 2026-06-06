import Foundation

enum DailyCareActionStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case completed = "COMPLETED"
    case skipped = "SKIPPED"
    case partiallyCompleted = "PARTIALLY_COMPLETED"
    case unclear = "UNCLEAR"
}

enum Tolerance: String, Codable {
    case good = "GOOD"
    case okay = "OKAY"
    case poor = "POOR"
    case painful = "PAINFUL"
    case unknown = "UNKNOWN"
}

enum VoiceNoteProcessingStatus: String, Codable {
    case pending = "PENDING"
    case transcribed = "TRANSCRIBED"
    case processed = "PROCESSED"
    case failed = "FAILED"
}

enum HealthObservationType: String, Codable {
    case slipping = "SLIPPING"
    case limping = "LIMPING"
    case weakness = "WEAKNESS"
    case stiffness = "STIFFNESS"
    case pain = "PAIN"
    case lowEnergy = "LOW_ENERGY"
    case appetite = "APPETITE"
    case bathroom = "BATHROOM"
    case medication = "MEDICATION"
    case generalNote = "GENERAL_NOTE"
}

enum CareActionCategory: String, Codable, CaseIterable {
    case stretch = "STRETCH"
    case strength = "STRENGTH"
    case mobility = "MOBILITY"
    case walk = "WALK"
    case medication = "MEDICATION"
    case generalCare = "GENERAL_CARE"
    case observationCheckpoint = "OBSERVATION_CHECKPOINT"
}

enum CareActionFrequency: String, Codable, CaseIterable {
    case daily = "DAILY"
    case everyOtherDay = "EVERY_OTHER_DAY"
    case weekly = "WEEKLY"
    case asNeeded = "AS_NEEDED"
}

enum CareActionTimeOfDay: String, Codable, CaseIterable {
    case morning = "MORNING"
    case evening = "EVENING"
    case anytime = "ANYTIME"
}

enum DogSex: String, Codable, CaseIterable {
    case male = "MALE"
    case female = "FEMALE"
    case unknown = "UNKNOWN"
}

struct UserSummary: Codable, Hashable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
}

struct DogRecord: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let breed: String?
    let age: Int?
    let sex: DogSex?
    let weightLbs: Double?
    let condition: String?
    let vetName: String?
    let vetPhone: String?
    let photoUrl: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    let role: String?
    let defaultCarePlan: String?
    let shareCode: String?
}

struct JoinPreview: Codable {
    let id: String
    let name: String
    let breed: String?
    let photoUrl: String?
}

struct CreateDogInput: Encodable {
    let name: String
    var breed: String?
    var age: Int?
    var sex: DogSex?
    var weightLbs: Double?
    var condition: String?
    var vetName: String?
    var vetPhone: String?
    var photoKey: String?
    var notes: String?
}

struct UpdateDogInput: Encodable {
    var name: String?
    var breed: String?
    var age: Int?
    var sex: DogSex?
    var weightLbs: Double?
    var condition: String?
    var vetName: String?
    var vetPhone: String?
    var photoKey: String?
    var notes: String?
}

struct MovementProgress: Codable {
    let completed: Int
    let total: Int
}

struct DailyCareActionStepRecord: Codable, Identifiable {
    let id: String
    let dailyCareActionId: String
    let careActionStepId: String
    let nameSnapshot: String
    let description: String?
    let instructions: String?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let mediaKey: String?
    let mediaContentType: String?
    let mediaUrl: String?
    let status: DailyCareActionStatus
    let completedAt: String?
    let completedByUserId: String?
    let notes: String?
    let completedBy: UserSummary?
}

struct DailyCareActionRecord: Codable, Identifiable {
    let id: String
    let dailyCareLogId: String
    let careActionId: String
    let nameSnapshot: String
    let categorySnapshot: String
    let status: DailyCareActionStatus
    let completedAt: String?
    let completedByUserId: String?
    let notes: String?
    let tolerance: Tolerance?
    let issueObserved: Bool
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let completedBy: UserSummary?
    let steps: [DailyCareActionStepRecord]
    let movementProgress: MovementProgress?
}

struct VoiceNoteRecord: Codable, Identifiable {
    let id: String
    let dogId: String
    let dailyCareLogId: String
    let userId: String
    let transcript: String
    let processingStatus: VoiceNoteProcessingStatus
    let caregiverNote: String?
    let needsReview: Bool
    let createdAt: String
    let user: UserSummary
}

struct HealthObservationRecord: Codable, Identifiable {
    let id: String
    let type: HealthObservationType
    let severity: String?
    let bodyArea: String?
    let note: String
    let observedAt: String?
    let createdAt: String
    let user: UserSummary
}

struct DailyLogPayload: Codable {
    let id: String
    let summary: String?
    let dailyCareActions: [DailyCareActionRecord]
    let voiceNotes: [VoiceNoteRecord]
    let healthObservations: [HealthObservationRecord]
}

struct TodayProgress: Codable {
    let completed: Int
    let total: Int
}

struct TodayPayload: Codable {
    let dog: DogRecord
    let date: String
    let dailyLog: DailyLogPayload
    let progress: TodayProgress
}

struct CalendarDaySummary: Codable, Identifiable {
    var id: String { date }
    let date: String
    let completedCount: Int
    let totalActions: Int
    let hasLog: Bool
}

struct CalendarPayload: Codable {
    let month: String
    let days: [CalendarDaySummary]
}

struct HistoryLogSummary: Codable, Identifiable {
    let id: String
    let date: String
    let summary: String?
    let completedCount: Int
    let totalActions: Int
    let observationCount: Int?
    let voiceNoteCount: Int?
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

struct HistoryPayload: Codable {
    let logs: [HistoryLogSummary]
    let pagination: PaginationInfo
}

struct CareActionStepRecord: Codable, Identifiable {
    let id: String
    let careActionId: String
    let name: String
    let description: String?
    let instructions: String?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let mediaKey: String?
    let mediaContentType: String?
    let mediaUrl: String?
    let sortOrder: Int
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
}

struct CareActionRecord: Codable, Identifiable {
    let id: String
    let carePlanId: String
    let name: String
    let description: String?
    let category: CareActionCategory
    let frequency: CareActionFrequency
    let timeOfDay: CareActionTimeOfDay?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let instructions: String?
    let sortOrder: Int
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    let steps: [CareActionStepRecord]
}

struct CarePlanPayload: Codable {
    let id: String
    let dogId: String
    let name: String
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    let actions: [CareActionRecord]
}

struct CreateCareActionInput: Encodable {
    let name: String
    var description: String?
    let category: CareActionCategory
    let frequency: CareActionFrequency
    var timeOfDay: CareActionTimeOfDay?
    var targetReps: Int?
    var targetDurationSeconds: Int?
    var instructions: String?
    var sortOrder: Int?
}

struct UpdateCareActionInput: Encodable {
    var name: String?
    var description: String?
    var category: CareActionCategory?
    var frequency: CareActionFrequency?
    var timeOfDay: CareActionTimeOfDay?
    var targetReps: Int?
    var targetDurationSeconds: Int?
    var instructions: String?
    var sortOrder: Int?
}

struct CreateCareActionStepInput: Encodable {
    let name: String
    var description: String?
    var instructions: String?
    var targetReps: Int?
    var targetDurationSeconds: Int?
    var mediaKey: String?
    var mediaContentType: String?
    var sortOrder: Int?
}

struct UpdateCareActionStepInput: Encodable {
    var name: String?
    var description: String?
    var instructions: String?
    var targetReps: Int?
    var targetDurationSeconds: Int?
    var mediaKey: String?
    var mediaContentType: String?
    var sortOrder: Int?
}

struct PresignDogPhotoResult: Decodable {
    let uploadUrl: String
    let photoKey: String
    let viewUrl: String
    let headers: [String: String]
    let expiresIn: Int
}

struct PresignCareStepMediaResult: Decodable {
    let uploadUrl: String
    let mediaKey: String
    let viewUrl: String
    let headers: [String: String]
    let expiresIn: Int
}

struct TranscribeVoiceNotePayload: Decodable {
    let dog: DogRecord
    let date: String
    let dailyLog: DailyLogPayload
    let progress: TodayProgress
    let text: String
    let voiceNote: VoiceNoteRecord
}
