//
//  ContractDecodingTests.swift
//  StarkHealthiOSTests
//
//  Encodes issue 0008's machine acceptance criteria: the iOS Codable models decode
//  the consolidated-contract shapes (context.md + Engineering/Data Model.md):
//    - CareAction with required `bucket`, no steps / no `category`
//    - DailyCareAction (unified) with `source` and target-vs-actual
//    - CareAgentSession (the single conversational producer; replaces the two
//      former per-flow agent session types)
//    - slimmed VoiceNote (no extraction / caregiverNote / needsReview)
//

import XCTest
@testable import StarkHealthiOS

// The app target uses MainActor default isolation, so the models' synthesized
// Decodable conformances are main-actor-isolated. Run these decode tests on the
// main actor so that usage is valid (and warning-free) under the Swift 6 language mode.
@MainActor
final class ContractDecodingTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    // MARK: - CareAction (required bucket; no steps / category)

    func testCareAction_decodesNewShape_withRequiredBucket() throws {
        let json = """
        {
          "id": "ca_1",
          "carePlanId": "cp_1",
          "name": "Left-leg hamstring stretch",
          "description": "Gentle assisted stretch",
          "bucket": "MOBILITY",
          "frequency": "DAILY",
          "timeOfDay": "MORNING",
          "targetReps": 10,
          "targetDurationSeconds": null,
          "instructions": "Hold 20s, no bouncing",
          "sortOrder": 0,
          "isActive": true,
          "createdAt": "2026-06-10T08:00:00.000Z",
          "updatedAt": "2026-06-10T08:00:00.000Z"
        }
        """
        let action = try decode(CareActionRecord.self, from: json)
        XCTAssertEqual(action.id, "ca_1")
        XCTAssertEqual(action.bucket, .mobility)
        XCTAssertEqual(action.frequency, .daily)
        XCTAssertEqual(action.targetReps, 10)
        XCTAssertTrue(action.isActive)
    }

    func testCareAction_failsToDecode_whenBucketMissing() {
        // Bucket is required (context.md#CareAction). A payload without it must fail.
        let json = """
        {
          "id": "ca_2",
          "carePlanId": "cp_1",
          "name": "No-bucket action",
          "frequency": "DAILY",
          "sortOrder": 0,
          "isActive": true
        }
        """
        XCTAssertThrowsError(try decode(CareActionRecord.self, from: json))
    }

    // MARK: - DailyCareAction (unified; with source + target-vs-actual)

    func testDailyCareAction_decodesNewShape_withSourceAndActuals() throws {
        let json = """
        {
          "id": "dca_1",
          "dailyCareLogId": "log_1",
          "bucket": "ACTIVITY",
          "source": "LLM_EXTRACTED",
          "nameSnapshot": "10-minute walk",
          "descriptionSnapshot": null,
          "instructionsSnapshot": null,
          "status": "COMPLETED",
          "tolerance": "GOOD",
          "completedAt": "2026-06-10T09:00:00.000Z",
          "completedByUserId": "user_1",
          "notes": "Did great, eager the whole way",
          "targetReps": null,
          "actualReps": null,
          "targetDurationSeconds": 600,
          "actualDurationSeconds": 720,
          "careActionId": "ca_1",
          "substitutedForId": null,
          "substitutedFor": null,
          "extractionConfidence": 0.92,
          "needsReview": false,
          "sortOrder": 0,
          "completedBy": { "id": "user_1", "email": "a@b.com", "firstName": "Mario", "lastName": "Oliver" }
        }
        """
        let action = try decode(DailyCareActionRecord.self, from: json)
        XCTAssertEqual(action.source, .llmExtracted)
        XCTAssertEqual(action.bucket, .activity)
        XCTAssertEqual(action.status, .completed)
        XCTAssertEqual(action.tolerance, .good)
        XCTAssertEqual(action.targetDurationSeconds, 600)
        XCTAssertEqual(action.actualDurationSeconds, 720)
        XCTAssertEqual(action.extractionConfidence, 0.92)
        XCTAssertFalse(action.needsReview)
        XCTAssertEqual(action.completedBy?.firstName, "Mario")
    }

    func testDailyCareAction_decodesSubstitution() throws {
        let json = """
        {
          "id": "dca_2",
          "dailyCareLogId": "log_1",
          "bucket": "RECOVERY",
          "source": "PLAN_VARIATION",
          "nameSnapshot": "Cold pack (substituted)",
          "status": "COMPLETED",
          "needsReview": false,
          "sortOrder": 1,
          "substitutedForId": "dca_1",
          "substitutedFor": { "id": "dca_1", "nameSnapshot": "Laser therapy" }
        }
        """
        let action = try decode(DailyCareActionRecord.self, from: json)
        XCTAssertEqual(action.source, .planVariation)
        XCTAssertEqual(action.substitutedForId, "dca_1")
        XCTAssertEqual(action.substitutedFor?.nameSnapshot, "Laser therapy")
    }

    func testBucketPayload_groupsDailyCareActions() throws {
        let json = """
        {
          "actions": [
            {
              "id": "dca_1", "dailyCareLogId": "log_1", "bucket": "MOBILITY",
              "source": "PLAN", "nameSnapshot": "Stretch", "status": "PENDING",
              "needsReview": false, "sortOrder": 0
            }
          ],
          "observations": [],
          "progress": { "completed": 0, "total": 1 },
          "score": null
        }
        """
        let payload = try decode(BucketPayload.self, from: json)
        XCTAssertEqual(payload.actions.count, 1)
        XCTAssertEqual(payload.actions.first?.source, .plan)
        XCTAssertEqual(payload.progress?.total, 1)
    }

    // MARK: - CareAgentSession (single conversational producer; replaces the two former agents)

    func testCareAgentSession_decodesPlanBuildDraft() throws {
        let json = """
        {
          "id": "cas_1",
          "dogId": "dog_1",
          "kind": "PLAN_BUILD",
          "status": "DRAFT_READY",
          "messages": [
            { "role": "user", "content": "hip strengthening" },
            { "role": "assistant", "content": "Here is a plan" }
          ],
          "questions": [],
          "draft": {
            "proposedAction": {
              "name": "Sit-to-stand",
              "description": "Hip strengthening",
              "bucket": "ACTIVITY",
              "frequency": "DAILY",
              "timeOfDay": "MORNING",
              "targetReps": 8,
              "targetDurationSeconds": null,
              "instructions": "Slow and controlled",
              "rationale": "Builds posterior chain",
              "safetyNotes": "Stop if painful",
              "researchSummary": "Common in canine rehab"
            },
            "report": null,
            "changes": null
          },
          "voiceNoteId": null,
          "committedCarePlanId": null,
          "createdAt": "2026-06-10T09:00:00.000Z",
          "updatedAt": "2026-06-10T09:05:00.000Z"
        }
        """
        let s = try decode(CareAgentSessionPayload.self, from: json)
        XCTAssertEqual(s.kind, .planBuild)
        XCTAssertEqual(s.status, .draftReady)
        XCTAssertEqual(s.messages.count, 2)
        XCTAssertEqual(s.draft?.proposedAction?.bucket, .activity)
        XCTAssertEqual(s.draft?.proposedAction?.targetReps, 8)
        XCTAssertNil(s.draft?.report)
    }

    func testCareAgentSession_decodesPlanAuditDraft() throws {
        let json = """
        {
          "id": "cas_2",
          "dogId": "dog_1",
          "kind": "PLAN_AUDIT",
          "status": "DRAFT_READY",
          "messages": [],
          "questions": [],
          "draft": {
            "proposedAction": null,
            "report": {
              "summary": "Solid base, light on recovery",
              "strengths": ["Good activity variety"],
              "gaps": ["No recovery work"],
              "observations": [
                { "actionId": "ca_1", "actionName": "Walk", "finding": "Too long", "severity": "MEDIUM", "recommendation": "Shorten to 10 min" }
              ],
              "overallRating": "FAIR"
            },
            "changes": {
              "summary": "1 change",
              "changes": [
                {
                  "id": "chg_1",
                  "type": "UPDATE",
                  "actionId": "ca_1",
                  "actionName": "Walk",
                  "updates": { "name": null, "description": null, "bucket": "RECOVERY", "frequency": "DAILY", "timeOfDay": null, "instructions": null },
                  "newAction": null,
                  "reason": "Rebalance toward recovery"
                }
              ]
            }
          },
          "voiceNoteId": "vn_1",
          "committedCarePlanId": null,
          "createdAt": "2026-06-10T09:00:00.000Z",
          "updatedAt": "2026-06-10T09:05:00.000Z"
        }
        """
        let s = try decode(CareAgentSessionPayload.self, from: json)
        XCTAssertEqual(s.kind, .planAudit)
        XCTAssertEqual(s.draft?.report?.overallRating, "FAIR")
        XCTAssertEqual(s.draft?.report?.observations.first?.severity, "MEDIUM")
        XCTAssertEqual(s.draft?.changes?.changes.first?.updates?.bucket, "RECOVERY")
        XCTAssertEqual(s.voiceNoteId, "vn_1")
    }

    // MARK: - VoiceNote (slimmed: dumb artifact)

    func testVoiceNote_decodesSlimmedShape() throws {
        // No `extraction`, `caregiverNote`, or `needsReview` — the slimmed artifact.
        let json = """
        {
          "id": "vn_1",
          "dogId": "dog_1",
          "dailyCareLogId": "log_1",
          "userId": "user_1",
          "audioUrl": "https://example.com/a.wav",
          "transcript": "we did his stretches and a 10-minute walk",
          "processingStatus": "PROCESSED",
          "createdAt": "2026-06-10T09:00:00.000Z",
          "user": { "id": "user_1", "email": "a@b.com", "firstName": "Mario", "lastName": "Oliver" }
        }
        """
        let note = try decode(VoiceNoteRecord.self, from: json)
        XCTAssertEqual(note.transcript, "we did his stretches and a 10-minute walk")
        XCTAssertEqual(note.processingStatus, .processed)
        XCTAssertEqual(note.audioUrl, "https://example.com/a.wav")
        XCTAssertEqual(note.user.firstName, "Mario")
    }
}
