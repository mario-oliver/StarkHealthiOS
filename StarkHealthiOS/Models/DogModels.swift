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

enum CareBucket: String, Codable, CaseIterable {
    case activity = "ACTIVITY"
    case mobility = "MOBILITY"
    case recovery = "RECOVERY"
}

enum DailyTaskSource: String, Codable {
    case plan = "PLAN"
    case adHoc = "AD_HOC"
    case llmExtracted = "LLM_EXTRACTED"
    case planVariation = "PLAN_VARIATION"
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

struct HealthObservationRecord: Codable, Identifiable, Hashable {
    let id: String
    let type: HealthObservationType
    let bucket: CareBucket?
    let severity: String?
    let bodyArea: String?
    let note: String
    let observedAt: String?
    let createdAt: String
    let user: UserSummary
}

struct BucketScore: Codable {
    let score: Int
    let label: String
    let summary: String
    let reasons: [String]
    let signals: [String]?
    let computedAt: String
}

struct SubstitutedForTask: Codable {
    let id: String
    let nameSnapshot: String
}

struct DailyTaskRecord: Codable, Identifiable {
    let id: String
    let dailyCareLogId: String
    let bucket: CareBucket
    let source: DailyTaskSource
    let nameSnapshot: String
    let descriptionSnapshot: String?
    let instructionsSnapshot: String?
    let status: DailyCareActionStatus
    let completedAt: String?
    let completedByUserId: String?
    let notes: String?
    let targetReps: Int?
    let actualReps: Int?
    let targetDurationSeconds: Int?
    let actualDurationSeconds: Int?
    let careActionId: String?
    let careActionStepId: String?
    let substitutedForTaskId: String?
    let substitutedFor: SubstitutedForTask?
    let needsReview: Bool
    let sortOrder: Int
    let mediaUrl: String?
    let mediaContentType: String?
    let completedBy: UserSummary?
}

struct BucketProgress: Codable {
    let completed: Int
    let total: Int
}

struct BucketPayload: Codable {
    let tasks: [DailyTaskRecord]
    let observations: [HealthObservationRecord]
    let progress: BucketProgress?
    let score: BucketScore?
}

struct BucketScores: Codable {
    let activity: BucketScore?
    let mobility: BucketScore?
    let recovery: BucketScore?
}

struct TodayBuckets: Codable {
    let activity: BucketPayload
    let mobility: BucketPayload
    let recovery: BucketPayload
}

struct DailyLogPayload: Codable {
    let id: String
    let summary: String?
    let bucketScores: BucketScores?
    let scoreComputedAt: String?
    let scoreInputVersion: String?
    let latestVoiceNoteAt: String?
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
    let buckets: TodayBuckets
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
    let bucket: CareBucket?
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
    let bucket: CareBucket?
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

struct CreateDailyTaskInput: Encodable {
    var dailyCareLogId: String?
    var date: String?
    let bucket: CareBucket
    let name: String
    var description: String?
    var notes: String?
    var targetReps: Int?
    var targetDurationSeconds: Int?
}

struct ReviewDailyTaskInput: Encodable {
    let accept: Bool
    var status: DailyCareActionStatus?
}

struct CreateCareActionInput: Encodable {
    let name: String
    var description: String?
    let category: CareActionCategory
    var bucket: CareBucket?
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
    var bucket: CareBucket?
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
    let buckets: TodayBuckets
    let progress: TodayProgress
    let text: String
    let voiceNote: VoiceNoteRecord
}

// MARK: - Exercise Agent

enum ExerciseAgentSessionStatus: String, Codable {
    case active = "ACTIVE"
    case awaitingInput = "AWAITING_INPUT"
    case draftReady = "DRAFT_READY"
    case committed = "COMMITTED"
    case failed = "FAILED"
}

struct ExerciseAgentMessage: Codable {
    let role: String
    let content: String
}

struct ProposedMovement: Codable {
    let name: String
    let description: String?
    let instructions: String?
    let sortOrder: Int?
}

struct ProposedExercise: Codable {
    let name: String
    let description: String?
    let category: CareActionCategory
    let frequency: CareActionFrequency
    let timeOfDay: CareActionTimeOfDay?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let instructions: String?
    let movements: [ProposedMovement]
    let rationale: String
    let safetyNotes: String
    let researchSummary: String
}

struct ExerciseAgentSessionPayload: Codable, Identifiable {
    let id: String
    let dogId: String
    let status: ExerciseAgentSessionStatus
    let messages: [ExerciseAgentMessage]
    let questions: [String]
    let draft: ProposedExercise?
    let createdAt: String
    let updatedAt: String
}
