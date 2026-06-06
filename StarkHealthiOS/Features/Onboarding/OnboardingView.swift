import PhotosUI
import SwiftUI

struct OnboardingView: View {
    @Environment(SessionStore.self) private var session

    @State private var step = 1
    @State private var form = DogProfileFormValues.empty()
    @State private var photoPreview: String?
    @State private var photoKey: String?
    @State private var photoUploading = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome to Stark Health")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .textCase(.uppercase)

                Text(step == 1 ? "Add your dog" : "Your care routine")
                    .font(.title2.bold())

                Text(step == 1
                     ? "Tell us about your dog — the basics plus anything that helps with PT and daily care."
                     : "We'll start you on a mobility and strength plan you can adjust later.")
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.mutedForeground)

                progressBar

                if let error {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                if step == 1 {
                    stepOne
                } else {
                    stepTwo
                }
            }
            .padding(20)
        }
        .background(StarkTheme.background)
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Capsule().fill(step >= 1 ? StarkTheme.primary : Color.secondary.opacity(0.2)).frame(height: 4)
            Capsule().fill(step >= 2 ? StarkTheme.primary : Color.secondary.opacity(0.2)).frame(height: 4)
        }
    }

    private var stepOne: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                    if let photoPreview, let url = URL(string: photoPreview) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.15))
                            .overlay {
                                Text(photoUploading ? "Uploading…" : "Add photo\n(optional)")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(StarkTheme.mutedForeground)
                            }
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task { await uploadPhoto(item) }
            }

            DogProfileFieldsView(form: $form)

            Button("Continue") { validateAndContinue() }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .frame(maxWidth: .infinity)

            Button("Have a share code? Join an existing dog") {
                session.showJoinFlow()
            }
            .font(.subheadline)
            .foregroundStyle(StarkTheme.primary)
            .frame(maxWidth: .infinity)
        }
    }

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                DogPhotoView(photoUrl: photoPreview, name: form.name, size: 72)
                VStack(alignment: .leading) {
                    Text(form.name).font(.headline)
                    Text([form.breed, form.age.isEmpty ? nil : "\(form.age) yrs", DogProfileFormSupport.formatDogSex(form.sex)]
                        .compactMap { $0?.isEmpty == false ? $0 : nil }
                        .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(StarkTheme.mutedForeground)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(DefaultRoutine.name).font(.headline)
            ForEach(DefaultRoutine.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                        Text(item.category).font(.caption).foregroundStyle(StarkTheme.mutedForeground)
                    }
                    Spacer()
                    Text(item.frequency).font(.caption2).foregroundStyle(StarkTheme.mutedForeground)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Button("Back") { step = 1 }
                    .buttonStyle(.bordered)
                Button(busy ? "Setting up…" : "Start care log") {
                    Task { await createDog() }
                }
                .buttonStyle(.borderedProminent)
                .tint(StarkTheme.primary)
                .disabled(busy || photoUploading)
            }
        }
    }

    private func validateAndContinue() {
        if let validationError = form.validate() {
            error = validationError
            return
        }
        if photoUploading {
            error = "Wait for the photo to finish uploading."
            return
        }
        error = nil
        step = 2
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        photoUploading = true
        defer { photoUploading = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
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
            photoKey = nil
            photoPreview = nil
        }
    }

    private func createDog() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let dog = try await session.apiClient.createDog(form.toCreatePayload(photoKey: photoKey))
            ActiveDogStore.setActiveDogId(dog.id)
            session.completeOnboarding(dog: dog)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
