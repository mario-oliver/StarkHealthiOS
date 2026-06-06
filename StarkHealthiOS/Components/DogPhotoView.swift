import SwiftUI

struct DogPhotoView: View {
    let photoUrl: String?
    let name: String
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(StarkTheme.primary.opacity(0.2), lineWidth: 1))
    }

    private var placeholder: some View {
        Circle()
            .fill(StarkTheme.primary.opacity(0.15))
            .overlay {
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(StarkTheme.primary)
            }
    }
}
