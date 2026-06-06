import SwiftUI

struct JoinView: View {
    @Environment(SessionStore.self) private var session

    @State private var step: JoinStep = .enter
    @State private var code = ""
    @State private var preview: JoinPreview?
    @State private var error: String?
    @State private var busy = false

    private enum JoinStep { case enter, confirm }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button("← Back") {
                    session.flow = session.dogs.isEmpty ? .onboarding : .dashboard
                }
                .font(.subheadline)
                .foregroundStyle(StarkTheme.primary)

                Text("Join a care log")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .textCase(.uppercase)

                Text(step == .enter ? "Enter share code" : "Confirm join")
                    .font(.title2.bold())

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                switch step {
                case .enter:
                    enterStep
                case .confirm:
                    confirmStep
                }
            }
            .padding(20)
        }
        .background(StarkTheme.background)
    }

    private var enterStep: some View {
        VStack(spacing: 16) {
            TextField("XXXX-XXXX", text: $code)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.body.monospaced())
                .textFieldStyle(.roundedBorder)

            Button(busy ? "Looking up…" : "Continue") {
                Task { await lookupCode() }
            }
            .buttonStyle(.borderedProminent)
            .tint(StarkTheme.primary)
            .frame(maxWidth: .infinity)
            .disabled(busy)
        }
    }

    private var confirmStep: some View {
        VStack(spacing: 16) {
            if let preview {
                VStack(spacing: 12) {
                    DogPhotoView(photoUrl: preview.photoUrl, name: preview.name, size: 96)
                    Text(preview.name).font(.title3.bold())
                    if let breed = preview.breed {
                        Text(breed).font(.subheadline).foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Button("Back") {
                    step = .enter
                    preview = nil
                }
                .buttonStyle(.bordered)
                Button(busy ? "Joining…" : "Join care log") {
                    Task { await join() }
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(busy)
            }
        }
    }

    private func lookupCode() async {
        let normalized = ShareCode.normalize(code)
        guard !normalized.isEmpty else {
            error = "Enter a share code."
            return
        }
        busy = true
        error = nil
        defer { busy = false }
        do {
            preview = try await session.apiClient.previewJoin(code: normalized)
            step = .confirm
        } catch {
            self.error = "Code not found. Check the code and try again."
        }
    }

    private func join() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let dog = try await session.apiClient.joinByShareCode(ShareCode.normalize(code))
            ActiveDogStore.setActiveDogId(dog.id)
            await session.completeJoin(dog: dog)
        } catch {
            self.error = "Could not join this care log. Try again."
        }
    }
}
