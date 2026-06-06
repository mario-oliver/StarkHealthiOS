import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session

    @State private var dog: DogRecord?
    @State private var editing = false
    @State private var form = DogProfileFormValues.empty()
    @State private var photoKey: String?
    @State private var photoPreview: String?
    @State private var photoUploading = false
    @State private var error: String?
    @State private var busy = false
    @State private var copied = false

    private var dogId: String? { session.activeDogId }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if dog == nil {
                    ProgressView("Loading profile…")
                } else if editing {
                    editForm
                } else {
                    readOnly
                }
            }
            .padding(16)
        }
        .background(StarkTheme.background)
        .task(id: dogId) { await loadDog() }
    }

    private var readOnly: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let dog, let dogId {
                DogHeroView(
                    dogId: dogId,
                    photoUrl: dog.photoUrl,
                    name: dog.name
                )
                .frame(maxWidth: .infinity)

                profileDetail(label: "Breed", value: dog.breed)
                profileDetail(label: "Age", value: dog.age.map { "\($0) years" })
                profileDetail(label: "Sex", value: DogProfileFormSupport.formatDogSex(dog.sex))
                profileDetail(label: "Weight", value: dog.weightLbs.map { "\($0) lbs" })
                profileDetail(label: "Condition", value: dog.condition)
                profileDetail(label: "Vet", value: dog.vetName)
                profileDetail(label: "Vet phone", value: dog.vetPhone)
                profileDetail(label: "Notes", value: dog.notes)

                if let shareCode = dog.shareCode {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Share code").font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                        HStack {
                            Text(ShareCode.format(shareCode))
                                .font(.title3.monospaced())
                            Spacer()
                            Button(copied ? "Copied!" : "Copy") {
                                UIPasteboard.general.string = ShareCode.format(shareCode)
                                copied = true
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    copied = false
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        Text("Share this code so caregivers can join \(dog.name)'s care log.")
                            .font(.caption)
                            .foregroundStyle(StarkTheme.mutedForeground)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Edit profile") {
                    form = DogProfileFormValues.from(dog: dog)
                    editing = true
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var editForm: some View {
        VStack(spacing: 16) {
            if let dogId {
                DogHeroView(
                    dogId: dogId,
                    photoUrl: photoPreview ?? dog?.photoUrl,
                    name: form.name.isEmpty ? (dog?.name ?? "") : form.name,
                    onPhotoSelected: { data in await uploadPhoto(data) }
                )
                .frame(maxWidth: .infinity)
            }

            DogProfileFieldsView(form: $form)

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    editing = false
                    photoKey = nil
                    photoPreview = nil
                }
                .buttonStyle(.bordered)

                Button(busy ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(busy || photoUploading)
            }
        }
    }

    @ViewBuilder
    private func profileDetail(label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                Text(value).font(.subheadline)
            }
        }
    }

    private func loadDog() async {
        guard let dogId else { return }
        do {
            dog = try await session.apiClient.getDog(dogId)
        } catch let loadError {
            self.error = loadError.localizedDescription
        }
    }

    private func uploadPhoto(_ data: Data) async {
        photoUploading = true
        defer { photoUploading = false }
        do {
            let contentType = PhotoUploadService.inferContentType(for: data)
            let result = try await PhotoUploadService.uploadDogPhoto(
                apiClient: session.apiClient,
                imageData: data,
                contentType: contentType
            )
            photoKey = result.photoKey
            photoPreview = result.viewUrl
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        guard let dogId else { return }
        if let validationError = form.validate() {
            error = validationError
            return
        }
        busy = true
        error = nil
        defer { busy = false }
        do {
            var payload = form.toUpdatePayload()
            if let photoKey { payload.photoKey = photoKey }
            dog = try await session.apiClient.updateDog(dogId, input: payload)
            editing = false
            photoKey = nil
            photoPreview = nil
            await session.refreshDogs()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
