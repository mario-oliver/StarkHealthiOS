import SwiftUI

// The DAILY_LOG draft-review + confirm flow (issue 0019), implementing the design
// chosen in 0018: a Triage spine (Keep / Skip each heard item) with two overview
// surfaces folded in — "View all" → a Checklist of the whole draft (shared selection),
// and the summary's "View" → a read-only Receipt of what's kept. The inert plan-change
// nudge saves today's log first, then opens the (stubbed) plan-review (ADR-0003 dec.8).
// Driven by DailyLogReviewViewModel against the real serialized Contract.

struct DailyLogReviewView: View {
    @State private var vm: DailyLogReviewViewModel
    private let onClose: () -> Void

    init(vm: DailyLogReviewViewModel, onClose: @escaping () -> Void = {}) {
        _vm = State(initialValue: vm)
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Daily log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close", action: onClose) }
                }
        }
        .task { await vm.startIfNeeded() }
    }

    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading:
            VStack(spacing: 14) {
                ProgressView()
                Text("Reading your note…").font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .awaitingInput(let question):
            AwaitingInputView(question: question, answering: { await vm.answer($0) })
        case .review:
            DailyLogTriageFlow(vm: vm)
        case .empty(let message):
            EmptyDraftView(message: message)
        case .committed(let count):
            CommittedView(count: count, onDone: onClose)
        case .failed(let message):
            FailedView(message: message, onRetry: { await vm.start() }, onClose: onClose)
        }
    }
}

// MARK: - Triage spine + overviews

private struct DailyLogTriageFlow: View {
    @Bindable var vm: DailyLogReviewViewModel

    private enum Stage { case deck, summary, planAudit }
    @State private var stage: Stage = .deck
    @State private var index = 0
    @State private var showChecklist = false
    @State private var showReceipt = false

    private var items: [ReviewItem] { vm.draft.reviewItems }
    private var keptCount: Int { vm.confirmChangeIds.count }

    var body: some View {
        Group {
            switch stage {
            case .deck: deck
            case .summary: summary
            case .planAudit: PlanReviewStub(savedCount: keptCount) { stage = .summary }
            }
        }
        .sheet(isPresented: $showChecklist) { ChecklistOverviewSheet(items: items, vm: vm) }
        .sheet(isPresented: $showReceipt) {
            ReceiptSummarySheet(items: items.filter { vm.selected.contains($0.id) })
        }
        .animation(.easeOut(duration: 0.2), value: index)
        .animation(.easeOut(duration: 0.2), value: stage)
    }

    private var deck: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Review what I heard").font(.headline)
                Text(items.isEmpty ? " " : "Item \(min(index + 1, items.count)) of \(items.count)")
                    .font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            }
            if index < items.count {
                TriageCard(item: items[index])
                HStack(spacing: 14) {
                    TriageActionButton(systemImage: "xmark", label: "Skip", tint: .secondary) {
                        vm.selected.remove(items[index].id); advance()
                    }
                    TriageActionButton(systemImage: "checkmark", label: "Keep", tint: StarkTheme.primary) {
                        vm.selected.insert(items[index].id); advance()
                    }
                }
                Button { showChecklist = true } label: {
                    Label("View all", systemImage: "list.bullet")
                        .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StarkTheme.border))
                }
                .buttonStyle(.plain).foregroundStyle(StarkTheme.primary)
            }
            Spacer()
        }
        .padding()
    }

    private func advance() { index += 1; if index >= items.count { stage = .summary } }

    private var summary: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "checklist").font(.largeTitle).foregroundStyle(StarkTheme.primary)
                    Text("Keeping \(keptCount) of \(items.count)").font(.title2.bold())
                }
                .padding(.top, 12)

                OverviewButton(title: "View what I'm saving", systemImage: "doc.text") { showReceipt = true }
                OverviewButton(title: "View all in checklist", systemImage: "list.bullet") { showChecklist = true }

                ForEach(Array(vm.draft.planChangeSuggestions.enumerated()), id: \.offset) { _, p in
                    PlanChangeNudge(suggestion: p) {
                        // Save today's log BEFORE leaving for the plan-review screen.
                        await vm.commit()
                        stage = .planAudit
                    }
                }

                Button { Task { await vm.commit() } } label: {
                    Text(keptCount == 0 ? "Nothing selected" : "Save \(keptCount) to today's log")
                        .font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(keptCount == 0 ? Color.gray.opacity(0.3) : StarkTheme.primary)
                        .foregroundStyle(.white).clipShape(Capsule())
                }
                .disabled(keptCount == 0 || vm.committing)
                .padding(.top, 4)
            }
            .padding()
        }
    }
}

// MARK: - Flattened review item + display helpers

private struct ReviewItem: Identifiable {
    let id: String          // changeId
    let title: String
    let bucket: CareBucket?
    let detail: String?
    let needsReview: Bool
    let groupLabel: String
}

private extension DailyLogDraft {
    var reviewItems: [ReviewItem] {
        var out: [ReviewItem] = []
        out += completions.map {
            ReviewItem(id: $0.changeId, title: $0.nameSnapshot, bucket: $0.bucket,
                       detail: DailyLogDisplay.actuals(reps: $0.actualReps, seconds: $0.actualDurationSeconds,
                                                       tolerance: $0.tolerance),
                       needsReview: $0.needsReview, groupLabel: "Completed")
        }
        out += adHocActions.map {
            ReviewItem(id: $0.changeId, title: $0.name, bucket: $0.bucket,
                       detail: DailyLogDisplay.actuals(reps: $0.actualReps, seconds: $0.actualDurationSeconds,
                                                       tolerance: nil),
                       needsReview: $0.needsReview, groupLabel: "Added today")
        }
        out += observations.map {
            ReviewItem(id: $0.changeId, title: DailyLogDisplay.observationTitle($0.type), bucket: nil,
                       detail: DailyLogDisplay.observationDetail(severity: $0.severity, bodyArea: $0.bodyArea, note: $0.note),
                       needsReview: $0.needsReview, groupLabel: "Health notes")
        }
        return out
    }
}

private enum DailyLogDisplay {
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
    static func actuals(reps: Int?, seconds: Int?, tolerance: Tolerance?) -> String? {
        var parts: [String] = []
        if let reps { parts.append("\(reps) reps") }
        if let seconds { parts.append("\(seconds / 60) min") }
        if let tolerance, tolerance != .unknown { parts.append(tolerance.rawValue.capitalized) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
    static func observationDetail(severity: ObservationSeverity?, bodyArea: String?, note: String) -> String {
        var parts: [String] = []
        if let bodyArea { parts.append(bodyArea) }
        if let severity, severity != .unknown { parts.append(severity.rawValue.capitalized) }
        return parts.isEmpty ? note : (parts.joined(separator: " · ") + " — " + note)
    }
}

// MARK: - Sheets & shared components

private struct ChecklistOverviewSheet: View {
    let items: [ReviewItem]
    @Bindable var vm: DailyLogReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(["Completed", "Added today", "Health notes"], id: \.self) { label in
                        let rows = items.filter { $0.groupLabel == label }
                        if !rows.isEmpty { group(label, rows) }
                    }
                }
                .padding()
            }
            .navigationTitle("All items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func group(_ title: String, _ rows: [ReviewItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(StarkTheme.mutedForeground)
            ForEach(rows) { item in
                let on = vm.selected.contains(item.id)
                Button { vm.toggle(item.id) } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: on ? "checkmark.square.fill" : "square")
                            .font(.title3).foregroundStyle(on ? StarkTheme.primary : StarkTheme.mutedForeground)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(item.title).font(.body.weight(.medium)).foregroundStyle(StarkTheme.foreground)
                                if let bucket = item.bucket { BucketChip(bucket: bucket) }
                                if item.needsReview { ReviewChip() }
                            }
                            if let detail = item.detail {
                                Text(detail).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12).background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ReceiptSummarySheet: View {
    let items: [ReviewItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Saving \(items.count) item\(items.count == 1 ? "" : "s") to today's log")
                        .font(.subheadline).foregroundStyle(StarkTheme.mutedForeground).padding(.top, 4)
                    ForEach(["Completed", "Added today", "Health notes"], id: \.self) { label in
                        let rows = items.filter { $0.groupLabel == label }
                        if !rows.isEmpty { section(label, rows) }
                    }
                    if items.isEmpty {
                        Text("Nothing selected yet.").font(.body).foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func section(_ title: String, _ rows: [ReviewItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased()).font(.caption2.weight(.bold))
                .foregroundStyle(StarkTheme.mutedForeground).padding(.bottom, 6)
            ForEach(Array(rows.enumerated()), id: \.element.id) { i, item in
                HStack(spacing: 10) {
                    Circle().fill(item.needsReview ? Color.orange : .clear).frame(width: 7, height: 7)
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

private struct TriageCard: View {
    let item: ReviewItem
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(item.groupLabel.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(StarkTheme.primary)
                if item.needsReview { ReviewChip() }
            }
            Text(item.title).font(.title2.bold())
            if let bucket = item.bucket { BucketChip(bucket: bucket) }
            if let detail = item.detail {
                Text(detail).font(.body).foregroundStyle(StarkTheme.mutedForeground)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .padding(24).background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

private struct TriageActionButton: View {
    let systemImage: String
    let label: String
    let tint: Color
    let action: () -> Void
    var body: some View {
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
}

private struct OverviewButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Image(systemName: "chevron.right").font(.caption)
            }
            .font(.subheadline.weight(.medium)).padding(14).frame(maxWidth: .infinity)
            .background(StarkTheme.card).clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain).foregroundStyle(StarkTheme.foreground)
    }
}

private struct AwaitingInputView: View {
    let question: String
    let answering: (String) async -> Void
    @State private var picked: String?
    // The clarifying round offers free-text in the real flow; here we send the question's
    // own phrasing back as a single answer affordance plus a text field.
    @State private var typed = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("One quick question", systemImage: "questionmark.bubble")
                .font(.caption.weight(.semibold)).foregroundStyle(StarkTheme.primary)
            Text(question).font(.title3.weight(.medium))
            TextField("Type your answer", text: $typed, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button {
                let answer = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !answer.isEmpty else { return }
                Task { await answering(answer) }
            } label: {
                Text("Send").font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(StarkTheme.primary).foregroundStyle(.white).clipShape(Capsule())
            }
            .disabled(typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer()
        }
        .padding()
    }
}

private struct PlanChangeNudge: View {
    let suggestion: DailyLogPlanChangeSuggestion
    let onReview: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Plan change noticed", systemImage: "lightbulb")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.orange)
            Text(suggestion.text).font(.subheadline)
            Text("Not saved to today. Reviewing saves your log first, then opens the plan.")
                .font(.caption).foregroundStyle(StarkTheme.mutedForeground)
            Button { Task { await onReview() } } label: {
                Text("Save log & review plan").font(.caption.weight(.semibold)).foregroundStyle(StarkTheme.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.25)))
    }
}

private struct PlanReviewStub: View {
    let savedCount: Int
    let onBack: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(StarkTheme.primary)
                    Text("Saved \(savedCount) to today's log").font(.subheadline.weight(.medium))
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(StarkTheme.primary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Plan review").font(.title2.bold())
                Text("You mentioned a change to the ongoing plan. Today's log is already saved — the plan-review handoff (PLAN_AUDIT) lands in a later task.")
                    .font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)

                Button(action: onBack) {
                    Text("Back").font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StarkTheme.border))
                }
                .buttonStyle(.plain).foregroundStyle(StarkTheme.primary)
            }
            .padding()
        }
    }
}

private struct EmptyDraftView: View {
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "mic.slash").font(.largeTitle).foregroundStyle(StarkTheme.mutedForeground)
            Text(message).font(.body).foregroundStyle(StarkTheme.mutedForeground).multilineTextAlignment(.center)
            Text("Nothing was saved — try recording again.").font(.caption).foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CommittedView: View {
    let count: Int
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(StarkTheme.primary)
            Text("Saved \(count) to today's log").font(.headline)
            Button("Done", action: onDone).font(.body.weight(.semibold)).padding(.top, 4)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FailedView: View {
    let message: String
    let onRetry: () async -> Void
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text("Couldn't read your note").font(.headline)
            Text(message).font(.caption).foregroundStyle(StarkTheme.mutedForeground).multilineTextAlignment(.center)
            Button { Task { await onRetry() } } label: {
                Text("Try again").font(.body.weight(.semibold)).padding(.horizontal, 24).padding(.vertical, 12)
                    .background(StarkTheme.primary).foregroundStyle(.white).clipShape(Capsule())
            }
            Button("Close", action: onClose).font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)
        }
        .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ReviewChip: View {
    var body: some View {
        Text("Double-check").font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(Color.orange.opacity(0.15)).foregroundStyle(.orange).clipShape(Capsule())
    }
}

private struct BucketChip: View {
    let bucket: CareBucket
    var body: some View {
        Text(CareDisplay.bucketLabel(bucket)).font(.caption2.weight(.medium))
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(StarkTheme.primary.opacity(0.12)).foregroundStyle(StarkTheme.primary).clipShape(Capsule())
    }
}
