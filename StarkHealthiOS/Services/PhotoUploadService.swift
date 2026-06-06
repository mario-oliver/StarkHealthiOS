import Foundation
import UIKit

enum PhotoUploadService {
    static let maxBytes = 10 * 1024 * 1024

    static func uploadDogPhoto(apiClient: APIClient, imageData: Data, contentType: String) async throws -> (photoKey: String, viewUrl: String) {
        guard imageData.count <= maxBytes else {
            throw PhotoUploadError.tooLarge
        }

        let presign = try await apiClient.presignDogPhoto(contentType: contentType, contentLength: imageData.count)
        let uploadURL = URL(string: presign.uploadUrl)!
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.httpBody = imageData
        request.setValue(presign.headers["Content-Type"] ?? contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw PhotoUploadError.uploadFailed
        }

        return (presign.photoKey, presign.viewUrl)
    }

    static func inferContentType(for data: Data) -> String {
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        return "image/jpeg"
    }
}

enum PhotoUploadError: LocalizedError {
    case tooLarge
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .tooLarge: return "Photo must be 10 MB or smaller."
        case .uploadFailed: return "Photo upload failed."
        }
    }
}
