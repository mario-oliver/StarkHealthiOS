import Foundation
import Observation

// The slice of the API the DAILY_LOG review flow needs. Injecting it (rather than the
// concrete APIClient) lets XCTest drive the flow against a mock — the real cross-repo
// path is issue 0020.
@MainActor
protocol DailyLogReviewAPI {
    func createDailyLogSession(_ dogId: String, voiceNoteId: String) async throws -> CareAgentSessionPayload
    func sendCareAgentMessage(_ dogId: String, sessionId: String, message: String) async throws -> CareAgentSessionPayload
    func commitCareAgentSession(_ dogId: String, sessionId: String, selectedChangeIds: [String]?) async throws -> CareAgentCommitResult
}

extension APIClient: DailyLogReviewAPI {}

/// Drives the post-voice-note review: create the DAILY_LOG session, surface the returned
/// draft (the 0018-chosen design), handle the one clarifying question, and commit exactly
/// the selected `changeId`s. Maps the session `status` onto a small phase machine so the
/// view never has to reason about wire statuses directly.
@MainActor
@Observable
final class DailyLogReviewViewModel {
    enum Phase: Equatable {
        case loading
        case awaitingInput(question: String)
        case review
        case empty(message: String)
        case committed(count: Int)
        case failed(message: String)
    }

    private(set) var phase: Phase = .loading
    private(set) var draft = DailyLogDraft.empty
    /// The user's current selection (change ids). Seeded from `draft.defaultSelection`.
    var selected: Set<String> = []
    private(set) var sessionId: String?
    private(set) var committing = false
    private var answering = false
    private var didStart = false

    let dogId: String
    let voiceNoteId: String
    private let api: DailyLogReviewAPI

    init(dogId: String, voiceNoteId: String, api: DailyLogReviewAPI) {
        self.dogId = dogId
        self.voiceNoteId = voiceNoteId
        self.api = api
    }

    /// The confirm payload — exactly the selected real draft items, never a plan-change.
    var confirmChangeIds: [String] { draft.confirmChangeIds(selected: selected) }

    /// Create the session once on first appearance (idempotent across `.task` re-runs).
    func startIfNeeded() async {
        guard !didStart else { return }
        didStart = true
        await start()
    }

    func start() async {
        phase = .loading
        do { apply(try await api.createDailyLogSession(dogId, voiceNoteId: voiceNoteId)) }
        catch { phase = .failed(message: error.localizedDescription) }
    }

    /// Answer the one clarifying question (AWAITING_INPUT → a fresh draft, ADR-0003 dec.5).
    func answer(_ option: String) async {
        guard let sessionId, !answering else { return }
        answering = true
        defer { answering = false }
        phase = .loading
        do { apply(try await api.sendCareAgentMessage(dogId, sessionId: sessionId, message: option)) }
        catch { phase = .failed(message: error.localizedDescription) }
    }

    /// Commit the selected items into today's log. Returns the number committed.
    @discardableResult
    func commit() async -> Int {
        guard let sessionId, !committing else { return 0 }
        committing = true
        defer { committing = false }
        let ids = confirmChangeIds
        do {
            _ = try await api.commitCareAgentSession(dogId, sessionId: sessionId, selectedChangeIds: ids)
            phase = .committed(count: ids.count)
            return ids.count
        } catch {
            phase = .failed(message: error.localizedDescription)
            return 0
        }
    }

    func toggle(_ changeId: String) {
        if selected.contains(changeId) { selected.remove(changeId) } else { selected.insert(changeId) }
    }

    private func apply(_ session: CareAgentSessionPayload) {
        sessionId = session.id
        let d = session.draft?.dailyLog ?? .empty
        draft = d
        switch session.status {
        case .awaitingInput:
            phase = .awaitingInput(question: session.questions.first ?? "Which one did you mean?")
        case .draftReady, .active:
            if d.isEmpty {
                phase = .empty(message: session.messages.last?.content ?? "I didn't catch any care to log.")
            } else {
                selected = d.defaultSelection
                phase = .review
            }
        case .committed:
            phase = .committed(count: d.selectableChangeIds.count)
        case .failed:
            phase = .failed(message: session.messages.last?.content ?? "Something went wrong extracting your note.")
        }
    }
}

extension DailyLogDraft {
    static let empty = DailyLogDraft(completions: [], adHocActions: [], observations: [], planChangeSuggestions: [])
}
