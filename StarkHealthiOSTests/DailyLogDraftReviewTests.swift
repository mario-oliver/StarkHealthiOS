//
//  DailyLogDraftReviewTests.swift
//  StarkHealthiOSTests
//
//  Issue 0019 machine acceptance:
//   - Decoding a DAILY_LOG `CareAgentSessionPayload` (the real serialized Contract:
//     serializeCareAgentSession + dailyLogDraftSchema) yields the expected
//     completions / ad-hoc / observations.
//   - The confirm payload contains exactly the selected `changeId`s and never a
//     `planChangeSuggestion` (which has no changeId by construction).
//   - The review view model drives create → (one question) → commit against a mock API.
//

import XCTest
@testable import StarkHealthiOS

@MainActor
final class DailyLogDraftReviewTests: XCTestCase {

    private let decoder = JSONDecoder()
    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    // A full DRAFT_READY DAILY_LOG payload, shaped exactly as the api serializer emits it
    // (note: no `committedCarePlanId` key — the wire omits it; the model field is optional).
    private let fullDraftJSON = """
    {
      "id": "cas_dl1",
      "dogId": "dog_1",
      "kind": "DAILY_LOG",
      "status": "DRAFT_READY",
      "messages": [{ "role": "assistant", "content": "Here's what I heard." }],
      "questions": [],
      "draft": {
        "completions": [
          { "changeId": "c1", "dailyCareActionId": "dca_1", "nameSnapshot": "Hip flexor stretches", "bucket": "MOBILITY", "actualReps": 10, "actualDurationSeconds": null, "tolerance": "GOOD", "extractionConfidence": 0.93, "needsReview": false },
          { "changeId": "c2", "dailyCareActionId": "dca_2", "nameSnapshot": "Evening walk", "bucket": "ACTIVITY", "actualReps": null, "actualDurationSeconds": 600, "tolerance": null, "extractionConfidence": 0.68, "needsReview": true }
        ],
        "adHocActions": [
          { "changeId": "a1", "name": "Backyard fetch", "bucket": "ACTIVITY", "actualReps": null, "actualDurationSeconds": null, "extractionConfidence": 0.86, "needsReview": false }
        ],
        "observations": [
          { "changeId": "o1", "type": "LIMPING", "severity": "MILD", "bodyArea": "back left leg", "note": "Limping a little on the back left", "extractionConfidence": 0.82, "needsReview": false },
          { "changeId": "o2", "type": "LOW_ENERGY", "severity": null, "bodyArea": null, "note": "Seemed low energy after dinner", "extractionConfidence": 0.54, "needsReview": true }
        ],
        "planChangeSuggestions": [
          { "text": "Add more reps to the hip flexor stretches going forward", "likelyAction": "Hip flexor stretches" }
        ]
      },
      "voiceNoteId": "vn_1",
      "createdAt": "2026-06-11T09:00:00.000Z",
      "updatedAt": "2026-06-11T09:00:01.000Z"
    }
    """

    private let awaitingInputJSON = """
    {
      "id": "cas_dl2", "dogId": "dog_1", "kind": "DAILY_LOG", "status": "AWAITING_INPUT",
      "messages": [], "questions": ["You said \\"his stretches\\" — which one?"],
      "draft": { "completions": [], "adHocActions": [], "observations": [], "planChangeSuggestions": [] },
      "voiceNoteId": "vn_1", "createdAt": "2026-06-11T09:00:00.000Z", "updatedAt": "2026-06-11T09:00:00.000Z"
    }
    """

    private let emptyDraftJSON = """
    {
      "id": "cas_dl3", "dogId": "dog_1", "kind": "DAILY_LOG", "status": "DRAFT_READY",
      "messages": [{ "role": "assistant", "content": "I didn't catch any care to log." }], "questions": [],
      "draft": { "completions": [], "adHocActions": [], "observations": [], "planChangeSuggestions": [] },
      "voiceNoteId": "vn_1", "createdAt": "2026-06-11T09:00:00.000Z", "updatedAt": "2026-06-11T09:00:00.000Z"
    }
    """

    // MARK: - Decoding the real DAILY_LOG draft

    func testDailyLogDraft_decodesCompletionsAdHocObservations() throws {
        let s = try decode(CareAgentSessionPayload.self, from: fullDraftJSON)
        XCTAssertEqual(s.kind, .dailyLog)
        XCTAssertEqual(s.status, .draftReady)
        let draft = try XCTUnwrap(s.draft?.dailyLog)

        XCTAssertEqual(draft.completions.count, 2)
        XCTAssertEqual(draft.adHocActions.count, 1)
        XCTAssertEqual(draft.observations.count, 2)
        XCTAssertEqual(draft.planChangeSuggestions.count, 1)

        let walk = draft.completions[1]
        XCTAssertEqual(walk.changeId, "c2")
        XCTAssertEqual(walk.dailyCareActionId, "dca_2")
        XCTAssertEqual(walk.bucket, .activity)
        XCTAssertEqual(walk.actualDurationSeconds, 600)
        XCTAssertNil(walk.tolerance)
        XCTAssertTrue(walk.needsReview)

        let stretch = draft.completions[0]
        XCTAssertEqual(stretch.tolerance, .good)
        XCTAssertEqual(stretch.actualReps, 10)

        let limp = draft.observations[0]
        XCTAssertEqual(limp.type, .limping)
        XCTAssertEqual(limp.severity, .mild)
        XCTAssertEqual(limp.bodyArea, "back left leg")
        XCTAssertEqual(draft.observations[1].severity, nil)

        XCTAssertEqual(draft.adHocActions[0].name, "Backyard fetch")
        XCTAssertEqual(draft.adHocActions[0].bucket, .activity)
    }

    func testDailyLogDraft_isNilForNonDailyLogKinds() throws {
        // A PLAN_BUILD draft has no DAILY_LOG arrays → `dailyLog` is nil (no false positives).
        let json = """
        { "id":"x","dogId":"d","kind":"PLAN_BUILD","status":"DRAFT_READY","messages":[],"questions":[],
          "draft": { "proposedAction": null, "report": null, "changes": null },
          "voiceNoteId": null, "createdAt":"2026-06-11T09:00:00.000Z","updatedAt":"2026-06-11T09:00:00.000Z" }
        """
        let s = try decode(CareAgentSessionPayload.self, from: json)
        XCTAssertNil(s.draft?.dailyLog)
    }

    // MARK: - Selection + confirm payload

    func testSelectableChangeIds_excludePlanChangeSuggestions() throws {
        let draft = try XCTUnwrap(decode(CareAgentSessionPayload.self, from: fullDraftJSON).draft?.dailyLog)
        XCTAssertEqual(draft.selectableChangeIds, ["c1", "c2", "a1", "o1", "o2"])
        // Plan-change suggestions carry no changeId and never appear in the selectable set.
        XCTAssertFalse(draft.selectableChangeIds.contains("Add more reps to the hip flexor stretches going forward"))
    }

    func testDefaultSelection_isConfidentAndNotNeedsReview() throws {
        let draft = try XCTUnwrap(decode(CareAgentSessionPayload.self, from: fullDraftJSON).draft?.dailyLog)
        // c1 (0.93,F), a1 (0.86,F), o1 (0.82,F) are pre-selected; c2/o2 are needsReview.
        XCTAssertEqual(draft.defaultSelection, ["c1", "a1", "o1"])
    }

    func testConfirmChangeIds_areExactlySelectedItems_neverPlanChangeOrStale() throws {
        let draft = try XCTUnwrap(decode(CareAgentSessionPayload.self, from: fullDraftJSON).draft?.dailyLog)
        // User selects two real items, plus a stale id and a plan-change string that must be filtered out.
        let selected: Set<String> = ["c1", "o2", "stale-id",
                                     "Add more reps to the hip flexor stretches going forward"]
        XCTAssertEqual(draft.confirmChangeIds(selected: selected), ["c1", "o2"])
    }

    // MARK: - View model flow (mock API)

    func testViewModel_review_thenCommit_sendsExactlySelectedIds() async throws {
        let api = MockDailyLogAPI(createResult: try decode(CareAgentSessionPayload.self, from: fullDraftJSON))
        let vm = DailyLogReviewViewModel(dogId: "dog_1", voiceNoteId: "vn_1", api: api)

        await vm.start()
        XCTAssertEqual(api.lastVoiceNoteId, "vn_1")
        XCTAssertEqual(vm.phase, .review)
        XCTAssertEqual(vm.selected, ["c1", "a1", "o1"])   // seeded from defaultSelection

        // Caregiver curates: keep one default + add a needsReview item; drop the rest.
        vm.selected = ["c1", "c2"]
        await vm.commit()

        XCTAssertEqual(api.capturedSelectedChangeIds, ["c1", "c2"])
        XCTAssertFalse(api.capturedSelectedChangeIds?.contains("Add more reps to the hip flexor stretches going forward") ?? false)
        XCTAssertEqual(vm.phase, .committed(count: 2))
    }

    func testViewModel_awaitingInput_thenAnswerProducesDraft() async throws {
        let api = MockDailyLogAPI(createResult: try decode(CareAgentSessionPayload.self, from: awaitingInputJSON))
        api.messageResult = try decode(CareAgentSessionPayload.self, from: fullDraftJSON)
        let vm = DailyLogReviewViewModel(dogId: "dog_1", voiceNoteId: "vn_1", api: api)

        await vm.start()
        guard case .awaitingInput(let question) = vm.phase else {
            return XCTFail("expected awaitingInput, got \(vm.phase)")
        }
        XCTAssertTrue(question.contains("which one"))

        await vm.answer("Hip flexor stretches")
        XCTAssertEqual(api.lastMessage, "Hip flexor stretches")
        XCTAssertEqual(vm.phase, .review)
    }

    func testViewModel_emptyTranscript_isEmptyPhaseNotFailed() async throws {
        let api = MockDailyLogAPI(createResult: try decode(CareAgentSessionPayload.self, from: emptyDraftJSON))
        let vm = DailyLogReviewViewModel(dogId: "dog_1", voiceNoteId: "vn_1", api: api)
        await vm.start()
        XCTAssertEqual(vm.phase, .empty(message: "I didn't catch any care to log."))
    }
}

// MARK: - Mock API

@MainActor
final class MockDailyLogAPI: DailyLogReviewAPI {
    var createResult: CareAgentSessionPayload
    var messageResult: CareAgentSessionPayload?
    var commitResult = CareAgentCommitResult(status: "committed", committedActions: nil, changesApplied: nil)

    private(set) var lastVoiceNoteId: String?
    private(set) var lastMessage: String?
    private(set) var capturedSelectedChangeIds: [String]?

    init(createResult: CareAgentSessionPayload) { self.createResult = createResult }

    func createDailyLogSession(_ dogId: String, voiceNoteId: String) async throws -> CareAgentSessionPayload {
        lastVoiceNoteId = voiceNoteId
        return createResult
    }

    func sendCareAgentMessage(_ dogId: String, sessionId: String, message: String) async throws -> CareAgentSessionPayload {
        lastMessage = message
        return messageResult ?? createResult
    }

    func commitCareAgentSession(_ dogId: String, sessionId: String, selectedChangeIds: [String]?) async throws -> CareAgentCommitResult {
        capturedSelectedChangeIds = selectedChangeIds
        return commitResult
    }
}
