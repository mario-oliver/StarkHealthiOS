import SwiftUI
import UIKit
import Foundation

@MainActor
@Observable
final class DogPhotoLoader {
    var image: UIImage?
    var isLoading = false
    var failed = false

    private var loadedKey: String?
    private var didRetry = false

    func load(
        dogId: String?,
        photoUrl: String?,
        fetchAuthenticated: (() async throws -> Data)?,
        fetchPresigned: (() async -> String?)?
    ) async {
        // #region agent log
        debugLog(
            runId: "warnings-check-pre",
            hypothesisId: "H3",
            location: "Components/DogPhotoView.swift:load",
            message: "DogPhotoLoader.load called",
            data: [
                "dogIdPresent": dogId != nil,
                "photoUrlPresent": photoUrl != nil,
                "hasFetchAuthenticated": fetchAuthenticated != nil,
                "hasFetchPresigned": fetchPresigned != nil
            ]
        )
        // #endregion
        let key = "\(dogId ?? "")|\(photoUrl ?? "")"
        if key == loadedKey, image != nil { return }

        isLoading = true
        failed = false

        if let fetchAuthenticated {
            if await loadFromData(key: key, loader: fetchAuthenticated) {
                isLoading = false
                return
            }
        }

        if let fetchPresigned, let freshUrl = await fetchPresigned(), await loadFromURL(freshUrl) {
            loadedKey = key
            isLoading = false
            return
        }

        if let photoUrl, await loadFromURL(photoUrl) {
            loadedKey = key
            isLoading = false
            return
        }

        if let fetchPresigned, !didRetry {
            didRetry = true
            if let freshUrl = await fetchPresigned(), freshUrl != photoUrl, await loadFromURL(freshUrl) {
                loadedKey = key
                isLoading = false
                return
            }
        }

        image = nil
        failed = true
        isLoading = false
    }

    private func debugLog(
        runId: String,
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any]
    ) {
        let payload: [String: Any] = [
            "sessionId": "869fb7",
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let line = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: line, encoding: .utf8) else { return }

        let url = URL(fileURLWithPath: "/Users/mariooliver/Documents/stark-health/.cursor/debug-869fb7.log")
        if let handle = try? FileHandle(forWritingTo: url) {
            do {
                try handle.seekToEnd()
                if let data = (text + "\n").data(using: .utf8) {
                    handle.write(data)
                }
                try handle.close()
            } catch {
                try? handle.close()
            }
            return
        }

        try? (text + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    func reset() {
        image = nil
        loadedKey = nil
        didRetry = false
        failed = false
        isLoading = false
    }

    private func loadFromData(key: String, loader: () async throws -> Data) async -> Bool {
        do {
            let data = try await loader()
            guard let uiImage = UIImage(data: data) else { return false }
            image = uiImage
            loadedKey = key
            failed = false
            return true
        } catch {
            return false
        }
    }

    private func loadFromURL(_ urlString: String) async -> Bool {
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
            failed = false
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
        .task(id: "\(dogId ?? "")|\(photoUrl ?? "")") {
            loader.reset()
            let apiClient = session.apiClient
            let resolvedDogId = dogId
            await loader.load(
                dogId: resolvedDogId,
                photoUrl: photoUrl,
                fetchAuthenticated: resolvedDogId.map { id in
                    { try await apiClient.fetchDogPhotoData(id) }
                },
                fetchPresigned: resolvedDogId.map { id in
                    { try? await apiClient.getDog(id).photoUrl }
                }
            )
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
