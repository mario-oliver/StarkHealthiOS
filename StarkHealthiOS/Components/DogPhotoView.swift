import SwiftUI
import UIKit

@MainActor
@Observable
final class DogPhotoLoader {
    var image: UIImage?
    var isLoading = false
    var failed = false

    private var loadedURL: String?
    private var didRetry = false

    func load(urlString: String?, dogId: String?, refreshURL: (@Sendable () async -> String?)?) async {
        guard let urlString, !urlString.isEmpty else {
            reset()
            failed = true
            return
        }

        if urlString == loadedURL, image != nil { return }

        isLoading = true
        failed = false

        if await fetchImage(from: urlString) {
            loadedURL = urlString
            isLoading = false
            return
        }

        if let dogId, let refreshURL, !didRetry {
            didRetry = true
            if let fresh = await refreshURL(), fresh != urlString, await fetchImage(from: fresh) {
                loadedURL = fresh
                isLoading = false
                return
            }
        }

        image = nil
        failed = true
        isLoading = false
    }

    func reset() {
        image = nil
        loadedURL = nil
        didRetry = false
        failed = false
        isLoading = false
    }

    private func fetchImage(from urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.setValue("", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return false
            }
            guard let uiImage = UIImage(data: data) else { return false }
            image = uiImage
            return true
        } catch {
            return false
        }
    }
}

struct DogPhotoView: View {
    @Environment(SessionStore.self) private var session

    var dogId: String?
    let photoUrl: String?
    let name: String
    var size: CGFloat = 48

    @State private var loader = DogPhotoLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if loader.isLoading {
                placeholder
                    .overlay { ProgressView().tint(StarkTheme.primary) }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(StarkTheme.primary.opacity(0.2), lineWidth: 1))
        .task(id: photoUrl) {
            loader.reset()
            await loader.load(urlString: photoUrl, dogId: dogId) {
                guard let dogId else { return nil }
                return try? await session.apiClient.getDog(dogId).photoUrl
            }
        }
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
