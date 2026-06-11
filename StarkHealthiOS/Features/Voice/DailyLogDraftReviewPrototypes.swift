// DailyLogDraftReviewPrototypes.swift
//
// THROWAWAY — Issue 0018 (Human-in-the-loop): the chosen DAILY_LOG draft-review flow.
// Mock data only, no networking. Delete this whole file once 0019 rebuilds the chosen
// interaction against the real serialized Contract (PRD-daily-log-voice-flow §Data +
// the DAILY_LOG draft shape in CareAgentDraft, which 0011 adds server-side).
//
// CHOSEN DESIGN (Mario, 2026-06-11): Triage-first — step through each heard item and
// Keep / Skip it. Two overview surfaces fold in:
//   • "View all" (a third button on each triage card) → Checklist A: the whole draft as
//     a toggle list, sharing one selection set with the triage walk.
//   • Final "Keeping N of M" page → "View" → Receipt C: a read-only receipt of what's kept.
// The plan-change nudge is inert toward the plan, but tapping "Review in plan audit"
// SAVES today's log first, then opens the (mock) plan-review screen.
// Awaiting-input / plan-change / empty run the same flow, with the Checklist overview
// reachable at the end.
//
// Paper Contract: completions / adHocActions / observations / planChangeSuggestions
// + ADR-0003 dec.3 (confirm-with-selection), dec.5 (blocked-only one question),
// dec.8 (inert plan-change nudge). Real iOS vocabulary (CareBucket, HealthObservationType).
//
// Review surface: the SwiftUI Previews + DailyLogDraftReviewHost (scenario picker).
// Build gate only — no unit tests for throwaway UI.

#if DEBUG
import SwiftUI

// MARK: - Mock draft model (throwaway mirror of the paper Contract)

private struct MockCompletion: Identifiable {
    let id: String          // stable changeId
    let nameSnapshot: String
    let bucket: CareBucket
    var actualReps: Int?
    var actualDurationSeconds: Int?
    var tolerance: String?
    let extractionConfidence: Double
    let needsReview: Bool
}

private struct MockAdHoc: Identifiable {
    let id: String
    let name: String
    let bucket: CareBucket
    var actualReps: Int?
    var actualDurationSeconds: Int?
    let extractionConfidence: Double
    let needsReview: Bool
}

private struct MockObservation: Identifiable {
    let id: String
    let type: HealthObservationType
    var severity: String?
    var bodyArea: String?
    let note: String
    let extractionConfidence: Double
    let needsReview: Bool
}

private struct MockPlanChange: Identifiable {
    let id: String
    let text: String
    let likelyAction: String
}

private struct MockDraft {
    var completions: [MockCompletion] = []
    var adHocActions: [MockAdHoc] = []
    var observations: [MockObservation] = []
    var planChangeSuggestions: [MockPlanChange] = []
    var question: MockQuestion?
    var emptyMessage: String?

    var isEmpty: Bool { completions.isEmpty && adHocActions.isEmpty && observations.isEmpty }
    var totalItems: Int { completions.count + adHocActions.count + observations.count }

    /// changeIds pre-selected: confident and not flagged. needsReview starts unchecked
    /// so a misheard line can't ride a default (ADR-0003 dec.3).
    var defaultSelection: Set<String> {
        var s = Set<String>()
        for c in completions where !c.needsReview && c.extractionConfidence >= 0.75 { s.insert(c.id) }
        for a in adHocActions where !a.needsReview && a.extractionConfidence >= 0.75 { s.insert(a.id) }
        for o in observations where !o.needsReview && o.extractionConfidence >= 0.75 { s.insert(o.id) }
        return s
    }
}

private struct MockQuestion {
    let prompt: String
    let options: [String]
}

// A flattened, render-ready item used by both the triage deck and the overview lists.
private struct DraftItem: Identifiable {
    let id: String
    let title: String
    let bucket: CareBucket?
    let detail: String?
    let needsReview: Bool
    let groupLabel: String
}

private extension MockDraft {
    var items: [DraftItem] {
        var out: [DraftItem] = []
        out += completions.map {
            DraftItem(id: $0.id, title: $0.nameSnapshot, bucket: $0.bucket,
                      detail: DraftDisplay.completionDetail($0), needsReview: $0.needsReview,
                      groupLabel: "Completed")
        }
        out += adHocActions.map {
            DraftItem(id: $0.id, title: $0.name, bucket: $0.bucket,
                      detail: DraftDisplay.adHocDetail($0), needsReview: $0.needsReview,
                      groupLabel: "Added today")
        }
        out += observations.map {
            DraftItem(id: $0.id, title: DraftDisplay.observationTitle($0.type), bucket: nil,
                      detail: DraftDisplay.observationDetail($0), needsReview: $0.needsReview,
                      groupLabel: "Health notes")
        }
        return out
    }
}

// MARK: - Scenarios

private enum DraftScenario: String, CaseIterable, Identifiable {
    case full, awaitingInput, planChange, empty
    var id: String { rawValue }
    var label: String {
        switch self {
        case .full: return "Full draft"
        case .awaitingInput: return "Awaiting input"
        case .planChange: return "Plan change"
        case .empty: return "Empty"
        }
    }
    var draft: MockDraft { DraftFixtures.draft(for: self) }
}

private enum DraftFixtures {
    static func draft(for scenario: DraftScenario) -> MockDraft {
        switch scenario {
        case .full: return full
        case .awaitingInput: return awaiting
        case .planChange: return planChangeFocused
        case .empty: return empty
        }
    }

    static let full = MockDraft(
        completions: [
            MockCompletion(id: "c1", nameSnapshot: "Hip flexor stretches", bucket: .mobility,
                           actualReps: 10, actualDurationSeconds: nil, tolerance: "Tolerated well",
                           extractionConfidence: 0.93, needsReview: false),
            MockCompletion(id: "c2", nameSnapshot: "Evening walk", bucket: .activity,
                           actualReps: nil, actualDurationSeconds: 600, tolerance: nil,
                           extractionConfidence: 0.68, needsReview: true)
        ],
        adHocActions: [
            MockAdHoc(id: "a1", name: "Backyard fetch", bucket: .activity,
                      actualReps: nil, actualDurationSeconds: nil,
                      extractionConfidence: 0.86, needsReview: false)
        ],
        observations: [
            MockObservation(id: "o1", type: .limping, severity: "mild", bodyArea: "back left leg",
                            note: "Limping a little on the back left",
                            extractionConfidence: 0.82, needsReview: false),
            MockObservation(id: "o2", type: .lowEnergy, severity: nil, bodyArea: nil,
                            note: "Seemed low energy after dinner",
                            extractionConfidence: 0.54, needsReview: true)
        ],
        planChangeSuggestions: [
            MockPlanChange(id: "p1",
                           text: "Add more reps to the hip flexor stretches going forward",
                           likelyAction: "Hip flexor stretches")
        ]
    )

    static let awaiting = MockDraft(
        observations: [
            MockObservation(id: "o1", type: .limping, severity: "mild", bodyArea: "back left leg",
                            note: "Limping a little on the back left",
                            extractionConfidence: 0.82, needsReview: false)
        ],
        question: MockQuestion(
            prompt: "You said you did “his stretches” — there are three on today's plan. Which one?",
            options: ["Hip flexor stretches", "Hamstring stretches", "Shoulder rolls"]
        )
    )

    static let planChangeFocused = MockDraft(
        completions: [
            MockCompletion(id: "c1", nameSnapshot: "Hip flexor stretches", bucket: .mobility,
                           actualReps: 15, actualDurationSeconds: nil, tolerance: "Tolerated well",
                           extractionConfidence: 0.91, needsReview: false)
        ],
        planChangeSuggestions: [
            MockPlanChange(id: "p1",
                           text: "Bump the hip flexor stretches to 15 reps every day going forward",
                           likelyAction: "Hip flexor stretches"),
            MockPlanChange(id: "p2",
                           text: "Add a second evening walk to the routine",
                           likelyAction: "Evening walk")
        ]
    )

    static let empty = MockDraft(emptyMessage: "I didn't catch any care to log in that note.")
}

// MARK: - Display helpers

private enum DraftDisplay {
    static func observationTitle(_ type: HealthObservationType) -> String {
        switch type {
        case .slipping: return "Slipping"
        case .limping: return "Limping"
        case .weakness: return "Weakness"
        case .stiffness: return "Stiffness"
        case .pain: return "Pain"
        case .lowEnergy: return "Low energy"
        case .appetite: return "Appetite"
        case .bathroom: return "Bathroom"
        case .medication: return "Medication"
        case .generalNote: return "Note"
        }
    }
    static func completionDetail(_ c: MockCompletion) -> String? {
        detail(reps: c.actualReps, seconds: c.actualDurationSeconds, extra: c.tolerance)
    }
    static func adHocDetail(_ a: MockAdHoc) -> String? {
        detail(reps: a.actualReps, seconds: a.actualDurationSeconds, extra: nil)
    }
    static func observationDetail(_ o: MockObservation) -> String {
        var parts: [String] = []
        if let area = o.bodyArea { parts.append(area) }
        if let sev = o.severity { parts.append(sev) }
        return parts.isEmpty ? o.note : (parts.joined(separator: " · ") + " — " + o.note)
    }
    private static func detail(reps: Int?, seconds: Int?, extra: String?) -> String? {
        var parts: [String] = []
        if let reps { parts.append("\(reps) reps") }
        if let seconds { parts.append("\(seconds / 60) min") }
        if let extra { parts.append(extra) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

private struct ReviewChip: View {
    var body: some View {
        Text("Double-check")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }
}

private struct BucketChip: View {
    let bucket: CareBucket
    var body: some View {
        Text(CareDisplay.bucketLabel(bucket))
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(StarkTheme.primary.opacity(0.12))
            .foregroundStyle(StarkTheme.primary)
            .clipShape(Capsule())
    }
}

// MARK: - Chosen flow (Triage-first, with Checklist + Receipt overviews)

private enum FlowStage { case question, deck, summary, planAudit }

struct DailyLogDraftReviewFlow: View {
    fileprivate let draft: MockDraft
    fileprivate let scenario: DraftScenario

    @State private var stage: FlowStage
    @State private var index = 0
    @State private var selected: Set<String>
    @State private var showChecklist = false
    @State private var showReceipt = false
    @State private var committed = false

    fileprivate init(draft: MockDraft, scenario: DraftScenario) {
        self.draft = draft
        self.scenario = scenario
        _selected = State(initialValue: draft.defaultSelection)
        _stage = State(initialValue: draft.question != nil ? .question : .deck)
    }

    private var deck: [DraftItem] { draft.items }
    private var keptCount: Int { selected.intersection(Set(deck.map(\.id))).count }

    var body: some View {
        Group {
            if draft.isEmpty && draft.question == nil {
                EmptyDraftView(message: draft.emptyMessage)
            } else {
                switch stage {
                case .question: questionStage
                case .deck: deckStage
                case .summary: summaryStage
                case .planAudit: MockPlanAuditScreen(savedCount: keptCount) { stage = .summary }
                }
            }
        }
        .overlay { if committed { CommittedOverlay(count: keptCount) } }
        .sheet(isPresented: $showChecklist) {
            ChecklistOverviewSheet(draft: draft, selected: $selected)
        }
        .sheet(isPresented: $showReceipt) {
            ReceiptSummarySheet(draft: draft, keptIds: selected)
        }
        .animation(.easeOut(duration: 0.2), value: index)
        .animation(.easeOut(duration: 0.2), value: stage)
    }

    // Stage 1 — one blocking question (AWAITING_INPUT)
    private var questionStage: some View {
        VStack(spacing: 16) {
            header(title: "Review what I heard", subtitle: "One quick thing first")
            QuestionCard(question: draft.question!, style: .card) {
                stage = deck.isEmpty ? .summary : .deck
            }
            Spacer()
        }
        .padding()
    }

    // Stage 2 — triage one item at a time
    private var deckStage: some View {
        VStack(spacing: 20) {
            header(title: "Review what I heard",
                   subtitle: deck.isEmpty ? " " : "Item \(min(index + 1, deck.count)) of \(deck.count)")
            if index < deck.count {
                triageCard(deck[index])
                HStack(spacing: 14) {
                    triageButton(systemImage: "xmark", label: "Skip", tint: .secondary) {
                        selected.remove(deck[index].id); index += 1; settleStage()
                    }
                    triageButton(systemImage: "checkmark", label: "Keep", tint: StarkTheme.primary) {
                        selected.insert(deck[index].id); index += 1; settleStage()
                    }
                }
                // Third option: jump to the whole draft as a checklist.
                Button { showChecklist = true } label: {
                    Label("View all", systemImage: "list.bullet")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StarkTheme.border))
                }
                .buttonStyle(.plain)
                .foregroundStyle(StarkTheme.primary)
            }
            Spacer()
        }
        .padding()
    }

    private func settleStage() { if index >= deck.count { stage = .summary } }

    // Stage 3 — summary + overviews + plan-change (save-first) + save
    private var summaryStage: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "checklist").font(.largeTitle).foregroundStyle(StarkTheme.primary)
                    Text("Keeping \(keptCount) of \(deck.count)").font(.title2.bold())
                }
                .padding(.top, 12)

                // Review-everything surface: receipt for full draft, checklist for the rest.
                if scenario == .full {
                    overviewButton(title: "View what I'm saving", systemImage: "doc.text") {
                        showReceipt = true
                    }
                } else if !deck.isEmpty {
                    overviewButton(title: "View all in checklist", systemImage: "list.bullet") {
                        showChecklist = true
                    }
                }

                ForEach(draft.planChangeSuggestions) { p in
                    PlanChangeNudge(suggestion: p) {
                        // Save today's log BEFORE leaving for the plan-review screen.
                        committed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            committed = false
                            stage = .planAudit
                        }
                    }
                }

                Button { committed = true } label: {
                    Text(keptCount == 0 ? "Nothing selected" : "Save \(keptCount) to today's log")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(keptCount == 0 ? Color.gray.opacity(0.3) : StarkTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(keptCount == 0)
                .padding(.top, 4)
            }
            .padding()
        }
    }

    // Shared pieces
    private func header(title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
        }
    }

    private func triageCard(_ item: DraftItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(item.groupLabel.uppercased())
                    .font(.caption2.weight(.bold)).foregroundStyle(StarkTheme.primary)
                if item.needsReview { ReviewChip() }
            }
            Text(item.title).font(.title2.bold())
            if let bucket = item.bucket { BucketChip(bucket: bucket) }
            if let detail = item.detail {
                Text(detail).font(.body).foregroundStyle(StarkTheme.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .padding(24)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private func triageButton(systemImage: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title2.weight(.semibold))
                Text(label).font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity).frame(height: 72)
            .background(tint.opacity(0.12)).foregroundStyle(tint)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func overviewButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .font(.subheadline.weight(.medium))
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(StarkTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .foregroundStyle(StarkTheme.foreground)
    }
}

// MARK: - "View all" → Checklist A overview (shared selection)

private struct ChecklistOverviewSheet: View {
    let draft: MockDraft
    @Binding var selected: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    group("Completed", "checkmark.circle", draft.completions.map {
                        ($0.id, $0.nameSnapshot, $0.bucket as CareBucket?, DraftDisplay.completionDetail($0), $0.needsReview)
                    })
                    group("Added today", "plus.circle", draft.adHocActions.map {
                        ($0.id, $0.name, $0.bucket as CareBucket?, DraftDisplay.adHocDetail($0), $0.needsReview)
                    })
                    group("Health notes", "stethoscope", draft.observations.map {
                        ($0.id, DraftDisplay.observationTitle($0.type), nil as CareBucket?, DraftDisplay.observationDetail($0), $0.needsReview)
                    })
                }
                .padding()
            }
            .navigationTitle("All items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func group(_ title: String, _ icon: String,
                       _ rows: [(String, String, CareBucket?, String?, Bool)]) -> some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(StarkTheme.mutedForeground)
                ForEach(rows, id: \.0) { row in
                    checkRow(id: row.0, title: row.1, bucket: row.2, detail: row.3, needsReview: row.4)
                }
            }
        }
    }

    private func checkRow(id: String, title: String, bucket: CareBucket?, detail: String?, needsReview: Bool) -> some View {
        let on = selected.contains(id)
        return Button {
            if on { selected.remove(id) } else { selected.insert(id) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: on ? "checkmark.square.fill" : "square")
                    .font(.title3).foregroundStyle(on ? StarkTheme.primary : StarkTheme.mutedForeground)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.body.weight(.medium)).foregroundStyle(StarkTheme.foreground)
                        if let bucket { BucketChip(bucket: bucket) }
                        if needsReview { ReviewChip() }
                    }
                    if let detail { Text(detail).font(.caption).foregroundStyle(StarkTheme.mutedForeground) }
                }
                Spacer(minLength: 0)
            }
            .padding(12).background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - "View" → Receipt C of what's kept (read-only)

private struct ReceiptSummarySheet: View {
    let draft: MockDraft
    let keptIds: Set<String>
    @Environment(\.dismiss) private var dismiss

    private var keptItems: [DraftItem] { draft.items.filter { keptIds.contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Saving \(keptItems.count) item\(keptItems.count == 1 ? "" : "s") to today's log")
                        .font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)
                        .padding(.top, 4)
                    ForEach(["Completed", "Added today", "Health notes"], id: \.self) { groupLabel in
                        let rows = keptItems.filter { $0.groupLabel == groupLabel }
                        if !rows.isEmpty { section(groupLabel, rows) }
                    }
                    if keptItems.isEmpty {
                        Text("Nothing selected yet.").font(.body).foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func section(_ title: String, _ rows: [DraftItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased()).font(.caption2.weight(.bold))
                .foregroundStyle(StarkTheme.mutedForeground).padding(.bottom, 6)
            ForEach(Array(rows.enumerated()), id: \.element.id) { i, item in
                HStack(spacing: 10) {
                    if item.needsReview { Circle().fill(.orange).frame(width: 7, height: 7) }
                    else { Circle().fill(.clear).frame(width: 7, height: 7) }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.body.weight(.medium))
                        if let detail = item.detail {
                            Text(detail).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
                if i < rows.count - 1 { Divider() }
            }
        }
        .padding(14).background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Mock plan-audit destination (reached only after the log is saved)

private struct MockPlanAuditScreen: View {
    let savedCount: Int
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(StarkTheme.primary)
                    Text("Saved \(savedCount) to today's log")
                        .font(.subheadline.weight(.medium))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(StarkTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Plan review").font(.title2.bold())
                Text("You mentioned a change to the ongoing plan. Today's log is already saved — this is where you'd review and apply the change (mock; a PLAN_AUDIT session).")
                    .font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Hip flexor stretches", systemImage: "figure.strengthtraining.functional")
                        .font(.body.weight(.medium))
                    Text("Proposed: 10 → 15 reps daily").font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 14))

                Button(action: onBack) {
                    Text("Back").font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StarkTheme.border))
                }
                .buttonStyle(.plain).foregroundStyle(StarkTheme.primary)
            }
            .padding()
        }
    }
}

// MARK: - Shared sub-views

private enum QuestionStyle { case panel, card, inlineReceipt }

private struct QuestionCard: View {
    let question: MockQuestion
    var style: QuestionStyle = .panel
    var onAnswer: (() -> Void)? = nil
    @State private var picked: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("One quick question", systemImage: "questionmark.bubble")
                .font(.caption.weight(.semibold)).foregroundStyle(StarkTheme.primary)
            Text(question.prompt).font(.body.weight(.medium))
            VStack(spacing: 8) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        picked = option
                        onAnswer?()
                    } label: {
                        HStack {
                            Text(option); Spacer()
                            if picked == option { Image(systemName: "checkmark") }
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(picked == option ? StarkTheme.primary.opacity(0.15) : StarkTheme.background)
                        .foregroundStyle(StarkTheme.foreground)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(StarkTheme.border))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(style == .inlineReceipt ? StarkTheme.primary.opacity(0.06) : StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(StarkTheme.primary.opacity(style == .card ? 0.4 : 0.15), lineWidth: 1))
    }
}

private struct PlanChangeNudge: View {
    let suggestion: MockPlanChange
    var onReview: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Plan change noticed", systemImage: "lightbulb")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.orange)
            Text(suggestion.text).font(.subheadline)
            Text("Not saved to today. Reviewing saves your log first, then opens the plan.")
                .font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            Button { onReview?() } label: {
                Text("Save log & review plan")
                    .font(.caption.weight(.semibold)).foregroundStyle(StarkTheme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.25)))
    }
}

private struct EmptyDraftView: View {
    let message: String?
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "mic.slash").font(.largeTitle).foregroundStyle(StarkTheme.mutedForeground)
            Text(message ?? "I didn't catch any care to log.")
                .font(.body).foregroundStyle(StarkTheme.mutedForeground).multilineTextAlignment(.center)
            Text("Nothing was saved — try recording again.")
                .font(.caption).foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CommittedOverlay: View {
    let count: Int
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(StarkTheme.primary)
            Text("Saved \(count) to today's log").font(.headline)
            Text("(mock — no data written)").font(.caption).foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding(32).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Dev host (scenario picker over the chosen flow)

struct DailyLogDraftReviewHost: View {
    @State private var scenario: DraftScenario = .full

    var body: some View {
        VStack(spacing: 0) {
            Picker("Scenario", selection: $scenario) {
                ForEach(DraftScenario.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(StarkTheme.background)

            Divider()

            DailyLogDraftReviewFlow(draft: scenario.draft, scenario: scenario)
                .id(scenario.rawValue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Previews (primary review surface)

#Preview("Host · scenario picker") { DailyLogDraftReviewHost() }

#Preview("Full draft — triage") { DailyLogDraftReviewFlow(draft: DraftScenario.full.draft, scenario: .full) }
#Preview("Awaiting input — triage") { DailyLogDraftReviewFlow(draft: DraftScenario.awaitingInput.draft, scenario: .awaitingInput) }
#Preview("Plan change — triage") { DailyLogDraftReviewFlow(draft: DraftScenario.planChange.draft, scenario: .planChange) }
#Preview("Empty — nothing to log") { DailyLogDraftReviewFlow(draft: DraftScenario.empty.draft, scenario: .empty) }

#Preview("Checklist overview (View all)") {
    ChecklistOverviewSheet(draft: DraftScenario.full.draft, selected: .constant(DraftScenario.full.draft.defaultSelection))
}
#Preview("Receipt of what's kept (View)") {
    ReceiptSummarySheet(draft: DraftScenario.full.draft, keptIds: DraftScenario.full.draft.defaultSelection)
}
#Preview("Plan review (after save)") {
    MockPlanAuditScreen(savedCount: 3) {}
}

#endif
