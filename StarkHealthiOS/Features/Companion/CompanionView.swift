import PhotosUI
import SwiftUI

struct CompanionView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    let dogId: String
    let dogName: String

    @State private var phase: GenerationPhase = .idle
    @State private var breed = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoPreview: UIImage?
    @State private var errorMessage: String?
    @State private var activeSession: SpriteGenerationSessionPayload?
    @State private var activeSpriteSet: SpriteSetPayload?
    @State private var pollTask: Task<Void, Never>?
    @State private var spriteSourceStore = SpriteSourceStore()

    private var canGenerate: Bool {
        photoData != nil && !breed.trimmingCharacters(in: .whitespaces).isEmpty && phase == .idle
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Active sprite preview
                    if let activeSpriteSet, phase != .generating {
                        activeSpritePreview(spriteSet: activeSpriteSet)
                    }

                    switch phase {
                    case .idle, .error:
                        formSection
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                    case .uploading:
                        SpriteOverlayView(preset: .savingNote, mode: .inline, size: .medium)
                            .frame(maxWidth: .infinity)

                    case .generating:
                        generatingSection

                    case .complete:
                        completionSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(StarkTheme.background)
            .environment(\.spriteSource, spriteSourceStore.source)
            .navigationTitle("Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(StarkTheme.primary)
                }
            }
            .task {
                if let set = try? await session.apiClient.getDogSpriteSet(dogId) {
                    activeSpriteSet = set
                    spriteSourceStore.source = .remote(spriteSet: set)
                }
            }
            .onDisappear { pollTask?.cancel() }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func activeSpritePreview(spriteSet: SpriteSetPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active companion")
                .font(.caption)
                .foregroundStyle(StarkTheme.mutedForeground)
                .textCase(.uppercase)
                .padding(.horizontal)

            HStack(spacing: 24) {
                ForEach([SpriteAnimation.idle, .run, .bark], id: \.self) { anim in
                    VStack(spacing: 4) {
                        StarkSpriteView(animation: anim, size: .medium)
                        Text(anim.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(StarkTheme.mutedForeground)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(StarkTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Text("\(spriteSet.manifest.breed) · Generated \(formattedDate(spriteSet.createdAt))")
                .font(.caption)
                .foregroundStyle(StarkTheme.mutedForeground)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create a new companion")
                .font(.headline)
                .padding(.horizontal)

            Text("Upload a photo of \(dogName) and enter the breed. Generation takes 1–3 minutes.")
                .font(.subheadline)
                .foregroundStyle(StarkTheme.mutedForeground)
                .padding(.horizontal)

            // Photo picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Photo")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal)

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        if let photoPreview {
                            Image(uiImage: photoPreview)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(StarkTheme.primary.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "camera")
                                        .foregroundStyle(StarkTheme.primary)
                                }
                        }
                        Text(photoData != nil ? "Change photo" : "Choose photo")
                            .foregroundStyle(StarkTheme.primary)
                        Spacer()
                    }
                    .padding()
                    .background(StarkTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task { await loadPhoto(newItem) }
                }
            }

            // Breed input
            VStack(alignment: .leading, spacing: 8) {
                Text("Breed")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal)

                TextField("e.g. Golden Retriever, Lab/Pit mix", text: $breed)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Text("Or say the breed via the voice button in the care log and it'll fill in automatically.")
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .padding(.horizontal)
            }

            Button {
                Task { await startGeneration() }
            } label: {
                Text("Generate companion sprite")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(StarkTheme.primary)
            .disabled(!canGenerate)
            .padding(.horizontal)
        }
    }

    private var generatingSubtext: String {
        guard let s = activeSession else { return "Starting…" }
        let pct = Int(s.progress)
        if let step = s.currentStep {
            return "\(step.replacingOccurrences(of: "_", with: " ").lowercased()) · \(pct)%"
        }
        return "\(pct)% complete"
    }

    private var generatingSection: some View {
        VStack(spacing: 16) {
            SpriteOverlayView(
                animation: .walk,
                message: "Creating your companion…",
                subtext: generatingSubtext,
                mode: .inline
            )

            if let s = activeSession {
                ProgressView(value: s.progress, total: 100)
                    .tint(StarkTheme.primary)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var completionSection: some View {
        VStack(spacing: 16) {
            SpriteOverlayView(
                animation: .playbow,
                message: "Companion ready.",
                subtext: activeSpriteSet.map { "\($0.manifest.breed) sprite set is now active." } ?? "Sprite set is now active.",
                mode: .inline
            )

            Button("Generate another") {
                phase = .idle
                photoData = nil
                photoPreview = nil
                selectedPhoto = nil
                breed = ""
                activeSession = nil
            }
            .buttonStyle(.bordered)
            .tint(StarkTheme.primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        photoData = data
        photoPreview = UIImage(data: data)
    }

    private func startGeneration() async {
        guard let photoData else { return }
        let breedText = breed.trimmingCharacters(in: .whitespaces)
        guard !breedText.isEmpty else { return }
        errorMessage = nil
        phase = .uploading

        do {
            // Upload photo
            let presign = try await session.apiClient.presignDogPhoto(
                contentType: "image/jpeg",
                contentLength: photoData.count
            )

            var uploadReq = URLRequest(url: URL(string: presign.uploadUrl)!)
            uploadReq.httpMethod = "PUT"
            uploadReq.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            uploadReq.httpBody = photoData
            _ = try await URLSession.shared.data(for: uploadReq)

            phase = .generating

            let newSession = try await session.apiClient.createSpriteSession(
                dogId,
                photoKey: presign.photoKey,
                breed: breedText
            )
            activeSession = newSession
            startPolling(sessionId: newSession.id)

        } catch {
            errorMessage = error.localizedDescription
            phase = .error
        }
    }

    private func startPolling(sessionId: String) {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                do {
                    let updated = try await session.apiClient.getSpriteSession(dogId, sessionId: sessionId)
                    await MainActor.run { activeSession = updated }

                    if updated.status == .completed {
                    if let set = try? await session.apiClient.getDogSpriteSet(dogId) {
                        await MainActor.run {
                            activeSpriteSet = set
                            spriteSourceStore.source = .remote(spriteSet: set)
                            phase = .complete
                        }
                    } else {
                        await MainActor.run { phase = .complete }
                    }
                        break
                    } else if updated.status == .failed || updated.status == .canceled {
                        await MainActor.run {
                            errorMessage = updated.error ?? "Generation failed. Please try again."
                            phase = .error
                        }
                        break
                    }
                } catch {
                    // Transient polling error — continue
                }
            }
        }
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Phase

private enum GenerationPhase {
    case idle, uploading, generating, complete, error
}

