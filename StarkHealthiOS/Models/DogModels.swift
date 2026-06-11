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

// Bucket is the ONLY categorization. Specificity lives in the action's `name`,
// never in a second taxonomy. See context.md#Bucket.
enum CareBucket: String, Codable, CaseIterable {
    case activity = "ACTIVITY"
    case mobility = "MOBILITY"
    case recovery = "RECOVERY"
}

// Source of a DailyCareAction. Wire values match the API's enum; the Swift type is
// named for the consolidated DailyCareAction (the former parallel daily-task table is
// merged into it).
enum DailyCareActionSource: String, Codable {
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

// MARK: - Daily Care Action (the single dated execution record)

struct SubstitutedForAction: Codable {
    let id: String
    let nameSnapshot: String
}

// The single dated, actualized instance of a CareAction — what was (or wasn't) done
// on a given day. The former parallel daily-task record is merged into this; there are
// no sub-steps. See context.md#DailyCareAction.
struct DailyCareActionRecord: Codable, Identifiable {
    let id: String
    let dailyCareLogId: String
    let bucket: CareBucket
    let source: DailyCareActionSource
    let nameSnapshot: String
    let descriptionSnapshot: String?
    let instructionsSnapshot: String?
    let status: DailyCareActionStatus
    let tolerance: Tolerance?
    let completedAt: String?
    let completedByUserId: String?
    let notes: String?
    let targetReps: Int?
    let actualReps: Int?
    let targetDurationSeconds: Int?
    let actualDurationSeconds: Int?
    let careActionId: String?
    let substitutedForId: String?
    let substitutedFor: SubstitutedForAction?
    let extractionConfidence: Double?
    let needsReview: Bool
    let sortOrder: Int
    let completedBy: UserSummary?
}

// A dumb artifact: captured audio + its Whisper transcript. It is an *input* to a
// CareAgentSession, not a session. Holds no extraction results. See context.md#VoiceNote.
struct VoiceNoteRecord: Codable, Identifiable {
    let id: String
    let dogId: String
    let dailyCareLogId: String
    let userId: String
    let audioUrl: String?
    let transcript: String
    let processingStatus: VoiceNoteProcessingStatus
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

struct BucketProgress: Codable {
    let completed: Int
    let total: Int
}

struct BucketPayload: Codable {
    let actions: [DailyCareActionRecord]
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

// MARK: - Care Plan / Care Action (prescribed)

// One flat, polymorphic, prescribed care item — the "main citizen". Grouped by
// `bucket` (required); no sub-steps; no second `category` taxonomy.
// See context.md#CareAction.
struct CareActionRecord: Codable, Identifiable {
    let id: String
    let carePlanId: String
    let name: String
    let description: String?
    let bucket: CareBucket
    let frequency: CareActionFrequency
    let timeOfDay: CareActionTimeOfDay?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let instructions: String?
    let sortOrder: Int
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
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

struct CreateDailyCareActionInput: Encodable {
    var dailyCareLogId: String?
    var date: String?
    let bucket: CareBucket
    let name: String
    var description: String?
    var notes: String?
    var targetReps: Int?
    var targetDurationSeconds: Int?
}

struct CreateCareActionInput: Encodable {
    let name: String
    var description: String?
    let bucket: CareBucket
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
    var bucket: CareBucket?
    var frequency: CareActionFrequency?
    var timeOfDay: CareActionTimeOfDay?
    var targetReps: Int?
    var targetDurationSeconds: Int?
    var instructions: String?
    var sortOrder: Int?
}

struct PresignDogPhotoResult: Decodable {
    let uploadUrl: String
    let photoKey: String
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

// MARK: - Care Agent Session

// The single conversational producer. One type for ALL conversational LLM flows;
// replaces the two former per-flow session types (exercise-agent and program-audit).
// See context.md#CareAgentSession.
enum CareAgentSessionKind: String, Codable {
    case dailyLog = "DAILY_LOG"
    case planBuild = "PLAN_BUILD"
    case planAudit = "PLAN_AUDIT"
}

enum CareAgentSessionStatus: String, Codable {
    case active = "ACTIVE"
    case awaitingInput = "AWAITING_INPUT"
    case draftReady = "DRAFT_READY"
    case committed = "COMMITTED"
    case failed = "FAILED"
}

struct CareAgentMessage: Codable {
    let role: String
    let content: String
}

// A care action proposed by a PLAN_BUILD session. Grouped by bucket (not a removed
// `category`), with no sub-movements (steps are gone — distinct movements are
// distinct actions).
struct ProposedCareAction: Codable {
    let name: String
    let description: String?
    let bucket: CareBucket
    let frequency: CareActionFrequency
    let timeOfDay: CareActionTimeOfDay?
    let targetReps: Int?
    let targetDurationSeconds: Int?
    let instructions: String?
    let rationale: String
    let safetyNotes: String
    let researchSummary: String
}

struct AuditObservation: Codable {
    let actionId: String
    let actionName: String
    let finding: String
    let severity: String
    let recommendation: String
}

struct AuditReport: Codable {
    let summary: String
    let strengths: [String]
    let gaps: [String]
    let observations: [AuditObservation]
    let overallRating: String
}

struct ProposedChangeUpdates: Codable {
    let name: String?
    let description: String?
    let bucket: String?
    let frequency: String?
    let timeOfDay: String?
    let instructions: String?
}

struct ProposedChange: Codable, Identifiable {
    let id: String
    let type: String
    let actionId: String?
    let actionName: String?
    let updates: ProposedChangeUpdates?
    let newAction: ProposedCareAction?
    let reason: String
}

struct ProposedProgramChanges: Codable {
    let summary: String
    let changes: [ProposedChange]
}

// The session draft (JSON, refined across turns). Which fields are populated depends
// on the session `kind`: PLAN_BUILD fills `proposedAction`; PLAN_AUDIT fills `report`
// and then `changes`.
struct CareAgentDraft: Codable {
    let proposedAction: ProposedCareAction?
    let report: AuditReport?
    let changes: ProposedProgramChanges?
    // DAILY_LOG draft arrays — present (as arrays, possibly empty) only for DAILY_LOG
    // sessions; absent for PLAN_BUILD / PLAN_AUDIT. Read via `dailyLog` (DailyLogDraft.swift).
    let completions: [DailyLogCompletionDraft]?
    let adHocActions: [DailyLogAdHocActionDraft]?
    let observations: [DailyLogObservationDraft]?
    let planChangeSuggestions: [DailyLogPlanChangeSuggestion]?
}

struct CareAgentSessionPayload: Codable, Identifiable {
    let id: String
    let dogId: String
    let kind: CareAgentSessionKind
    let status: CareAgentSessionStatus
    let messages: [CareAgentMessage]
    let questions: [String]
    let draft: CareAgentDraft?
    let voiceNoteId: String?
    let committedCarePlanId: String?
    let createdAt: String
    let updatedAt: String
}

struct CareAgentCommitResult: Decodable {
    let status: String
    let committedActions: [CareActionRecord]?
    let changesApplied: Int?
}
