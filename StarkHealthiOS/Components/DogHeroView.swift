import PhotosUI
import SwiftUI

struct DogHeroView: View {
    let dogId: String
    let photoUrl: String?
    let name: String
    var date: String?
    var onPhotoSelected: ((Data) async -> Void)?

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            if let onPhotoSelected {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    heroContent
                }
                .onChange(of: pickerItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await onPhotoSelected(data)
                        }
                    }
                }
            } else {
                heroContent
            }

            Text(name)
                .font(.title2.bold())
                .foregroundStyle(StarkTheme.foreground)
                .multilineTextAlignment(.center)

            if let date {
                Text(date)
                    .font(.subheadline)
                    .foregroundStyle(StarkTheme.mutedForeground)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var heroContent: some View {
        DogPhotoView(dogId: dogId, photoUrl: photoUrl, name: name, size: 120)
            .overlay(alignment: .bottomTrailing) {
                if onPhotoSelected != nil {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }
    }
}
