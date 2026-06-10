import SwiftUI

struct ProgramAuditView: View {
    let dogId: String
    let onCommitted: () async -> Void

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var auditSession: CareAgentSessionPayload?
    @State private var input: String = ""
    @State private var busy = false
    @State private var error: String?
    @State private var selectedChangeIds: Set<String> = []

    private var status: CareAgentSessionStatus? { auditSession?.status }
    private var report: AuditReport? { auditSession?.draft?.report }
    private var plan: ProposedProgramChanges? { auditSession?.draft?.changes }
    private var isLoading: Bool { busy && auditSession == nil }
    // The unified CareAgentSession exposes a single `draft`; phase is derived from its
    // contents. Proposed changes ready to apply takes precedence over the report view.
    private var isPlanReady: Bool { plan != nil && status == .draftReady }
    private var isReportReady: Bool { report != nil && plan == nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else {
                    scrollArea
                    bottomBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
            .background(StarkTheme.background)
            .navigationTitle("Audit program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { Task { await handleCancel() } }
                }
            }
            .task { await startAudit() }
        }
    }

    // MARK: - Loading state

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing your program…")
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scroll area

    private var scrollArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    // Vet disclaimer
                    Text("This is not veterinary advice. Consult your vet before making changes to your dog's care.")
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Audit report
                    if let report {
                        AuditReportView(report: report)
                            .padding(.horizontal, 16)
                    }

                    // Chat transcript
                    ForEach(Array((auditSession?.messages ?? []).enumerated()), id: \.offset) { _, msg in
                        chatBubble(msg)
                    }

                    // Proposed changes
                    if isPlanReady, let plan {
                        ProposedChangesView(
                            plan: plan,
                            selectedIds: $selectedChangeIds
                        )
                        .padding(.horizontal, 16)
                    }

                    if busy {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.8)
                            Text("Thinking…")
                                .font(.subheadline)
                                .foregroundStyle(StarkTheme.mutedForeground)
                        }
                        .padding(.horizontal, 16)
                    }

                    if let error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: auditSession?.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: plan?.changes.count) { _, _ in
                // Pre-select all proposed changes when plan first appears
                if let changes = plan?.changes {
                    selectedChangeIds = Set(changes.map(\.id))
                }
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 10) {
            if isPlanReady {
                // Revision field
                TextField(
                    "Ask for different changes or more detail…",
                    text: $input,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .disabled(busy)

                if !input.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: { Task { await handleSend() } }) {
                        Text("Send revision").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(StarkTheme.primary)
                    .disabled(busy)
                }

                // Apply selected changes button
                let selectedCount = selectedChangeIds.count
                Button(action: { Task { await handleConfirm() } }) {
                    Text(selectedCount == 0
                         ? "Select changes to apply"
                         : "Apply \(selectedCount) change\(selectedCount == 1 ? "" : "s")")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(busy || selectedCount == 0)

            } else if isReportReady {
                // Conversation input
                TextField(
                    "Ask a question or say what to improve…",
                    text: $input,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .disabled(busy)
                .onSubmit { Task { await handleSend() } }

                HStack(spacing: 10) {
                    // Quick-action: propose changes directly
                    Button(action: { Task { await handleProposeChanges() } }) {
                        Text("Propose changes").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(StarkTheme.primary)
                    .disabled(busy)

                    Button(action: { Task { await handleSend() } }) {
                        Text("Send").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(StarkTheme.primary)
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || busy)
                }

            } else if status == .failed {
                Button(action: { Task { await startAudit() } }) {
                    Text("Try again").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
            }
        }
    }

    // MARK: - Chat bubble

    @ViewBuilder
    private func chatBubble(_ msg: CareAgentMessage) -> some View {
        let isUser = msg.role == "user"
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(msg.content)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isUser ? StarkTheme.primary : StarkTheme.card)
                .foregroundStyle(isUser ? Color.white : StarkTheme.foreground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func startAudit() async {
        guard auditSession == nil else { return }
        busy = true
        error = nil
        do {
            auditSession = try await session.apiClient.createCareAgentSession(dogId, kind: .planAudit, message: nil)
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleSend() async {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !busy, let current = auditSession else { return }
        busy = true
        error = nil
        input = ""
        do {
            auditSession = try await session.apiClient.sendCareAgentMessage(dogId, sessionId: current.id, message: text)
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleProposeChanges() async {
        guard !busy, let current = auditSession else { return }
        busy = true
        error = nil
        do {
            auditSession = try await session.apiClient.sendCareAgentMessage(
                dogId,
                sessionId: current.id,
                message: "Based on this analysis, please propose specific changes to improve the program."
            )
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleConfirm() async {
        guard let current = auditSession, !busy else { return }
        busy = true
        error = nil
        do {
            _ = try await session.apiClient.commitCareAgentSession(
                dogId,
                sessionId: current.id,
                selectedChangeIds: Array(selectedChangeIds)
            )
            dismiss()
            await onCommitted()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleCancel() async {
        if let current = auditSession, current.status != .committed {
            try? await session.apiClient.cancelCareAgentSession(dogId, sessionId: current.id)
        }
        dismiss()
    }
}

// MARK: - Audit Report Card

private struct AuditReportView: View {
    let report: AuditReport

    private var ratingColor: Color {
        switch report.overallRating {
        case "GOOD": return .green
        case "FAIR": return .orange
        default: return .red
        }
    }

    private var ratingLabel: String {
        switch report.overallRating {
        case "GOOD": return "Good"
        case "FAIR": return "Fair"
        default: return "Needs work"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rating badge + title
            HStack(spacing: 8) {
                Text(ratingLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(ratingColor.opacity(0.15))
                    .foregroundStyle(ratingColor)
                    .clipShape(Capsule())

                Text("Program Analysis")
                    .font(.headline)
            }

            Text(report.summary)
                .font(.subheadline)
                .foregroundStyle(StarkTheme.foreground)

            if !report.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Strengths", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    ForEach(report.strengths, id: \.self) { s in
                        Text("• \(s)")
                            .font(.caption)
                            .foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
            }

            if !report.gaps.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Areas to improve", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                    ForEach(report.gaps, id: \.self) { g in
                        Text("• \(g)")
                            .font(.caption)
                            .foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
            }

            if !report.observations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Exercise notes")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(StarkTheme.mutedForeground)

                    ForEach(report.observations, id: \.actionId) { obs in
                        AuditObservationRow(observation: obs)
                    }
                }
            }
        }
        .padding(14)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StarkTheme.border, lineWidth: 0.5))
    }
}

private struct AuditObservationRow: View {
    let observation: AuditObservation

    private var severityColor: Color {
        switch observation.severity {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        default: return .yellow
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 7, height: 7)
                Text(observation.actionName)
                    .font(.caption.weight(.semibold))
            }
            Text(observation.finding)
                .font(.caption)
                .foregroundStyle(StarkTheme.mutedForeground)
            Text(observation.recommendation)
                .font(.caption)
                .foregroundStyle(StarkTheme.foreground)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Proposed Changes List

private struct ProposedChangesView: View {
    let plan: ProposedProgramChanges
    @Binding var selectedIds: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Proposed changes")
                .font(.headline)

            Text(plan.summary)
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)

            Text("Select the changes you want to apply:")
                .font(.caption)
                .foregroundStyle(StarkTheme.mutedForeground)

            ForEach(plan.changes) { change in
                ProposedChangeCard(
                    change: change,
                    isSelected: selectedIds.contains(change.id),
                    onToggle: {
                        if selectedIds.contains(change.id) {
                            selectedIds.remove(change.id)
                        } else {
                            selectedIds.insert(change.id)
                        }
                    }
                )
            }
        }
    }
}

private struct ProposedChangeCard: View {
    let change: ProposedChange
    let isSelected: Bool
    let onToggle: () -> Void

    private var typeBadgeColor: Color {
        switch change.type {
        case "CREATE": return .green
        case "DEACTIVATE": return .red
        default: return StarkTheme.primary
        }
    }

    private var typeLabel: String {
        switch change.type {
        case "CREATE": return "Add"
        case "DEACTIVATE": return "Remove"
        default: return "Update"
        }
    }

    private var exerciseName: String {
        change.actionName ?? change.newAction?.name ?? "Exercise"
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? StarkTheme.primary : StarkTheme.mutedForeground)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(typeLabel)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(typeBadgeColor.opacity(0.15))
                            .foregroundStyle(typeBadgeColor)
                            .clipShape(Capsule())

                        Text(exerciseName)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }

                    Text(change.reason)
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)

                    // Show update fields if present
                    if let updates = change.updates {
                        let fields = changedFields(from: updates)
                        if !fields.isEmpty {
                            Text(fields.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundStyle(StarkTheme.mutedForeground)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                isSelected
                    ? StarkTheme.primary.opacity(0.06)
                    : StarkTheme.card
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? StarkTheme.primary.opacity(0.4) : StarkTheme.border,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func changedFields(from u: ProposedChangeUpdates) -> [String] {
        var parts: [String] = []
        if let f = u.frequency { parts.append(f.replacingOccurrences(of: "_", with: " ").capitalized) }
        if let t = u.timeOfDay { parts.append(t.capitalized) }
        if let b = u.bucket { parts.append(b.replacingOccurrences(of: "_", with: " ").capitalized) }
        return parts
    }
}
