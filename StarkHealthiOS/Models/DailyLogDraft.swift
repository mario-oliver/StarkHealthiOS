import Foundation

// The frozen DAILY_LOG `draft` Contract (issue 0019), exactly as
// `serializeCareAgentSession` surfaces it from `dailyLogDraftSchema` in
// api-stark-sesh: `{ completions, adHocActions, observations, planChangeSuggestions }`,
// each item carrying a stable `changeId` (issues 0011/0012/0013). Field names mirror
// the wire 1:1 to avoid client/api drift (see stark-web-api-bucket-contract-drift).

/// Severity of a health observation. Matches api `ObservationSeverity` (ADR-0002 taxonomy).
enum ObservationSeverity: String, Codable {
    case mild = "MILD"
    case moderate = "MODERATE"
    case severe = "SEVERE"
    case unknown = "UNKNOWN"
}

/// A caregiver-reported completion matched to one of today's planned `DailyCareAction`s.
struct DailyLogCompletionDraft: Codable, Identifiable, Equatable {
    let changeId: String
    let dailyCareActionId: String
    let nameSnapshot: String
    let bucket: CareBucket
    let actualReps: Int?
    let actualDurationSeconds: Int?
    let tolerance: Tolerance?
    let extractionConfidence: Double
    let needsReview: Bool
    var id: String { changeId }
}

/// An activity with no confident planned match (`source: AD_HOC` on commit).
struct DailyLogAdHocActionDraft: Codable, Identifiable, Equatable {
    let changeId: String
    let name: String
    let bucket: CareBucket
    let actualReps: Int?
    let actualDurationSeconds: Int?
    let extractionConfidence: Double
    let needsReview: Bool
    var id: String { changeId }
}

/// A health observation extracted from the note.
struct DailyLogObservationDraft: Codable, Identifiable, Equatable {
    let changeId: String
    let type: HealthObservationType
    let severity: ObservationSeverity?
    let bodyArea: String?
    let note: String
    let extractionConfidence: Double
    let needsReview: Bool
    var id: String { changeId }
}

/// Inert plan-change hint. Has **no** `changeId` — by construction it can never enter
/// `selectedChangeIds` (ADR-0003 dec.8). Surfaced only as a soft nudge.
struct DailyLogPlanChangeSuggestion: Codable, Equatable {
    let text: String
    let likelyAction: String?
}

/// The whole reviewable DAILY_LOG draft.
struct DailyLogDraft: Codable, Equatable {
    let completions: [DailyLogCompletionDraft]
    let adHocActions: [DailyLogAdHocActionDraft]
    let observations: [DailyLogObservationDraft]
    let planChangeSuggestions: [DailyLogPlanChangeSuggestion]

    var isEmpty: Bool { completions.isEmpty && adHocActions.isEmpty && observations.isEmpty }
    var totalItems: Int { completions.count + adHocActions.count + observations.count }

    /// Every selectable change id. Plan-change suggestions are inert and never appear here.
    var selectableChangeIds: Set<String> {
        var s = Set<String>()
        completions.forEach { s.insert($0.changeId) }
        adHocActions.forEach { s.insert($0.changeId) }
        observations.forEach { s.insert($0.changeId) }
        return s
    }

    /// Pre-selected items: confident and not flagged. `needsReview` starts unchecked so a
    /// misheard line can't ride a default through to commit (ADR-0003 dec.3).
    var defaultSelection: Set<String> {
        var s = Set<String>()
        for c in completions where !c.needsReview && c.extractionConfidence >= 0.75 { s.insert(c.changeId) }
        for a in adHocActions where !a.needsReview && a.extractionConfidence >= 0.75 { s.insert(a.changeId) }
        for o in observations where !o.needsReview && o.extractionConfidence >= 0.75 { s.insert(o.changeId) }
        return s
    }

    /// The confirm payload: exactly the selected ids that are real draft items. Filtering
    /// through `selectableChangeIds` makes it structurally impossible to commit a
    /// plan-change suggestion or a stale id.
    func confirmChangeIds(selected: Set<String>) -> [String] {
        Array(selected.intersection(selectableChangeIds)).sorted()
    }
}

extension CareAgentDraft {
    /// The DAILY_LOG view of this draft — non-nil only when the four DAILY_LOG arrays
    /// decoded (i.e. the session `kind` is DAILY_LOG). Other kinds return nil.
    var dailyLog: DailyLogDraft? {
        guard let completions, let adHocActions, let observations, let planChangeSuggestions else {
            return nil
        }
        return DailyLogDraft(
            completions: completions,
            adHocActions: adHocActions,
            observations: observations,
            planChangeSuggestions: planChangeSuggestions
        )
    }
}
