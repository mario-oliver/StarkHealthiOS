import SwiftUI

struct ExerciseAgentView: View {
    let dogId: String
    let onCommitted: () async -> Void

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var agentSession: CareAgentSessionPayload?
    @State private var input: String = ""
    @State private var busy = false
    @State private var error: String?

    private var proposedAction: ProposedCareAction? {
        agentSession?.draft?.proposedAction
    }

    private var draftReady: Bool {
        agentSession?.status == .draftReady && proposedAction != nil
    }

    private var awaitingInput: Bool {
        agentSession?.status == .awaitingInput
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                disclaimerBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                scrollArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .background(StarkTheme.background)
            .navigationTitle("Create exercise with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task { await handleCancel() }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var disclaimerBanner: some View {
        Text("This is not veterinary advice. Consult your vet before starting new rehab exercises.")
            .font(.caption)
            .foregroundStyle(StarkTheme.mutedForeground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }

    private var scrollArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if agentSession == nil {
                        Text("Describe what you want to work on — for example, hip weakness after surgery, or gentle morning stretches.")
                            .font(.subheadline)
                            .foregroundStyle(StarkTheme.mutedForeground)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    ForEach(Array((agentSession?.messages ?? []).enumerated()), id: \.offset) { _, msg in
                        chatBubble(msg)
                    }

                    if awaitingInput, let questions = agentSession?.questions, !questions.isEmpty {
                        questionsCard(questions)
                            .padding(.horizontal, 16)
                    }

                    if draftReady, let draft = proposedAction {
                        DraftPreviewView(draft: draft)
                            .padding(.horizontal, 16)
                    }

                    if busy {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Researching and drafting…")
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

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: agentSession?.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if draftReady {
                revisionField

                Button(action: { Task { await handleConfirm() } }) {
                    Text("Add to routine")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(busy)

                if !input.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: { Task { await handleStartOrSend() } }) {
                        Text("Send revision")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(StarkTheme.primary)
                    .disabled(busy)
                }
            } else {
                inputField

                Button(action: { Task { await handleStartOrSend() } }) {
                    Text(agentSession == nil ? "Start" : "Send")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || busy)
            }
        }
    }

    private var inputField: some View {
        TextField(
            agentSession == nil
                ? "e.g. My dog needs hip strengthening, 5 min daily…"
                : "Type your answer or more details…",
            text: $input,
            axis: .vertical
        )
        .lineLimit(3...6)
        .textFieldStyle(.roundedBorder)
        .disabled(busy)
        .submitLabel(.send)
        .onSubmit { Task { await handleStartOrSend() } }
    }

    private var revisionField: some View {
        TextField(
            "Ask for changes, e.g. evening instead of morning…",
            text: $input,
            axis: .vertical
        )
        .lineLimit(2...4)
        .textFieldStyle(.roundedBorder)
        .disabled(busy)
    }

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

    private func questionsCard(_ questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Please answer")
                .font(.caption)
                .textCase(.uppercase)
                .tracking(1)
                .foregroundStyle(StarkTheme.mutedForeground)

            ForEach(Array(questions.enumerated()), id: \.offset) { index, q in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(index + 1).")
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)
                    Text(q)
                        .font(.subheadline)
                }
            }
        }
        .padding(12)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(StarkTheme.border, lineWidth: 0.5)
        )
    }

    // MARK: - Actions

    private func handleStartOrSend() async {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !busy else { return }
        busy = true
        error = nil
        input = ""
        do {
            if agentSession == nil {
                agentSession = try await session.apiClient.createCareAgentSession(dogId, kind: .planBuild, message: text)
            } else {
                agentSession = try await session.apiClient.sendCareAgentMessage(dogId, sessionId: agentSession!.id, message: text)
            }
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleConfirm() async {
        guard let current = agentSession, !busy else { return }
        busy = true
        error = nil
        do {
            _ = try await session.apiClient.commitCareAgentSession(dogId, sessionId: current.id)
            dismiss()
            await onCommitted()
        } catch {
            self.error = error.localizedDescription
        }
        busy = false
    }

    private func handleCancel() async {
        if let current = agentSession, current.status != .committed {
            try? await session.apiClient.cancelCareAgentSession(dogId, sessionId: current.id)
        }
        dismiss()
    }
}

// MARK: - Draft Preview

private struct DraftPreviewView: View {
    let draft: ProposedCareAction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.name)
                    .font(.headline)

                if let desc = draft.description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }

                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)
            }

            if let instructions = draft.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Instructions")
                        .font(.caption.weight(.semibold))
                    Text(instructions)
                        .font(.caption)
                        .foregroundStyle(StarkTheme.mutedForeground)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                labeledText(label: "Why", body: draft.rationale)
                Text(draft.safetyNotes)
                    .font(.caption)
                    .foregroundStyle(.orange)
                labeledText(label: "Research", body: draft.researchSummary)
            }
        }
        .padding(14)
        .background(StarkTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(StarkTheme.border, lineWidth: 0.5)
        )
    }

    private var metaLine: String {
        var parts: [String] = [
            CareDisplay.bucketLabel(draft.bucket),
            draft.frequency.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        ]
        if let tod = draft.timeOfDay {
            parts.append(tod.rawValue.capitalized)
        }
        return parts.joined(separator: " · ")
    }

    private func labeledText(label: String, body: String) -> some View {
        Group {
            Text("\(label): ").font(.caption.weight(.semibold))
            + Text(body).font(.caption)
        }
        .foregroundStyle(StarkTheme.mutedForeground)
    }
}
